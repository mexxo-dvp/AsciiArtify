# MVP — ArgoCD автосинхронізація (AsciiArtify)

Мета: розгорнути наш застосунок через ArgoCD з **Auto-Sync** і продемонструвати автоматичну синхронізацію змін з Git.

## Передумови
- Кластер kind запущений (`make cluster-up`)
- ArgoCD встановлено і доступне в Codespaces (див. `doc/POC.md`, розділ про Ports → Public, порт 8080)

## Кроки

### 1) Додати/оновити маніфести застосунку
- `k8s/app/configmap.yaml` (index.html з текстом “MVP v1”)
- `k8s/app/deployment.yaml`
- `k8s/app/service.yaml` (NodePort 30090 для локальних перевірок)

### 2) Створити ArgoCD Application
```bash
kubectl apply -f k8s/argocd/asciiartify-app.yaml
kubectl -n argocd get applications.argoproj.io
```
3) Відкрити UI ArgoCD (Codespaces)
```bash
make argocd-open
```
    У вкладці Ports порту 8080 поставити Public.

    Відкрити URL виду: https://<codespace>-8080.app.github.dev.

    Залогінитись (admin / initial password з POC.md).

Переконатися, що Application → asciiartify має статус Synced/Healthy.
4) Переглянути застосунок у браузері
```bash
make app-open
```
    У вкладці Ports порту 8081 поставити Public.

    Відкрити: https://<codespace>-8081.app.github.dev → бачимо “MVP v1”.

5) Демо авто-синху (видима зміна)

    Змінити doc: у k8s/app/configmap.yaml замінити MVP v1 → MVP v2.

    Закомітити і запушити в main.

    У UI ArgoCD побачити: OutOfSync → Auto-Sync → Synced.

    Оновити сторінку застосунку (8081/Public) → бачимо “MVP v2”.

Демо (відео)

    Демо роботи застосунку: посилання

    Демо авто-синхронізації: посилання