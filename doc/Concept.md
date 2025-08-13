## 1. Вступ
Стартап **AsciiArtify** планує створити програмний продукт для перетворення зображень у ASCII-art за допомогою Machine Learning.  
Оскільки команда не має досвіду в DevOps, потрібно обрати інструмент для локальної розробки та тестування на базі Kubernetes.  
Було розглянуто три основні варіанти:

- **minikube** — локальний Kubernetes із багатьма драйверами (Docker/Podman/VM), багатий набір аддонів.
- **kind** — upstream Kubernetes у контейнерах Docker; мінімалістичний, надійний у CI.
- **k3d** — обгортка для полегшеного k3s (Rancher) у Docker; дуже швидкий старт і малий фуутпринт.

У виборі також враховано ризики ліцензування Docker Desktop та можливість використання альтернативи Podman.

---
## 2. Структура репозиторію
```text
AsciiArtify/
├─ doc/
│  ├─ Concept.md
│  └─ demo/
│     └─ kind-asciiartify.cast
├─ kind/
│  └─ cluster.yaml
├─ k8s/
│  └─ hello.yaml
├─ .gitignore
├─ README.md
└─ Makefile
```
doc/ — документація та демо-записи

cluster/ — конфіги кластерів kind

k8s/ — маніфести застосунків для Kubernetes

.gitignore — виключення зайвих файлів з git

README.md — короткий опис і посилання на Concept.md

Makefile — зручні цілі для запуску/зупинки кластерів та деплою

Порівняльний аналіз інструментів для локального Kubernetes

## 3. Характеристики
markdown
|  Область                        | minikube                             | kind                                   | k3d (k3s)                             | Нотатки                                                |
|  ------------------------------ | ------------------------------------ | -------------------------------------- | ------------------------------------- | ------------------------------------------------------ |
| **ОС / архітектури**            | Win / macOS / Linux; x86_64 / arm64  | Win / macOS / Linux; x86_64 / arm64    | Win / macOS / Linux; x86_64 / arm64   | Усі троє підтримують сучасні десктопи та Apple Silicon |
| **Рантайм / драйвер**           | Docker / Podman / VM                 | Переважно Docker (Podman — Linux only) | Переважно Docker (Podman нестабільно) | Найменше тертя з рантаймом — у minikube                |
|  **Multi-node**                 | Так                                  | Так                                    | Так                                   | Для PoC достатньо 1 control-plane + 1–2 workers        |
|  **Швидкість старту**           | Середня                              | Висока                                 | Дуже висока                           | k3d найшвидший; kind швидкий і стабільний              |
|  **Ресурсний фуутпринт**        | Середній                             | Помірний                               | Малий                                 | k3d найменший; kind помірний                           |
|  **Відповідність upstream K8s** | Висока                               | **Найвища**                            | Середня (k3s — полегшений)            | Для сумісності маніфестів: kind ≈ prod                 |
| **Аддони «з коробки»**          | Є (Ingress / Dashboard / metrics)    | Мінімум (налаштовується вручну)        | Прості (ingress, registry)            | Мінімалізм kind — плюс для CI, мінус для «магії»       |
| **Local Registry**              | Можна підключити                     | Через додаткові кроки                  | Вбудована підтримка                   | Для kind потрібна окрема конфігурація                  |
| **LoadBalancer (dev)**          | Є (tunnel / MetalLB)                 | Через Kindnet + MetalLB                | Є (k3s LB / Traefik)                  | Для демо зазвичай вистачає NodePort / Ingress          |
|  **Зручність у CI**             | Добре                                | **Відмінно**                           | Добре                                 | kind має зрілий UX у CI                                |
| **Підтримка Podman**            | **Найкраща**                         | Обмежена (Linux)                       | Нестабільно                           | Якщо уникаємо Docker Desktop — minikube топ            |
|  **Документація / ком’юніті**   | Активна                              | **Дуже активна**                       | Активна                               | Усі мають активну спільноту                            |
---

## 4. Переваги та недоліки

**minikube**
- ➕ Працює без Docker Desktop (через Podman/VM)
- ➕ Аддони одним кліком
- ➖ Повільніший старт

**kind**
- ➕ Максимальна відповідність прод-середовищу
- ➕ Швидке створення і видалення кластерів
- ➖ Менше готових аддонів

