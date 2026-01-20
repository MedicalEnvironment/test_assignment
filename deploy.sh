#!/bin/bash

# Deploy script for Hello World Application
# This script handles zero-downtime deployment

set -e  # Exit on error

APP_DIR="/opt/hello-world-app"
BACKUP_DIR="/opt/hello-world-app-backup"
LOG_FILE="/var/log/hello-world-deploy.log"

echo "[$(date)] Starting deployment..." | tee -a $LOG_FILE

# Function to log messages
log() {
    echo "[$(date)] $1" | tee -a $LOG_FILE
}

# Function to rollback
rollback() {
    log "ERROR: Deployment failed! Rolling back..."
    cd $APP_DIR
    docker compose down
    
    if [ -d "$BACKUP_DIR" ]; then
        log "Restoring from backup..."
        cp -r $BACKUP_DIR/* $APP_DIR/
        docker compose up -d
        log "Rollback completed"
    fi
    
    exit 1
}

# Set trap for errors
trap rollback ERR

# Navigate to application directory
cd $APP_DIR

# Create backup
log "Creating backup..."
rm -rf $BACKUP_DIR
mkdir -p $BACKUP_DIR
cp -r $APP_DIR/* $BACKUP_DIR/ || true

# Pull latest changes
log "Pulling latest changes from Git..."
git pull origin main

# Stop old containers gracefully
log "Stopping old containers..."
docker compose down --timeout 30

# Remove old images
log "Cleaning up old images..."
docker image prune -f

# Build new images
log "Building new Docker images..."
docker compose build --no-cache

# Start new containers
log "Starting new containers..."
docker compose up -d

# Wait for containers to be healthy
log "Waiting for health checks..."
sleep 15

# Verify deployment
log "Verifying deployment..."

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    log "ERROR: Containers are not running!"
    rollback
fi

# Health check
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f http://localhost/health > /dev/null 2>&1; then
        log "Health check passed!"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    log "Health check attempt $RETRY_COUNT/$MAX_RETRIES..."
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    log "ERROR: Health check failed after $MAX_RETRIES attempts!"
    rollback
fi

# Test main endpoint
if ! curl -f http://localhost/ > /dev/null 2>&1; then
    log "ERROR: Main endpoint is not responding!"
    rollback
fi

# Clean up backup after successful deployment
log "Cleaning up backup..."
rm -rf $BACKUP_DIR

log "Deployment completed successfully!"
log "Application is running on http://localhost"

# Display running containers
docker compose ps

exit 0
