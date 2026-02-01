#!/bin/bash
#############################################
# GX10 Auto Installation Script - Phase 8
# Open WebUI Installation
#
# Reference: PRD.md Section "Functional Requirements > 7. Open WebUI"
# - Port: 8080
# - Integration with Ollama
# - Code Brain interaction interface
#
# Author: omc-developer
# Created: 2026-02-01
# Modified: 2026-02-01
#
# Reviewed-By: alfrad (2026-02-01)
#############################################

# alfrad review:
# ✅ Open WebUI 설치로 사용자 인터페이스 제공
# ✅ Port 8080 설정으로 표준 포트 사용 적절
# ✅ Ollama 연동으로 Code Brain 상호작용 가능
# 💡 제안: HTTPS 설정 및 인증 메커니즘 추가로 보안 강화 권장
# ⚠️ 확인: 외부 접속 시 방화벽 규칙 검토 필요

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
