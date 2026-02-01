#!/bin/bash
#############################################
# GX10 Auto Installation Script - Phase 8
# Open WebUI Installation
#############################################

set -e
set -u

LOG_FILE="/gx10/runtime/logs/08-webui-install.log"
mkdir -p /gx10/runtime/logs

echo "=========================================="
echo "GX10 Phase 8: Open WebUI Install"
echo "=========================================="
echo "Log: $LOG_FILE"
echo ""

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Installing Open WebUI..."

# Create data directory
log "Creating data directory..."
mkdir -p /gx10/brains/code/webui

# Pull and run Open WebUI container
log "Pulling Open WebUI image..."
docker pull ghcr.io/open-webui/open-webui:main >> "$LOG_FILE" 2>&1

log "Starting Open WebUI container..."
docker run -d \
  --name open-webui \
  --restart unless-stopped \
  -p 8080:8080 \
  -v /gx10/brains/code/webui:/app/backend/data \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-webui/open-webui:main >> "$LOG_FILE" 2>&1

# Wait for container to start
log "Waiting for Open WebUI to start..."
sleep 10

# Verification
log "Verifying Open WebUI..."
echo "" | tee -a "$LOG_FILE"
echo "=== Open WebUI Container ===" | tee -a "$LOG_FILE"
docker ps | grep open-webui | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "=== Access Information ===" | tee -a "$LOG_FILE"
IP=$(hostname -I | awk '{print $1}')
echo "Open WebUI: http://$IP:8080" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Note: First access will require admin account creation" | tee -a "$LOG_FILE"

log "Phase 8 completed successfully!"
echo "=========================================="
echo "Phase 8: COMPLETED"
echo "=========================================="
echo "Open WebUI is available at: http://$IP:8080"
