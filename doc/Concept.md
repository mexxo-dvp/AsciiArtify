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
```text
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

```
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
## 7. Конфігурація kind для проєкту AsciiArtify

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
## 8. Демонстрація (kind)

Деплой “Hello World”

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
## 9. Makefile
```bash
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
```
Використання:
```bash
make cluster-up
make deploy
make verify
```
## 11. Демо-запис: demo/kind-asciiartify.cast

[![asciicast](https://asciinema.org/a/Bm4fq8HRyKPmZu6KLm53MvzMx.svg)](https://asciinema.org/a/Bm4fq8HRyKPmZu6KLm53MvzMx)

## 10. Висновки

    kind — основний інструмент для PoC: швидкий, стабільний, максимально сумісний з upstream K8s.

    minikube — оптимальний під Podman/VM.

    k3d — найшвидший варіант для легких PoC.