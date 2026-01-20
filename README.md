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
└── JENKINS_SETUP.md        # Инструкция по настройке Jenkins
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

## Автор

Akbar Abayev