**k3d**
- ➕ Дуже швидкий і легкий
- ➕ Простий локальний registry
- ➖ k3s має відмінності від kube

---

## 5. Ризики Docker і альтернатива Podman
- Docker Desktop може потребувати ліцензію у комерційних компаній.  
- Альтернативи: **Linux Docker Engine**, **Podman**, **Rancher Desktop**, **Colima**.

---

## 6. Системні залежності

**Обов’язкові:**
```bash
# Docker
sudo apt install -y docker.io
```
### kubectl
```bash
sudo apt update && sudo apt install -y kubectl
```
### kind
```bash
mkdir -p ~/.local/bin
curl -Lo ~/.local/bin/kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ~/.local/bin/kind
kind version
```
### make
```bash
sudo apt install -y make
```

## 7. У проєкті використано набір Kubernetes-маніфестів (ConfigMap, Deployment, Service, Namespace), які розгортають MVP-версію веб-додатку AsciiArtify на Nginx, публікують його через NodePort та ізолюють у окремому просторі імен.

Метадані Helm-чарта (назва, опис, версії).
helm/Chart.yaml
```yaml
apiVersion: v2
name: asciiartify
description: Helm chart for AsciiArtify stack
type: application
version: 0.1.0
appVersion: "1.0.0"
```
Призначення: визначає структуру та опис чарта.
helm/values.yaml
Базові змінні, які можна параметризувати.
```yaml
namespace: demo
```
Призначення: зберігає значення за замовчуванням (namespace, образи, порти).
helm/templates/configmap.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: asciiartify-web
data:
  index.html: |
    <!doctype html>
    <html>
      <head><meta charset="utf-8"><title>AsciiArtify — MVP v1</title></head>
      <body style="font-family: system-ui; padding:20px;">
        <h1>AsciiArtify — MVP v2</h1>
        <p>Демо сторінка. Авто-синхронізація ArgoCD працює ✅</p>
      </body>
    </html>
```
Призначення: аналог попереднього ConfigMap, але вже у структурі Helm.
helm/templates/deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: asciiartify-web
  labels:
    app: asciiartify-web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: asciiartify-web
  template:
    metadata:
      labels:
        app: asciiartify-web
    spec:
      containers:
        - name: nginx
          image: nginx:1.25-alpine
          ports:
            - containerPort: 80
          volumeMounts:
            - name: web
              mountPath: /usr/share/nginx/html
      volumes:
        - name: web
          configMap:
            name: asciiartify-web
            items:
              - key: index.html
                path: index.html
```
Призначення: деплой веб-сервера у Helm.
helm/templates/service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: asciiartify-web
  labels:
    app: asciiartify-web
spec:
  type: NodePort
  selector:
    app: asciiartify-web
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30954
```
Призначення: зовнішній доступ через NodePort.
helm/templates/namespace.yaml (опційно)

Додається, якщо не використовується CreateNamespace=true в ArgoCD.
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: {{ .Values.namespace }}
```
Призначення: створення простору імен із значення в values.yaml.

## 8. Конфігурація kind для проєкту AsciiArtify

cluster/cluster.yaml:
```yaml
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
name: asciiartify
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30090
        hostPort: 30090
        protocol: TCP
```
## 9. Деплой тестового додатку “Hello World”

k8s/hello.yaml:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello
  labels:
    app: hello
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
        - name: nginx
          image: nginx:1.25-alpine
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: hello
spec:
  type: NodePort
  selector:
    app: hello
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30090
```
Запуск:
```bash
kind create cluster --name asciiartify --config cluster/cluster.yaml
kubectl apply -f k8s/hello.yaml
kubectl rollout status deploy/hello
```
Перевірка:
```bash
kubectl get svc hello -o wide # Ця команда показує детальну інформацію про сервіс hello у Kubernetes, включно з його типом, IP-адресами, портами та зв’язаними Pod-ами.
curl -I http://localhost:30090/
```
Видалення:
```bash
kind delete cluster --name asciiartify
```
## 10. Makefile

Цей Makefile автоматизує створення локального Kubernetes-кластеру в Kind, розгортання додатків, налаштування ArgoCD та відкриття доступу до MVP-додатку.
```bash
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

demo: kind-install cluster-up deploy verify app-apply argocd-open app-open

verify:
	@kubectl get svc hello -o wide || { echo "Service 'hello' not found. Run 'make deploy'"; exit 1; }
	@echo "Checking NodePort 30090..."
	@curl -I http://localhost:30090/ || true

