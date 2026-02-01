#!/bin/bash
#############################################
# GX10 Auto Installation Script - Phase 4
# Code Brain Installation (Ollama)
#############################################

set -e
set -u

LOG_FILE="/gx10/runtime/logs/04-code-brain-install.log"
mkdir -p /gx10/runtime/logs

echo "=========================================="
echo "GX10 Phase 4: Code Brain Install"
echo "=========================================="
echo "Log: $LOG_FILE"
echo ""

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Installing Ollama..."

# Install Ollama
log "Downloading and installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh >> "$LOG_FILE" 2>&1

# Verify installation
log "Verifying Ollama installation..."
OLLAMA_VERSION=$(ollama --version)
echo "Ollama version: $OLLAMA_VERSION" | tee -a "$LOG_FILE"

# Configure systemd service
log "Configuring Ollama systemd service..."
sudo mkdir -p /etc/systemd/system/ollama.service.d

sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null << 'EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_MODELS=/gx10/brains/code/models"
Environment="OLLAMA_KEEP_ALIVE=24h"
Environment="OLLAMA_NUM_PARALLEL=2"
Environment="OLLAMA_MAX_LOADED_MODELS=2"
EOF

# Reload and restart service
log "Reloading systemd and restarting Ollama..."
sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1
sudo systemctl restart ollama >> "$LOG_FILE" 2>&1
sudo systemctl enable ollama >> "$LOG_FILE" 2>&1

# Wait for service to start
log "Waiting for Ollama service to start..."
sleep 5

# Verification
log "Verifying Ollama service..."
echo "" | tee -a "$LOG_FILE"
echo "=== Ollama Service Status ===" | tee -a "$LOG_FILE"
sudo systemctl status ollama --no-pager | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "=== Ollama API Test ===" | tee -a "$LOG_FILE"
curl -s http://localhost:11434/api/version | jq . | tee -a "$LOG_FILE"

log "Phase 4 completed successfully!"
echo "=========================================="
echo "Phase 4: COMPLETED"
echo "=========================================="
