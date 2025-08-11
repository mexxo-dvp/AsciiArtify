.PHONY: kind-install cluster-up cluster-down deploy demo verify clean \
        argocd-install app-apply app-delete argocd-open app-open

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
	  kind create cluster --name asciiartify --config cluster/cluster.yaml; \
	else \
	  echo "kind cluster 'asciiartify' already exists"; \
	fi

cluster-down:
	-kind delete cluster --name asciiartify

deploy:
	kubectl apply -f k8s/hello.yaml
	kubectl rollout status deploy/hello

demo: kind-install cluster-up deploy verify argocd-install app-apply argocd-open

verify:
	@kubectl get svc hello -o wide || { echo "Service 'hello' not found. Run 'make deploy'"; exit 1; }
	@curl -I http://localhost:30090/ || true

# Встановлює ArgoCD (разом із CRD) і чекає готовності
argocd-install:
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl wait --for=condition=Established crd/applications.argoproj.io --timeout=120s
	kubectl -n argocd rollout status deploy/argocd-server --timeout=180s

# Створити/оновити наше ArgoCD Application (дивиться на k8s/app/)
app-apply: argocd-install
	kubectl apply -f k8s/argocd/asciiartify-app.yaml
	kubectl -n argocd get applications.argoproj.io

# Видалити Application і namespace demo
app-delete:
	-kubectl -n argocd delete application asciiartify
	-kubectl delete ns demo --ignore-not-found=true

# Відкрити UI ArgoCD через HTTP (insecure mode) на 8080
argocd-open:
	@echo ">> Port-forward ArgoCD (deploy) on 8080 (HTTP). In Codespaces set 8080 -> Public"
	- pkill -f "kubectl.*port-forward.*argocd-server" || true
	kubectl -n argocd wait --for=condition=Available deploy/argocd-server --timeout=180s
	kubectl -n argocd wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --timeout=180s
	kubectl -n argocd port-forward --address 0.0.0.0 deploy/argocd-server 8080:8080

# Відкрити MVP-app (Codespaces: Ports → 8081 → Public)
app-open:
	@echo "Waiting for asciiartify-web to be ready..."
	kubectl -n demo rollout status deploy/asciiartify-web --timeout=180s
	@echo "Port-forwarding asciiartify-web on 8081 (HTTP)..."
	- pkill -f "kubectl.*port-forward.*asciiartify-web" || true
	kubectl -n demo port-forward --address 0.0.0.0 svc/asciiartify-web 8081:80

clean: cluster-down
