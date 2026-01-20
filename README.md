# Hello World DevOps Project

Контейнеризированное Node.js/Express приложение с Nginx reverse proxy и CI/CD через Jenkins.

## Быстрый старт

### Локальный запуск

```bash
# Клонировать репозиторий
git clone https://github.com/MedicalEnvironment/test_assignment.git
cd test_assignment

# Запустить
docker compose up -d

# Проверить
curl http://localhost
```

### Остановка

```bash
docker compose down
```

## Структура проекта

```
├── app.js                  # Express приложение
├── package.json            # Node.js зависимости
├── Dockerfile              # Multi-stage Docker build
├── docker-compose.yml      # Nginx + 2 экземпляра приложения
├── nginx.conf              # Конфигурация reverse proxy
├── Jenkinsfile             # CI/CD pipeline
├── deploy.sh               # Скрипт деплоя
├── proxmox-setup.sh        # Подготовка ноды в Proxmox VE
└── README.md               # Документация
```

## Endpoints

- `http://localhost` - основное приложение
- `http://localhost/health` - health check приложения
- `http://localhost/nginx-health` - health check Nginx

## Особенности

**Docker:**
- Multi-stage build (оптимизация размера образа)
- Non-root пользователь
- Alpine Linux базовый образ
- Health checks для всех сервисов

**Nginx:**
- Балансировка нагрузки между 2 экземплярами
- Автоматический failover при ошибках
- Keep-alive соединения

**Zero-downtime deployment:**
- Graceful shutdown (10 сек таймаут)
- Health checks перед приемом трафика
- Автоматический rollback при ошибках

**CI/CD Pipeline:**
- Триггер на push в main ветку
- Автоматическая сборка образов
- Тесты перед деплоем
- Деплой на Lubuntu сервер
- Проверка health checks

## Jenkins Setup

**Кратко:**

```bash
# На Lubuntu
sudo apt update && sudo apt install openjdk-17-jdk -y
# Установить Jenkins (см. JENKINS_SETUP.md)
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

**В Jenkins UI:**
1. New Item → Pipeline
2. GitHub project: `https://github.com/MedicalEnvironment/test_assignment`
3. Build Triggers: ✓ GitHub hook trigger
4. Pipeline: Script from SCM → Git → `Jenkinsfile`

**Запуск:** Push в main или Build Now в Jenkins

## Логирование

```bash
# На сервере деплоя
cd /var/lib/jenkins/workspace/my-web-app
docker compose logs -f

# Или по имени контейнера
docker logs -f nginx-proxy
docker logs -f hello-world-app-1
docker logs -f hello-world-app-2

# Jenkins логи
sudo journalctl -u jenkins -f

# Деплой лог
tail -f /var/log/hello-world-deploy.log
```

## Проверка работы

```bash
# Статус контейнеров
docker ps

# Health checks
curl http://localhost/health
curl http://localhost/nginx-health

# Балансировка (несколько запросов)
for i in {1..10}; do curl http://localhost; echo; done
```

## Технологии

- **Runtime:** Node.js 18 (Alpine)
- **Framework:** Express.js 4.18
- **Reverse Proxy:** Nginx (Alpine)
- **Containerization:** Docker, Docker Compose
- **CI/CD:** Jenkins
- **Server:** Lubuntu VM

## Infrastructure & Proxmox (Virtualization)

Хотя проект запущен на демонстрационной виртуальной машине Lubuntu, архитектура полностью готова к развертыванию в **Proxmox VE**:

**Тип виртуализации:**
- Рекомендуется использовать **KVM** (виртуальную машину), а не LXC-контейнер
- Docker требует специфических настроек ядра, которые проще изолировать внутри полноценной ВМ

**Сетевая настройка:**
- Создается виртуальный мост `vmbr0`
- ВМ назначается статический IP в локальной сети Proxmox
- Стабильная связь с Jenkins и внешними сервисами

**Автоматизация (IaC):**
- Развертывание может быть автоматизировано через **Terraform** (провайдер `telmate/proxmox`)
- Или через **Ansible** для конфигурации нод

**SSH Access:**
- Доступ к ноде организован по SSH-ключам
- Позволяет Jenkins выполнять команды `docker compose` удаленно
- В данном демо Jenkins работает локально для упрощения

**Подготовка ноды:**
```bash
# Автоматическая подготовка ноды (рекомендуется)
chmod +x proxmox-setup.sh
./proxmox-setup.sh

# Или вручную:
# Установка QEMU Guest Agent для интеграции с Proxmox
sudo apt update && sudo apt install -y qemu-guest-agent
sudo systemctl enable qemu-guest-agent

# Docker уже установлен через стандартный скрипт
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

## Пример успешной развертки работы

**Контейнеры в рабочем состоянии:**
- 3 контейнера: nginx-proxy, hello-world-app-1, hello-world-app-2
- Все контейнеры имеют статус `healthy`
- Минимальное потребление ресурсов (~20MB RAM на контейнер приложения)

**Jenkins CI/CD Pipeline:**
- Build #9 выполнен успешно
- История билдов показывает стабильность пайплайна
- Zero-downtime deployment работает корректно

**Endpoints проверены:**
- `http://localhost` → "Hello, World!" ✓
- `http://localhost/health` → {"status":"healthy","timestamp":""} ✓
- `http://localhost/nginx-health` → "Nginx is healthy" ✓

**Docker контейнеры:**
```
CONTAINER ID   IMAGE                  STATUS                   NAMES
7a25965ba7e9   my-web-app-web2       Up 10 minutes (healthy)  hello-world-app-2
531f24a6fcb5   my-web-app-web1       Up 10 minutes (healthy)  hello-world-app-1
64e50df8511c   nginx:alpine          Up 26 minutes (healthy)  nginx-proxy
```

## Автор

Akbar Abayev
