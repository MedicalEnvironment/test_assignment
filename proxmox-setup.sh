#!/bin/bash

# Proxmox Node Preparation Script
# This script prepares a Proxmox VM for Docker-based deployments

set -e

echo "=== Proxmox VM Preparation Script ==="
echo "Preparing node for Docker deployment..."

# Update system packages
echo "[1/5] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install QEMU Guest Agent for Proxmox integration
echo "[2/5] Installing QEMU Guest Agent..."
sudo apt install -y qemu-guest-agent
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent

# Install Docker
echo "[3/5] Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    echo "Docker installed successfully"
else
    echo "Docker already installed"
fi

# Install Docker Compose
echo "[4/5] Installing Docker Compose..."
if ! command -v docker compose &> /dev/null; then
    sudo apt install -y docker-compose-plugin
    echo "Docker Compose installed successfully"
else
    echo "Docker Compose already installed"
fi

# Configure Docker to start on boot
echo "[5/5] Configuring Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Add current user to docker group
sudo usermod -aG docker $USER
sudo usermod -aG docker jenkins || true

echo ""
echo "=== Setup Complete ==="
echo "Docker version: $(docker --version)"
echo "Docker Compose version: $(docker compose version)"
echo ""
echo "Note: You may need to log out and back in for group changes to take effect"
echo ""
echo "Proxmox VM is ready for deployment!"
