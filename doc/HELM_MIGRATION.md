# Міграція з YAML на Helm для AsciiArtify
Резюме

Перенесли маніфести з k8s/app у Helm-чарт helm/. ArgoCD тепер рендерить ресурси через Helm, що спрощує версіонування та параметризацію.
Передумови

### Kubernetes-кластер доступний (kind/Minikube/GKE).

### ArgoCD встановлено та налаштовано.

### Репозиторій підключено до ArgoCD Application.

## Структура репозиторію (після міграції)
```text
helm/
  Chart.yaml           # метадані чарта
  values.yaml          # базові значення
  templates/
    configmap.yaml     # сторінка index.html
    deployment.yaml    # nginx-подовий веб
    service.yaml       # сервіс (NodePort)
k8s/
  argocd/
    asciiartify.yaml   # Application з path: helm
```
## Зміни у конфігурації

### Helm-чарт
 
### Створено helm/Chart.yaml:
```yaml
apiVersion: v2
name: asciiartify
description: Helm chart for AsciiArtify stack
type: application
version: 0.1.0
appVersion: "1.0.0"
```
### Створено helm/values.yaml:
```yaml
namespace: demo
```
### Перенесено маніфести до helm/templates/:

configmap.yaml — містить index.html (текст “AsciiArtify — MVP v2”).

deployment.yaml — виправлено опечатку (було depolyment.yaml), образ nginx:1.25-alpine, монтування ConfigMap у /usr/share/nginx/html.

service.yaml — type: NodePort, nodePort: 30954 для локального доступу.

## Namespace

templates/namespace.yaml:
```yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      name: {{ .Values.namespace }}
```

## ArgoCD Application

Оновлено шлях на Helm:
```yaml
spec:
  source:
    path: helm
```
## Після пушу — форс-оновлення:
```bash
kubectl -n argocd annotate app asciiartify argocd.argoproj.io/refresh=hard --overwrite
```
Кроки міграції

## 1) Створення каталогу чарта
```bash
mkdir -p helm/templates
```
## 2) Додавання файлів чарта (Chart.yaml, values.yaml) — як вище

## 3) Перенесення YAML у чарт
```bash
cp -a k8s/app/*.yaml helm/templates/ 2>/dev/null || true
```
## 4) Оновлення ArgoCD Application на path: helm
```bash
sed -i 's#path: k8s/app#path: helm#g' k8s/argocd/asciiartify-app.yaml
```