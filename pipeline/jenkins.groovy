pipeline {
  agent any
  options {
    disableConcurrentBuilds()
    ansiColor('xterm')
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }
  parameters {
    string(name: 'GIT_REF', defaultValue: 'main', description: 'Branch, tag або commit SHA')
    choice(name: 'PLATFORMS', choices: ['linux/amd64,linux/arm64','linux/amd64','linux/arm64','linux/arm/v7'],
    string(name: 'REPOSITORY', defaultValue: 'ghcr.io/mexxo-dvp/kbot', description: 'registry/repo')
    string(name: 'IMAGE_TAG', defaultValue: 'auto', description: 'auto => <tag|dev>-<shortSHA>')
    booleanParam(name: 'PUSH', defaultValue: true, description: 'Пушити у реєстр')
    string(name: 'DOCKERFILE', defaultValue: 'Dockerfile', description: 'Шлях до Dockerfile')
    string(name: 'CONTEXT', defaultValue: '.', description: 'Build context')
    booleanParam(name: 'USE_QEMU', defaultValue: true, description: 'binfmt/qemu для крос-збірки')
    choice(name: 'REGISTRY', choices: ['ghcr','dockerhub','quay','none'], description: 'Куди логінитись')
    string(name: 'EXTRA_BUILD_ARGS', defaultValue: '', description: 'Додаткові build-args')
  }
  environment {
    DOCKER_CLI_EXPERIMENTAL = 'enabled'
    BUILDX_BUILDER = 'jenkinsbuilder'
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
        sh '''
          set -euxo pipefail
          git fetch --all --tags
          git checkout "${GIT_REF}" || git checkout -B tmp "${GIT_REF}"
          git submodule update --init --recursive || true
        '''
      }
    }
    stage('Prepare Buildx') {
      steps {
        sh '''
          set -euxo pipefail
          docker version
          docker info
          if ! docker buildx inspect "${BUILDX_BUILDER}" >/dev/null 2>&1; then
            docker buildx create --name "${BUILDX_BUILDER}" --use
          else
            docker buildx use "${BUILDX_BUILDER}"
          fi
          if [ "${USE_QEMU}" = "true" ]; then
            docker run --privileged --rm tonistiigi/binfmt --install all
          fi
          docker buildx inspect --bootstrap
        '''
      }
    }
    stage('Resolve Tag') {
      steps {
        script {
          def shortSha = sh(script: 'git rev-parse --short=7 HEAD', returnStdout: true).trim()
          def baseTag  = sh(script: 'git describe --tags --exact-match 2>/dev/null || echo dev', returnStdout: true).trim()
          env.IMAGE_TAG = (params.IMAGE_TAG?.trim() && params.IMAGE_TAG != 'auto') ? params.IMAGE_TAG : "${baseTag}-${shortSha}"
          currentBuild.displayName = "#${env.BUILD_NUMBER} ${env.IMAGE_TAG}"
        }
      }
    }
    stage('Login (optional)') {
      when { expression { return params.REGISTRY != 'none' && params.PUSH } }
      steps {
        script {
          if (params.REGISTRY == 'ghcr') {
            withCredentials([usernamePassword(credentialsId: 'ghcr-creds', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
              sh 'echo "$REG_PASS" | docker login ghcr.io -u "$REG_USER" --password-stdin'
            }
          } else if (params.REGISTRY == 'dockerhub') {
            withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
              sh 'echo "$REG_PASS" | docker login -u "$REG_USER" --password-stdin'
            }
          } else if (params.REGISTRY == 'quay') {
            withCredentials([usernamePassword(credentialsId: 'quay-creds', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
              sh 'echo "$REG_PASS" | docker login quay.io -u "$REG_USER" --password-stdin'
            }
          }
        }
      }
    }
    stage('Build (multi-arch)') {
      steps {
        sh '''
          set -euxo pipefail
          DOCKER_PUSH_FLAG="--load"
          if [ "${PUSH}" = "true" ]; then DOCKER_PUSH_FLAG="--push"; fi
          docker buildx build \
            --platform "${PLATFORMS}" \
            -f "${DOCKERFILE}" \
            ${EXTRA_BUILD_ARGS} \
            -t "${REPOSITORY}:${IMAGE_TAG}" \
            ${DOCKER_PUSH_FLAG} \
            "${CONTEXT}"
        '''
      }
    }
    stage('Inspect & Artifacts') {
      steps {
        sh '''
          set -euxo pipefail
          docker buildx imagetools inspect "${REPOSITORY}:${IMAGE_TAG}" | tee buildx-inspect.txt || true
          {
            echo "image=${REPOSITORY}:${IMAGE_TAG}"
            echo "platforms=${PLATFORMS}"
            echo "git_ref=${GIT_REF}"
            echo "commit=$(git rev-parse HEAD)"
          } > build-metadata.txt
        '''
        archiveArtifacts artifacts: 'build-metadata.txt,buildx-inspect.txt', onlyIfSuccessful: true
      }
    }
  }
  post {
    always {
      sh 'docker logout ghcr.io || true; docker logout quay.io || true; docker logout || true'
      cleanWs()
    }
    success { echo "✅ Built ${env.REPOSITORY}:${env.IMAGE_TAG} for ${params.PLATFORMS}" }
    failure { echo "❌ Build failed" }
  }
}
