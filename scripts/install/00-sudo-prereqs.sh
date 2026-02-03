#!/bin/bash
#############################################
# GX10 Phase 0: Sudo Prerequisites
# Run ALL sudo-required operations upfront
#
# Purpose: Execute all privileged commands in one session
# so that subsequent phases can run without sudo.
#
# Usage: sudo ./00-sudo-prereqs.sh
#
# Author: holee
# Created: 2026-02-03
#############################################

set -e
set -u

# Verify running as root
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: This script must be run with sudo"
  echo "Usage: sudo ./00-sudo-prereqs.sh"
  exit 1
fi

ACTUAL_USER="${SUDO_USER:-$USER}"
LOG_DIR="/gx10/runtime/logs"

echo "=========================================="
echo "GX10 Phase 0: Sudo Prerequisites"
echo "=========================================="
echo "User: $ACTUAL_USER"
echo "Date: $(date)"
echo ""
echo "This script will execute ALL sudo-required"
echo "operations so subsequent phases can run"
echo "without elevated privileges."
echo ""
echo "Estimated time: 15-20 minutes"
echo "=========================================="
echo ""

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [Phase 0] $1"
}

# ==========================================
# Section 1: System Package Update
# ==========================================
log "=== Section 1/7: System Package Update ==="

apt update && apt upgrade -y

apt install -y \
  build-essential cmake git curl wget \
  htop btop tmux vim neovim tree jq unzip \
  net-tools openssh-server \
  python3-pip python3-venv python3-dev \
  pkg-config libssl-dev libffi-dev

log "Section 1 complete: System packages installed"

# ==========================================
# Section 2: SSH and Firewall Configuration
# ==========================================
log "=== Section 2/7: SSH & Firewall ==="

systemctl enable ssh
systemctl start ssh

ufw allow ssh
ufw allow 11434/tcp   # Ollama API
ufw allow 8080/tcp    # Open WebUI
ufw allow 5678/tcp    # n8n
ufw --force enable

log "Section 2 complete: SSH enabled, firewall configured"

# ==========================================
# Section 3: Directory Structure & Permissions
# ==========================================
log "=== Section 3/7: Directory Structure ==="

mkdir -p /gx10/brains/code/{models,prompts,execution,logs}
mkdir -p /gx10/brains/vision/{models,cuda,benchmarks,logs}
mkdir -p /gx10/runtime/{locks,logs}
mkdir -p /gx10/api
mkdir -p /gx10/automation/{n8n,mcp}
mkdir -p /gx10/system/{monitoring,update,backup}

# Transfer ownership to actual user
chown -R "$ACTUAL_USER:$ACTUAL_USER" /gx10

log "Section 3 complete: /gx10 directory structure created, owned by $ACTUAL_USER"

# ==========================================
# Section 4: Docker Group Setup
# ==========================================
log "=== Section 4/7: Docker Group ==="

if groups "$ACTUAL_USER" | grep -q docker; then
  log "User $ACTUAL_USER already in docker group"
else
  usermod -aG docker "$ACTUAL_USER"
  log "User $ACTUAL_USER added to docker group"
  log "NOTE: Re-login required for docker group to take effect"
fi

# ==========================================
# Section 5: Ollama Installation
# ==========================================
log "=== Section 5/7: Ollama Installation ==="

if command -v ollama &> /dev/null; then
  log "Ollama already installed: $(ollama --version)"
else
  curl -fsSL https://ollama.com/install.sh | sh
  log "Ollama installed: $(ollama --version)"
fi

# ==========================================
# Section 6: Ollama Service Configuration
# ==========================================
log "=== Section 6/7: Ollama Service Configuration ==="

mkdir -p /etc/systemd/system/ollama.service.d

tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null << EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_MODELS=/gx10/brains/code/models"
Environment="OLLAMA_KEEP_ALIVE=24h"
Environment="OLLAMA_NUM_PARALLEL=2"
Environment="OLLAMA_MAX_LOADED_MODELS=2"
EOF

systemctl daemon-reload
systemctl enable ollama
systemctl restart ollama

log "Section 6 complete: Ollama service configured and started"

# ==========================================
# Section 7: Monitoring Service (Optional)
# ==========================================
log "=== Section 7/7: Monitoring Service ==="

tee /etc/systemd/system/gx10-monitor.service > /dev/null << EOF
[Unit]
Description=GX10 System Monitor
After=network.target ollama.service

[Service]
Type=oneshot
User=$ACTUAL_USER
ExecStart=/gx10/system/monitoring/health-check.sh
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

tee /etc/systemd/system/gx10-monitor.timer > /dev/null << EOF
[Unit]
Description=GX10 Monitor Timer (every 5 minutes)

[Timer]
OnBootSec=120
OnUnitActiveSec=300

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload

log "Section 7 complete: Monitoring service registered (not enabled yet)"

# ==========================================
# Summary
# ==========================================
echo ""
echo "=========================================="
echo "Phase 0: Sudo Prerequisites COMPLETED"
echo "=========================================="
echo ""
echo "Completed operations:"
echo "  [OK] System packages updated and installed"
echo "  [OK] SSH enabled, firewall configured (ports: 22, 11434, 8080, 5678)"
echo "  [OK] /gx10 directory structure created (owned by $ACTUAL_USER)"
echo "  [OK] Docker group: $ACTUAL_USER added"
echo "  [OK] Ollama installed and service configured"
echo "  [OK] Ollama systemd override (0.0.0.0, /gx10/brains/code/models)"
echo "  [OK] Monitoring service registered"
echo ""
echo "=========================================="
echo "IMPORTANT: Next steps (NO sudo required)"
echo "=========================================="
echo ""
echo "1. Re-login or run: newgrp docker"
echo "   (Required for docker group to take effect)"
echo ""
echo "2. Verify Ollama:"
echo "   ollama --version"
echo "   curl http://localhost:11434/api/version"
echo ""
echo "3. Download AI models (no sudo needed):"
echo "   ollama pull qwen2.5-coder:32b    # ~30min"
echo "   ollama pull qwen2.5-coder:7b     # ~10min"
echo ""
echo "4. Continue with remaining phases:"
echo "   ./05-code-models-download.sh"
echo "   ./06-vision-brain-build.sh"
echo "   ./07-brain-switch-api.sh"
echo "   ./08-webui-install.sh"
echo "   ./10-final-validation.sh"
echo ""
echo "All remaining phases can run WITHOUT sudo."
echo "=========================================="
