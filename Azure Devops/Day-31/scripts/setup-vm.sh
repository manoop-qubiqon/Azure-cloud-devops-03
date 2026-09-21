#!/bin/bash
# ============================================================
# SkillPulse VM Setup Script
# Run this on a fresh Ubuntu 22.04 Azure VM
# Usage: curl -sL <raw-url> | bash
# ============================================================

set -e

echo "========================================"
echo "  SkillPulse VM Setup"
echo "========================================"

# Update system
echo "[1/5] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
echo "[2/5] Installing Docker..."
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Install Docker Compose
echo "[3/5] Installing Docker Compose..."
sudo apt install -y docker-compose-v2

# Install Git
echo "[4/5] Installing Git..."
sudo apt install -y git

# Create project directory
echo "[5/5] Creating project directory..."
sudo mkdir -p /opt/skillpulse
sudo chown $USER:$USER /opt/skillpulse

echo ""
echo "========================================"
echo "  VM Setup Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Log out and back in (for Docker group to take effect)"
echo "  2. Clone your repo: git clone <repo-url> /opt/skillpulse"
echo "  3. Run the agent installer: bash install-agent.sh"
echo ""
echo "Docker version:"
docker --version
echo ""
echo "Docker Compose version:"
docker compose version
