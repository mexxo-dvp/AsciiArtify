.PHONY: cluster-up cluster-down deploy demo verify clean

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
