.PHONY: kind-install cluster-up cluster-down deploy demo verify clean \
        argocd-install app-apply app-delete argocd-open app-open ns-demo

kind-install:
	@if ! command -v kind >/dev/null 2>&1; then \
	  echo "Installing kind..."; \
	  curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64; \
	  chmod +x ./kind; \
	  sudo mv ./kind /usr/local/bin/kind; \
	else \
	  echo "kind already installed: $$(kind version)"; \
	fi

cluster-up:
	@if ! kind get clusters | grep -qx asciiartify; then \
	  echo "Creating kind cluster 'asciiartify'..."; \
	  kind create cluster --name asciiartify --config cluster/cluster.yaml; \
	else \
	  echo "kind cluster 'asciiartify' already exists"; \
	fi

cluster-down:
	-echo "Deleting kind cluster 'asciiartify'..."
	-kind delete cluster --name asciiartify

deploy:
	@echo "Deploying hello app..."
	kubectl apply -f k8s/hello.yaml
	kubectl rollout status deploy/hello

ns-demo:
	@echo "Creating namespace 'demo'..."
	@kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
	@echo "Namespace 'demo' is ready"

# Повний сценарій без дублювання: app-apply вже включає ns-demo та argocd-install
demo: kind-install cluster-up deploy verify app-apply argocd-open app-open

verify:
	@kubectl get svc hello -o wide || { echo "Service 'hello' not found. Run 'make deploy'"; exit 1; }
	@echo "Checking NodePort 30090..."
	@curl -I http://localhost:30090/ || true

# Процес налаштування доступу до веб-інтерфейсу ArgoCD (разом із CRD)
argocd-install:
	@echo "Installing ArgoCD..."
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl wait --for=condition=Established crd/applications.argoproj.io --timeout=120s
	kubectl -n argocd rollout status deploy/argocd-server --timeout=180s

# Деплой  Application у ArgoCD (включає підготовку namespace та встановлення ArgoCD)
app-apply: argocd-install ns-demo
	@echo "Applying ArgoCD Application 'asciiartify'..."
	kubectl apply -f k8s/argocd/asciiartify-app.yaml
	kubectl -n argocd get applications.argoproj.io

# Видаляє Application та namespace demo
app-delete:
	@echo "Deleting ArgoCD Application 'asciiartify' and namespace 'demo'..."
	-kubectl -n argocd delete application asciiartify
	-kubectl delete ns demo --ignore-not-found=true

# Відкриває UI ArgoCD через HTTP (режим insecure) на порту 8080
argocd-open:
	@echo "Patching ArgoCD server to run in --insecure mode (HTTP only)..."
	- kubectl -n argocd patch deploy argocd-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--insecure"}]' || true
	kubectl -n argocd rollout status deploy/argocd-server --timeout=180s
	@echo "Port-forwarding ArgoCD UI on 8080 (HTTP)..."
	- pkill -f "kubectl.*port-forward.*argocd-server" || true
	kubectl -n argocd port-forward --address 0.0.0.0 svc/argocd-server 8080:80

# Відкриває MVP-додаток (у Codespaces: Ports → 8081 → Public)
app-open:
	@echo "Waiting for asciiartify-web to be ready..."
	kubectl -n demo rollout status deploy/asciiartify-web --timeout=180s
	@echo "Port-forwarding asciiartify-web on 8081 (HTTP)..."
	- pkill -f "kubectl.*port-forward.*asciiartify-web" || true
	kubectl -n demo port-forward --address 0.0.0.0 svc/asciiartify-web 8081:80

clean: cluster-down