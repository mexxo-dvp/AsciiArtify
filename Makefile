.PHONY: cluster-up cluster-down deploy demo verify clean
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

demo: cluster-up deploy

verify:
	@kubectl get svc hello -o wide || { echo "Service 'hello' not found. Run 'make deploy'"; exit 1; }
	@curl -I http://localhost:30090/ || true

clean: cluster-down
