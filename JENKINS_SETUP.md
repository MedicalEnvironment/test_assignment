# Jenkins CI/CD Setup Guide

## Требования

- Debian based VM с установленным Jenkins
- Docker и Docker Compose на сервере
- Git на сервере
- Доступ к GitHub репозиторию

## 1. Установка Jenkins на Lubuntu

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Java (требуется для Jenkins)
sudo apt install openjdk-17-jdk -y

# Добавление ключа Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Добавление репозитория Jenkins
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Установка Jenkins
sudo apt update
sudo apt install jenkins -y

# Запуск Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Проверка статуса
sudo systemctl status jenkins
```

Jenkins будет доступен на `http://your-vm-ip:8080`

## 2. Первоначальная настройка Jenkins

1. Получите начальный пароль:
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

2. Откройте Jenkins в браузере и введите пароль
3. Установите рекомендуемые плагины
4. Создайте администратора

## 3. Установка необходимых плагинов

В Jenkins перейдите: **Manage Jenkins → Plugins → Available Plugins**

Установите:
- Git Plugin
- GitHub Plugin
- Docker Plugin
- Docker Pipeline Plugin
- Pipeline Plugin
- Credentials Plugin

## 4. Настройка Docker для Jenkins

```bash
# Добавьте пользователя jenkins в группу docker
sudo usermod -aG docker jenkins

# Перезапустите Jenkins
sudo systemctl restart jenkins

# Проверьте доступ (выполните от имени jenkins)
sudo -u jenkins docker ps
```

## 5. Настройка GitHub Webhook (опционально, для автоматического триггера)

### На GitHub:

1. Перейдите в репозиторий: **Settings → Webhooks → Add webhook**
2. Payload URL: `http://your-lubuntu-ip:8080/github-webhook/`
3. Content type: `application/json`
4. Events: `Just the push event`
5. Active: ✓
6. Сохраните

### В Jenkins:

Webhook будет работать автоматически, если в Jenkinsfile указан `githubPush()` триггер.

## 6. Создание Jenkins Pipeline Job

1. В Jenkins: **New Item**
2. Имя: `hello-world-app-pipeline`
3. Тип: **Pipeline**
4. OK

### Настройка Pipeline:

**General:**
- ✓ GitHub project: `https://github.com/MedicalEnvironment/test_assignment`

**Build Triggers:**
- ✓ GitHub hook trigger for GITScm polling

**Pipeline:**
- Definition: **Pipeline script from SCM**
- SCM: **Git**
- Repository URL: `https://github.com/MedicalEnvironment/test_assignment.git`
- Credentials: Добавьте свои GitHub credentials (если репозиторий приватный)
- Branch: `*/main`
- Script Path: `Jenkinsfile`

Сохраните.

## 7. Настройка учетных данных (если нужны)

**Manage Jenkins → Credentials → System → Global credentials → Add Credentials**

### Для GitHub (если приватный репозиторий):
- Kind: **Username with password**
- Username: ваш GitHub username
- Password: GitHub Personal Access Token
- ID: `github-credentials`

### Для Docker Hub (если будете пушить образы):
- Kind: **Username with password**
- Username: ваш Docker Hub username
- Password: Docker Hub password
- ID: `dockerhub-credentials`

## 8. Подготовка сервера для деплоя

```bash
# Создайте директорию для приложения
sudo mkdir -p /opt/hello-world-app
sudo chown jenkins:jenkins /opt/hello-world-app

# Клонируйте репозиторий (первый раз)
cd /opt/hello-world-app
git clone https://github.com/MedicalEnvironment/test_assignment.git .

# Создайте лог файл
sudo touch /var/log/hello-world-deploy.log
sudo chown jenkins:jenkins /var/log/hello-world-deploy.log

# Сделайте deploy.sh исполняемым
chmod +x /opt/hello-world-app/deploy.sh
```

## 9. Запуск первого билда

1. Откройте ваш Pipeline job в Jenkins
2. Нажмите **Build Now**
3. Наблюдайте за логами в **Console Output**

## 10. Проверка работы приложения

После успешного деплоя:

```bash
# Проверка контейнеров
docker ps

# Проверка логов
docker compose logs

# Проверка приложения
curl http://localhost
curl http://localhost/health
curl http://localhost/nginx-health
```

Приложение будет доступно на `http://your-lubuntu-ip`

## Troubleshooting

### Проблема: Jenkins не может выполнить docker команды

**Решение:**
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Проблема: Permission denied при git pull

**Решение:**
```bash
# Настройте SSH ключи для jenkins пользователя
sudo -u jenkins ssh-keygen -t ed25519 -C "jenkins@lubuntu"
# Добавьте публичный ключ в GitHub Deploy Keys
sudo cat /var/lib/jenkins/.ssh/id_ed25519.pub
```

### Проблема: Port 80 уже занят

**Решение:**
```bash
# Проверьте, что использует порт 80
sudo lsof -i :80
# Остановите конфликтующий сервис или измените порт в docker-compose.yml
```

### Проблема: Health check fails

**Решение:**
```bash
# Проверьте логи контейнеров
docker compose logs

# Проверьте статус
docker compose ps

# Перезапустите
docker compose restart
```

## Архитектура CI/CD Pipeline

```
GitHub Push → Webhook → Jenkins Pipeline
                            ↓
                    1. Checkout Code
                            ↓
                    2. Build Docker Images
                            ↓
                    3. Run Tests
                            ↓
                    4. Tag Images
                            ↓
                    5. Deploy (docker compose up)
                            ↓
                    6. Verify Health Checks
                            ↓
                    Success ✓ / Rollback ✗
```

## Дополнительные улучшения

### 1. Добавить email уведомления

В Jenkinsfile раскомментируйте секции `emailext` и настройте:
**Manage Jenkins → System → E-mail Notification**

### 2. Использовать Docker Registry

Раскомментируйте секцию Push to Registry в Jenkinsfile и настройте credentials.

### 3. Мониторинг

Установите Prometheus и Grafana для мониторинга:
```bash
# Добавьте в docker-compose.yml сервисы мониторинга
```

### 4. Secrets Management

Используйте Jenkins Credentials для хранения секретов вместо хардкода в коде.

## Полезные команды

```bash
# Jenkins логи
sudo journalctl -u jenkins -f

# Перезапуск Jenkins
sudo systemctl restart jenkins

# Проверка дискового пространства
df -h

# Очистка Docker
docker system prune -a --volumes
```

## Контакты и поддержка

При возникновении проблем проверьте:
- Jenkins Console Output
- `/var/log/hello-world-deploy.log`
- `docker compose logs`
