#!/bin/bash
# GX10 Auto-Install Script
# DGX OS 7.2.3 Compatible
#
# Usage:
#   git clone <repo> ~/workspace/gx10-install
#   cd ~/workspace/gx10-install
#   ./install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && pwd)"

echo "=========================================="
echo "    GX10 Auto-Install Script"
echo "=========================================="
echo ""
echo "Project: $PROJECT_ROOT"
echo ""

# Check if running on GX10
echo "[1/8] Checking system..."
if ! command -v nvidia-smi &> /dev/null; then
    echo "❌ nvidia-smi not found. This script must run on GX10 with DGX OS."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ docker not found. This script must run on GX10 with DGX OS."
    exit 1
fi

echo "✅ Running on GX10 with DGX OS"
nvidia-smi --query-gpu=name --format=csv,noheader | head -1
echo ""

# Create directory structure
echo "[2/8] Creating directories..."
sudo mkdir -p /gx10/{api,brains/{code,vision},runtime/logs,system/monitoring}
sudo mkdir -p ~/workspace/scripts
sudo chown -R $USER:$USER /gx10
echo "✅ Directories created"
echo ""

# Install scripts
echo "[3/8] Installing management scripts..."
if [ -d "$SCRIPT_DIR/gx10-scripts" ]; then
    cp "$SCRIPT_DIR/gx10-scripts/api"/*.sh /gx10/api/ 2>/dev/null || true
    cp "$SCRIPT_DIR/gx10-scripts/brains/vision/run.sh" /gx10/brains/vision/ 2>/dev/null || true
    cp "$SCRIPT_DIR/gx10-scripts/brains/vision/Dockerfile" /gx10/brains/vision/ 2>/dev/null || true
    cp "$SCRIPT_DIR/gx10-scripts/system/start-all.sh" /gx10/system/ 2>/dev/null || true
    cp "$SCRIPT_DIR/gx10-scripts/system/monitoring/health-check.sh" /gx10/system/monitoring/ 2>/dev/null || true

    chmod +x /gx10/api/*.sh
    chmod +x /gx10/brains/vision/run.sh
    chmod +x /gx10/system/start-all.sh
    chmod +x /gx10/system/monitoring/health-check.sh

    echo "✅ Management scripts installed"
else
    echo "⚠️  gx10-scripts directory not found, skipping..."
fi
echo ""

# Install workspace scripts
echo "[4/8] Installing workspace scripts..."
if [ -d "$SCRIPT_DIR/gx10-scripts/workspace-scripts" ]; then
    cp "$SCRIPT_DIR/gx10-scripts/workspace-scripts"/*.sh ~/workspace/scripts/ 2>/dev/null || true
    chmod +x ~/workspace/scripts/*.sh
    echo "✅ Workspace scripts installed"
else
    echo "⚠️  workspace-scripts directory not found, skipping..."
fi
echo ""

# Install Ollama
echo "[5/8] Installing Ollama..."
if ! command -v ollama &> /dev/null; then
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh

    # Configure Ollama service
    sudo mkdir -p /etc/systemd/system/ollama.service.d
    sudo tee /etc/systemd/system/ollama.service.d/override.conf << EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_MODELS=/gx10/brains/code/models"
Environment="OLLAMA_KEEP_ALIVE=24h"
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable ollama
    sudo systemctl start ollama

    echo "✅ Ollama installed"
else
    echo "✅ Ollama already installed"
fi
echo ""

# Configure bashrc
echo "[6/8] Configuring bashrc..."
if ! grep -q "GX10 AI System Aliases" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'

# GX10 AI System Aliases (DGX OS)
alias gx-status='/gx10/api/status.sh'
alias gx-switch='/gx10/api/switch.sh'
alias gx-start='/gx10/system/start-all.sh'
alias ai-start='~/workspace/scripts/start-all.sh'
alias ai-status='~/workspace/scripts/status.sh'

# Quick model access
alias chat='ollama run qwen2.5-coder:32b'
alias chat-fast='ollama run qwen2.5-coder:7b'
alias vision='ollama run qwen2.5-vl:7b'

# DGX Dashboard
alias dgx-dash='echo "Access DGX Dashboard at: https://$(hostname -I | awk '"'"'{print $1}'"'"'):6789"'
EOF

    echo "✅ bashrc configured"
else
    echo "✅ bashrc already configured"
fi
echo ""

# Setup health check cron
echo "[7/8] Setting up health check cron..."
if ! crontab -l 2>/dev/null | grep -q "health-check.sh"; then
    (crontab -l 2>/dev/null; echo "*/5 * * * * /gx10/system/monitoring/health-check.sh") | crontab -
    echo "✅ Health check cron added"
else
    echo "✅ Health check cron already configured"
fi
echo ""

# Setup auto-start on boot
echo "[8/8] Setting up auto-start on boot..."
if ! crontab -l 2>/dev/null | grep -q "start-all.sh"; then
    (crontab -l 2>/dev/null; echo "@reboot sleep 60 && /gx10/system/start-all.sh >> /gx10/runtime/logs/startup.log 2>&1") | crontab -
    echo "✅ Auto-start configured"
else
    echo "✅ Auto-start already configured"
fi
echo ""

echo "=========================================="
echo "    Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Reload bashrc: source ~/.bashrc"
echo "  2. Download models: ollama pull qwen2.5-coder:32b"
echo "  3. Check status: gx-status"
echo ""
echo "For detailed instructions, see:"
echo "  $PROJECT_ROOT/INSTALLATION-CHECKLIST.md"
echo ""
