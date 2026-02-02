#!/bin/bash
# GX10 AI Services Startup Script
# DGX OS 7.2.3 Compatible

set -euo pipefail

echo "=========================================="
echo "    GX10 AI Services Starting...          "
echo "=========================================="
echo ""

# Workspace directories
WORKSPACE="$HOME/workspace"
LOG_DIR="$WORKSPACE/logs"

mkdir -p "$LOG_DIR"

# 1. Start Ollama
echo "[1/4] Starting Ollama..."
if systemctl list-unit-files | grep -q ollama.service 2>/dev/null; then
    # Check if ollama command exists
    if ! command -v ollama &> /dev/null; then
        echo "  ⚠️  ollama not found, installing..."
        curl -fsSL https://ollama.com/install.sh | sh 2>/dev/null || {
            echo "  ❌ Failed to install Ollama"
        }
    fi

    sudo systemctl start ollama 2>/dev/null || true
    sleep 3

    if systemctl is-active --quiet ollama 2>/dev/null; then
        echo "  ✅ Ollama started"
    else
        echo "  ⚠️  Ollama failed to start"
    fi
else
    echo "  ⚠️  ollama.service not found"
    echo "  Install Ollama: curl -fsSL https://ollama.com/install.sh | sh"
fi

# 2. Start Open WebUI
echo "[2/4] Checking Open WebUI..."
if command -v docker &> /dev/null; then
    if docker ps -a -q -f name=open-webui 2>/dev/null | grep -q .; then
        docker start open-webui 2>/dev/null || true
    else
        # Only try to create if user wants Open WebUI
        echo "  ℹ️  Open WebUI not installed"
        echo "  To install: docker run -d --name open-webui --restart unless-stopped --gpus all -p 8080:8080 -v open-webui-data:/app/backend/data -e OLLAMA_BASE_URL=http://host.docker.internal:11434 --add-host=host.docker.internal:host-gateway ghcr.io/open-webui/open-webui:main"
    fi

    if docker ps -q -f name=open-webui 2>/dev/null | grep -q .; then
        echo "  ✅ Open WebUI running"
    else
        echo "  ℹ️  Open WebUI not running"
    fi
else
    echo "  ⚠️  Docker not available"
fi

# 3. Start Jupyter Lab (if configured)
echo "[3/4] Checking Jupyter Lab..."
if systemctl list-unit-files | grep -q jupyter.service 2>/dev/null; then
    sudo systemctl start jupyter 2>/dev/null || true

    if systemctl is-active --quiet jupyter 2>/dev/null; then
        echo "  ✅ Jupyter Lab started"
    else
        echo "  ℹ️  Jupyter Lab not running"
    fi
else
    echo "  ℹ️  Jupyter service not configured"
fi

# 4. Check services
echo "[4/4] Checking services..."
sleep 2

echo ""
echo "=========================================="
echo "    Services Status                      "
echo "=========================================="
echo ""

# Ollama
if command -v curl &> /dev/null && curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
    echo "✅ Ollama API  : http://localhost:11434"
elif systemctl is-active --quiet ollama 2>/dev/null; then
    echo "✅ Ollama      : Running (API not responding yet)"
else
    echo "❌ Ollama      : Not running"
fi

# Open WebUI
if docker ps -q -f name=open-webui 2>/dev/null | grep -q .; then
    echo "✅ Open WebUI  : http://localhost:8080"
else
    echo "ℹ️  Open WebUI  : Not installed or not running"
fi

# Jupyter Lab
if systemctl is-active --quiet jupyter 2>/dev/null; then
    echo "✅ Jupyter Lab : http://localhost:8888"
elif command -v docker &> /dev/null && docker ps -q -f name=jupyter 2>/dev/null | grep -q .; then
    echo "✅ Jupyter Lab : http://localhost:8888 (Docker)"
else
    echo "ℹ️  Jupyter Lab : Not configured"
fi

echo ""
echo "Logs: $LOG_DIR/"
echo ""
