# AsciiArtify
AsciiArtify — PoC стартапу для перетворення зображень у ASCII-art за допомогою ML. Проведено порівняння локальних Kubernetes-інструментів (minikube, kind, k3d) з урахуванням ризиків ліцензування Docker та можливості Podman. Рекомендовано kind для дев-середовища та CI.
## Changelog
- Додано інструкцію PoC з розгортання ArgoCD у `doc/POC.md`.
- Додано ціль `kind-install` у Makefile для автоматичної інсталяції kind.
- Додано doc/POC.md — інструкція по доступу до ArgoCD UI.
- Оновлено Makefile — додані цілі:

 kind-install — встановлення Kind.
 argocd-install — інсталяція ArgoCD і CRD.
 app-apply / app-delete — створення та видалення ArgoCD Application.
 argocd-open / app-open — швидкий доступ до ArgoCD UI та MVP-додатку.

- Оновлено README.md з описом останніх змін.
- Додано Kubernetes-маніфести в k8s/argocd/ та k8s/app/ для автоматичного деплою додатку через ArgoCD.
- Налаштовано автоматичну синхронізацію ArgoCD з GitHub-репозиторієм.