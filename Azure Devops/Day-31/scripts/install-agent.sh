#!/bin/bash
# ============================================================
# Azure DevOps Self-Hosted Agent Installer
# Run this on the Azure VM after setup-vm.sh
#
# Prerequisites:
#   - Azure DevOps PAT token with Agent Pools (read, manage) scope
#   - Agent Pool "SelfHostedPool" created in Azure DevOps
#
# Usage:
#   export AZP_URL="https://dev.azure.com/your-org"
#   export AZP_TOKEN="your-pat-token"
#   bash install-agent.sh
# ============================================================

set -e

# Check required environment variables
if [ -z "$AZP_URL" ]; then
    echo "Error: AZP_URL is not set"
    echo "Usage: export AZP_URL='https://dev.azure.com/your-org'"
    exit 1
fi

if [ -z "$AZP_TOKEN" ]; then
    echo "Error: AZP_TOKEN is not set"
    echo "Usage: export AZP_TOKEN='your-pat-token'"
    exit 1
fi

AZP_POOL="${AZP_POOL:-SelfHostedPool}"
AZP_AGENT_NAME="${AZP_AGENT_NAME:-skillpulse-agent}"

echo "========================================"
echo "  Azure DevOps Agent Installer"
echo "========================================"
echo "  Organization: $AZP_URL"
echo "  Pool:         $AZP_POOL"
echo "  Agent Name:   $AZP_AGENT_NAME"
echo "========================================"

# Install dependencies
echo "[1/5] Installing dependencies..."
sudo apt install -y curl jq

# Create agent directory
echo "[2/5] Creating agent directory..."
mkdir -p ~/azp-agent && cd ~/azp-agent

# Get latest agent version
echo "[3/5] Downloading latest agent..."
AZP_AGENT_RESPONSE=$(curl -s -u user:${AZP_TOKEN} \
    "${AZP_URL}/_apis/distributedtask/packages/agent?platform=linux-x64&\$top=1" \
    -H "Accept:application/json")

AZP_AGENT_URL=$(echo "$AZP_AGENT_RESPONSE" | jq -r '.value[0].downloadUrl')

if [ -z "$AZP_AGENT_URL" ] || [ "$AZP_AGENT_URL" = "null" ]; then
    echo "Error: Could not get agent download URL"
    echo "Check your AZP_URL and AZP_TOKEN"
    exit 1
fi

curl -sL "$AZP_AGENT_URL" | tar -xz

# Configure agent
echo "[4/5] Configuring agent..."
./config.sh --unattended \
    --url "$AZP_URL" \
    --auth pat \
    --token "$AZP_TOKEN" \
    --pool "$AZP_POOL" \
    --agent "$AZP_AGENT_NAME" \
    --acceptTeeEula \
    --replace

# Install and start as service
echo "[5/5] Installing agent as a service..."
sudo ./svc.sh install
sudo ./svc.sh start

echo ""
echo "========================================"
echo "  Agent installed and running!"
echo "========================================"
echo ""
echo "Verify in Azure DevOps:"
echo "  Project Settings > Agent Pools > $AZP_POOL"
echo "  You should see '$AZP_AGENT_NAME' as Online"
echo ""
echo "To check agent status:  sudo ./svc.sh status"
echo "To stop agent:          sudo ./svc.sh stop"
echo "To uninstall agent:     sudo ./svc.sh uninstall"
