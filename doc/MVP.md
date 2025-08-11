# MVP — ArgoCD автосинхронізація (AsciiArtify)

Мета: розгорнути наш застосунок через ArgoCD з **Auto-Sync** і продемонструвати автоматичну синхронізацію змін з Git.

## Передумови
- Кластер kind запущений (`make cluster-up`)
- ArgoCD встановлено і доступне в Codespaces (див. `doc/POC.md`, розділ про Ports → Public, порт 8080)

## Кроки

### 1) Додати/оновити маніфести застосунку
- `k8s/app/configmap.yaml` (index.html з текстом “MVP v1”)
- `k8s/app/deployment.yaml`
- `k8s/app/service.yaml` (NodePort 30954 для локальних перевірок)

### 2) Повний сценарій для швидкого старту: встановлює Kind, створює кластер, деплоїть тестовий додаток, верифікує роботу, застосовує ArgoCD-додаток, відкриває UI ArgoCD і MVP-додаток.
```bash
make demo
```
### 3) Makefile — автоматизація сценарію розгортання MVP

Цей Makefile автоматизує створення локального Kubernetes-кластеру в Kind, розгортання додатків, налаштування ArgoCD та відкриття доступу до MVP-додатку.
Основні цілі
Ціль	Призначення
kind-install	Встановлює Kind (Kubernetes in Docker), якщо він ще не встановлений.
cluster-up	Створює кластер Kind з іменем asciiartify за конфігом cluster/cluster.yaml.
cluster-down	Видаляє кластер asciiartify.
deploy	Розгортає тестовий додаток hello та очікує його готовності.
ns-demo	Створює Kubernetes namespace demo (якщо ще не існує).
demo	Повний сценарій для швидкого старту: встановлює Kind, створює кластер, деплоїть тестовий додаток, верифікує роботу, застосовує ArgoCD-додаток, відкриває UI ArgoCD і MVP-додаток.
verify	Перевіряє наявність сервісу hello і доступність NodePort 30090.
argocd-install	Встановлює ArgoCD (разом із CRD) у namespace argocd та чекає на готовність.
app-apply	Створює або оновлює ArgoCD Application asciiartify та готує середовище (ns-demo + argocd-install).
app-delete	Видаляє Application asciiartify і namespace demo.
argocd-open	Відкриває UI ArgoCD у режимі --insecure на порту 8080 (через port-forward).
app-open	Очікує готовності Deployment asciiartify-web та відкриває доступ до нього на порту 8081 (через port-forward).
clean	Очищає середовище — видаляє кластер Kind.
Логіка роботи

    Підготовка інструментів
    Перевірка наявності Kind та встановлення за потреби.

    Ініціалізація середовища
    Створення локального Kubernetes-кластеру для тестового розгортання.

    Базове розгортання
    Деплой тестового сервісу hello для перевірки мережевої доступності.

    ArgoCD

        Встановлення ArgoCD в окремий namespace.

        Створення Application для керування нашим додатком через GitOps.

    Доступ до сервісів

        Port-forward для доступу до UI ArgoCD (порт 8080).

        Port-forward для доступу до MVP-додатку (порт 8081).

    Очищення
    Можливість повністю знести кластер та середовище для чистого старту.

### 4) Відкрити UI ArgoCD (Codespaces)
```bash
make argocd-open
```
    У вкладці Ports порту 8080 поставити Public.

    Відкрити URL виду: https://<codespace>-8080.app.github.dev.

    Залогінитись (admin / initial password з POC.md).

Переконатися, що Application → asciiartify має статус Synced/Healthy.
### 5) Переглянути застосунок у браузері
```bash
make app-open
```
    У вкладці Ports порту 8081 поставити Public.

    Відкрити: https://<codespace>-8081.app.github.dev → бачимо “MVP v1”.

### 6) Демо авто-синху (видима зміна)

    Змінити doc: у k8s/app/configmap.yaml замінити MVP v1 → MVP v2.

    Закомітити і запушити в main.

    У UI ArgoCD побачити: OutOfSync → Auto-Sync → Synced.

    Оновити сторінку застосунку (8081/Public) → бачимо “MVP v2”.

Демо (відео)

    Демо роботи застосунку: посилання та Демо авто-синхронізації: 
[![Дивитися відео](https://www.loom.com/share/43be298dfeb14d99863110969feb8aa2/0.jpg)](https://www.loom.com/share/43be298dfeb14d99863110969feb8aa2)