argocd-install:
	@echo "Installing ArgoCD..."
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl wait --for=condition=Established crd/applications.argoproj.io --timeout=120s
	kubectl -n argocd rollout status deploy/argocd-server --timeout=180s

app-apply: argocd-install ns-demo
	@echo "Applying ArgoCD Application 'asciiartify'..."
	kubectl apply -f k8s/argocd/asciiartify-app.yaml
	kubectl -n argocd get applications.argoproj.io

app-delete:
	@echo "Deleting ArgoCD Application 'asciiartify' and namespace 'demo'..."
	-kubectl -n argocd delete application asciiartify
	-kubectl delete ns demo --ignore-not-found=true

argocd-open:
	@echo "Patching ArgoCD server to run in --insecure mode (HTTP only)..."
	- kubectl -n argocd patch deploy argocd-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--insecure"}]' || true
	kubectl -n argocd rollout status deploy/argocd-server --timeout=180s
	@echo "Port-forwarding ArgoCD UI on 8080 (HTTP)..."
	- pkill -f "kubectl.*port-forward.*argocd-server" || true
	kubectl -n argocd port-forward --address 0.0.0.0 svc/argocd-server 8080:80

app-open:
	@echo "Waiting for asciiartify-web to be ready..."
	kubectl -n demo rollout status deploy/asciiartify-web --timeout=180s
	@echo "Port-forwarding asciiartify-web on 8081 (HTTP)..."
	- pkill -f "kubectl.*port-forward.*asciiartify-web" || true
	kubectl -n demo port-forward --address 0.0.0.0 svc/asciiartify-web 8081:80

clean: cluster-down
```
Використання команд з файлу Makefile та детальний опис
Встановлює Kind (Kubernetes in Docker), якщо він ще не встановлений.
```bash
make kind-install
```
Створює кластер Kind з іменем asciiartify за конфігом cluster/cluster.yaml.
```bash
make cluster-up
```
Видаляє кластер asciiartify.
```bash
make cluster-down
```
Деплой додатку hello та очікування його готовності.
```bash
make deploy
```
Створює Kubernetes namespace demo (якщо ще не існує).
```bash
make ns-demo
```
Повний сценарій для швидкого старту: встановлює Kind, створює кластер, деплоїть тестовий додаток, верифікує роботу, застосовує ArgoCD-додаток, відкриває UI ArgoCD і MVP-додаток.
```bash
make demo
```
Перевіряє наявність сервісу hello і доступність NodePort 30090.
```bash
make verify
```
Процес налаштування доступу до веб-інтерфейсу ArgoCD (разом із CRD)
```bash
make argocd-install
```
Створює або оновлює ArgoCD Application asciiartify та готує середовище (ns-demo + argocd-install).
```bash
make app-apply
```
Видаляє Application asciiartify і namespace demo.
```bash
make app-delete
```
Відкриває UI ArgoCD у режимі --insecure на порту 8080 (через port-forward).
```bash
make argocd-open
```
Відкриває MVP-додаток (у Codespaces: Ports → 8081 → Public)
```bash
make app-open
```
Очищає середовище — видаляє кластер Kind.
```bash
make clean
```
## 11. Демо-запис: demo/kind-asciiartify.cast

[![asciicast](https://asciinema.org/a/Bm4fq8HRyKPmZu6KLm53MvzMx.svg)](https://asciinema.org/a/Bm4fq8HRyKPmZu6KLm53MvzMx)

## 12. Висновки

kind — основний інструмент для PoC: швидкий, стабільний, максимально сумісний з upstream K8s.

minikube — оптимальний під Podman/VM.

k3d — найшвидший варіант для легких PoC.
    

У даному контексті kind обрано як інструмент для створення кластерів Kubernetes (тобто Kubernetes IN Docker). Цей вибір обґрунтовано такими ключовими перевагами:

Швидкість і портативність – kind дозволяє створювати локальні кластери Kubernetes прямо в Docker-контейнерах, що значно пришвидшує розгортання та тестування.

Тестування та CI/CD – ідеально підходить для автоматизованого середовища: швидко проганяються тести на ізольованих кластерах без необхідності розгортання хмарних ресурсів.

Простота налаштування – не потребує складних конфігурацій або окремих віртуальних машин: достатньо лише Docker середовища, яке часто вже доступне.