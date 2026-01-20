# Hello World Web Application

Простое веб-приложение на Node.js/Express, контейнеризированное с помощью Docker.

## Описание проекта

Это приложение выводит "Hello, World!" при обращении к корневому URL. Приложение развернуто в двух экземплярах за Nginx reverse proxy с балансировкой нагрузки.

## Структура проекта

- `app.js` - основной файл приложения Express
- `package.json` - зависимости Node.js
- `Dockerfile` - инструкции для создания Docker-образа
- `docker-compose.yml` - конфигурация для Docker Compose (Nginx + 2 экземпляра приложения)
- `nginx.conf` - конфигурация Nginx как reverse proxy
- `.dockerignore` - файлы, исключаемые из Docker-образа

## Запуск приложения

### С использованием Docker Compose:

```bash
docker compose up -d
```

Приложение будет доступно по адресу: http://localhost

**Примечание:** Nginx работает на порту 80 и проксирует запросы к двум экземплярам приложения (web1 и web2) с балансировкой нагрузки.

### Остановка приложения:

```bash
docker compose down
```

### Просмотр логов:

```bash
docker compose logs
```

### Пересборка образа:

```bash
docker compose up -d --build
```

## Технологии

- Node.js 18
- Express.js 4.18
- Nginx (Alpine) как reverse proxy
- Docker
- Docker Compose
