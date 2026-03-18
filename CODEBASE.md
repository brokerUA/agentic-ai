# Документация кодовой базы AI Agent

## Краткое описание проекта

Этот проект реализует облачную инфраструктуру для AI-агентов на базе Kubernetes, используя `agentgateway` (в режиме KGway с **Kubernetes Gateway API**) и `kagent`. Он позволяет развертывать AI-агентов и их конфигурации как стандартные ресурсы Kubernetes.

## Архитектура

- **AgentGateway (режим KGway)**: Полностью интегрирован с Kubernetes Gateway API (`Gateway`, `HTTPRoute`, `AgentgatewayBackend`). Выступает в качестве шлюза для маршрутизации запросов к различным провайдерам LLM.
- **KAgent**: Контроллер и агенты, управляющие жизненным циклом AI-агентов в кластере.
- **Инфраструктурный слой**: Использует стандартные объекты Kubernetes (Secret, ConfigMap, ReferenceGrant) вместе с Custom Resource Definitions (CRDs) от `agentgateway` и `kagent`.

## Структура проекта

- `kubernetes/apps/`: Содержит манифесты приложений Kubernetes, включая `agentgateway.yaml`, `kagent.yaml`, `infra.yaml` (секреты, роутинг) и `platform-agent.yaml`.
- `kubernetes/crds/`: Содержит определения пользовательских ресурсов (CRDs) для `agentgateway`, `kagent` и Gateway API.
- `infrastructure/bootstrap/`: Конфигурация Terraform для подготовки облачной инфраструктуры и Flux CD.
- `scripts/`: Утилиты для тестирования и проверки развернутой инфраструктуры.
- `.github/workflows/`: CI/CD пайплайны для Flux CD и автоматизации репозитория.
- `.mise/tasks/`: Пользовательские задачи `mise` для настройки и развертывания проекта.

## Основные типы домена (CRDs)

- `Agent`: Определяет поведение AI агента и связанную с ним конфигурацию модели.
- `ModelConfig`: Настраивает провайдера LLM, модель и аутентификацию для агентов.
- `MCPServer`: (KAgent CRD) Описывает сервер Model Context Protocol для предоставления инструментов агентам.
- `AgentgatewayBackend`: Определяет, как `agentgateway` должен маршрутизировать и обрабатывать AI запросы (например, Gemini).
- `Gateway`, `HTTPRoute`: Стандартные ресурсы Kubernetes Gateway API, используемые для маршрутизации.

## Соглашения по именованию

- Манифесты Kubernetes используют `kebab-case` для имен файлов (например, `platform-agent.yaml`).
- Имена ресурсов внутри манифестов также следуют `kebab-case`.
- Пространства имен (Namespaces) используются согласованно: `agentgateway-system` для шлюза и `kagent` для агентов.

## Паттерны кода

- **Декларативное управление**: Вся инфраструктура и конфигурации агентов управляются как манифесты YAML.
- **Интеграция с Gateway API**: Использование `HTTPRoute` с `parentRefs` для привязки маршрутов к `Gateway`.
- **Управление секретами**: API-ключи и конфиденциальные данные обрабатываются через `Secret` Kubernetes и ссылаются в `ModelConfig` или `AgentgatewayBackend`.
- **Инструменты (Tools)**: Использование MCP (Model Context Protocol) для расширения возможностей агентов через внешние серверы.
