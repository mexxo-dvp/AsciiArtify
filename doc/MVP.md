# MVP — ArgoCD автосинхронізація (AsciiArtify)

### Мета: 
розгорнути наш застосунок через ArgoCD з **Auto-Sync** і продемонструвати автоматичну синхронізацію змін з Git.

### Передумови
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
## ArgoCD
![Скріншот інтерфейсу](https://raw.githubusercontent.com/mexxo-dvp/AsciiArtify/main/doc/argocd.jpg)

## Доступ до сервісів

Port-forward для доступу до UI ArgoCD (порт 8080).

Port-forward для доступу до MVP-додатку (порт 8081).

## Деплой UI ArgoCD (Codespaces)
```bash
make app-apply
```
Детальний опис процесу деплою:
```bash
	@echo "Applying ArgoCD Application 'asciiartify'..."
	kubectl apply -f k8s/argocd/asciiartify-app.yaml
	kubectl -n argocd get applications.argoproj.io
```
У вкладці Ports порту 8080 поставити Public.

Відкрити URL виду: https://<codespace>-8080.app.github.dev.

Залогінитись (admin / initial password з POC.md).

Переконатися, що Application → asciiartify має статус Synced/Healthy.
## Переглянути застосунок у браузері
```bash
make app-open
```
У вкладці Ports порту 8081 поставити Public.

Відкрити: https://<codespace>-8081.app.github.dev → бачимо “MVP v1”.

### TLS-захист
У нашій реалізації не виконувалось налаштування доступу до ArgoCD через порт 443 з використанням самопідписаного сертифіката, оскільки робота здійснюється в середовищі GitHub Codespaces. Дане середовище автоматично прокидує увесь трафік через HTTPS із валідним SSL-сертифікатом, виданим для доменів формату *.github.dev.
Таким чином, навіть за умови, що ArgoCD у межах кластера працює по HTTP, підключення до веб-інтерфейсу ззовні вже захищене шифруванням TLS/SSL на рівні інфраструктури Codespaces.

## Демо авто-синху (видима зміна)

Змінити doc: у k8s/app/configmap.yaml замінити MVP v1 → MVP v2.

Закомітити і запушити в main.

У UI ArgoCD побачити: OutOfSync → Auto-Sync → Synced.

Оновити сторінку застосунку (8081/Public) → бачимо “MVP v2”.

Демо (відео)

Демо роботи застосунку: посилання та Демо авто-синхронізації: 
[![Дивитися відео](https://www.loom.com/share/e1ff9d94580842e8b900ce42f6ab35d5?sid=cbfedf14-0a19-4625-afd1-e941449998e2/0.jpg)](https://www.loom.com/share/e1ff9d94580842e8b900ce42f6ab35d5?sid=cbfedf14-0a19-4625-afd1-e941449998e2)

