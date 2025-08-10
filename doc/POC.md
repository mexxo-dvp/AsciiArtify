# Proof of Concept (PoC) — Розгортання ArgoCD на Kubernetes (kind)

## 1. Перевірка доступу до кластера

Після створення кластеру командою:

```bash
make cluster-up
```
Перевіримо версію Kubernetes та доступність компонентів:
```bash
kubectl version --short
kubectl get componentstatuses
```
2. Огляд нод та ресурсів

Список усіх нод у кластері:
```bash
kubectl get nodes -o wide
```
Список усіх ресурсів у всіх просторах імен:
```bash
kubectl get all -A
```
3. Зручні налаштування для роботи з kubectl

Щоб скоротити команди, можна додати alias та автодоповнення:
```bash
alias k=kubectl
source <(kubectl completion bash)
complete -F __start_kubectl k
```
Для Zsh:
```bash
alias k=kubectl
source <(kubectl completion zsh)
compdef __start_kubectl k
```
    💡 Тепер замість kubectl get nodes можна писати k get nodes.

4. Перемикання контексту

Якщо у вас кілька кластерів, для перемикання на наш кластер використовуйте:
```bash
kubectl config use-context kind-asciiartify
```
Перевірити поточний контекст:
```bash
kubectl config current-context
```
5. Доступ до демо-сервісу

Ми розгорнули тестовий застосунок Hello World:
```bash
kubectl apply -f k8s/hello.yaml
kubectl rollout status deploy/hello
```
Сервіс працює через NodePort:
```bash
kubectl get svc hello -o wide
```
Перевірка доступу:
```bash
curl -I http://localhost:30090/
```
6. Демо-сесія (loom)
[![Демо ArgoCD](https://cdn.loom.com/sessions/thumbnails/0fac9973c08844c29f7b7edb2f0c99fd?sid=0e9e8425-aa89-4618-bc9a-24d01c8f8e8c-with-play.gif)](https://www.loom.com/share/0fac9973c08844c29f7b7edb2f0c99fd?sid=0e9e8425-aa89-4618-bc9a-24d01c8f8e8c)
7. Наступний етап — встановлення ArgoCD

Інструкції з встановлення ArgoCD:
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
## Доступ до ArgoCD в GitHub Codespaces (Public Ports)

> У Codespaces публічний порт-проксі не підтримує TLS passthrough. Тому при форварді на 443 виникає 404. Рішення — увімкнути HTTP-режим для argocd-server і форвардити порт 80.

### Кроки

1) Увімкнути **insecure (HTTP)** режим для `argocd-server` і перезапустити:
```bash
kubectl -n argocd patch configmap argocd-cmd-params-cm -p \
'{"data":{"server.insecure":"true"}}'
kubectl -n argocd rollout restart deploy/argocd-server
kubectl -n argocd rollout status deploy/argocd-server
```
    Зробити port-forward на 80 і слухати на всіх інтерфейсах:
```bash
kubectl -n argocd port-forward --address 0.0.0.0 svc/argocd-server 8080:80
```
    У вкладці Ports (у Codespaces) знайти порт 8080 → змінити Visibility → Public → відкрити посилання виду:
```bash
https://<your-codespace>-8080.app.github.dev
```
    Логін у UI:

# Початковий пароль admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

User: admin
Pass: (значення з команди вище)

    Після входу одразу змініть пароль у UI.