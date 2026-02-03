#!/bin/bash
#############################################
# GX10 Auto Installation Script - Phase 4
# Open WebUI Installation
#
# Reference: PRD.md Section "Functional Requirements > 7. Open WebUI"
# - Port: 8080
# - Integration with Ollama
# - Code Brain interaction interface
#
# Author: omc-developer
# Created: 2026-02-01
# Modified: 2026-02-03
#
# Reviewed-By: alfrad (2026-02-01)
#############################################

# alfrad review:
# ✅ Open WebUI 설치로 사용자 인터페이스 제공
# ✅ Port 8080 설정으로 표준 포트 사용 적절
# ✅ Ollama 연동으로 Code Brain 상호작용 가능
# ⚠️ 확인: 외부 접속 시 방화벽 규칙 검토 필요

# MoAI review (v2.1.0 - KB-011):
# ❌ HTTPS 지원 제거: Open WebUI 컨테이너가 내부 8443 HTTPS를 지원하지 않음
# ✅ HTTP(8080) 단일 모드로 단순화 - 안정성 확보
# 💡 참고: HTTPS 필요 시 nginx reverse proxy 아키텍처 권장

#
# Document-ID: DOC-SCR-004
# Document-Name: GX10 Auto-Installation Script - Phase 04
# Reference: GX10-03-Final-Implementation-Guide.md Section "Phase 4: WebUI Install"
# Reference: GX10-09-Two-Brain-Optimization.md Section "User Interface Integration"
# Related: KB-011 (Open WebUI HTTPS 내부 미지원)
#
# Version: 2.1.0
# Status: RELEASED
# Dependencies: DOC-SCR-000 (Phase 0)
#

set -e
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/state-manager.sh"
source "$SCRIPT_DIR/lib/error-handler.sh"

LOG_FILE="/gx10/runtime/logs/04-webui-install.log"
mkdir -p /gx10/runtime/logs

# Initialize state management
init_state
init_checkpoint_system

# Initialize phase log
PHASE="04"
init_log "$PHASE" "$(basename "$0" .sh)"

echo "=========================================="
echo "GX10 Phase 4: Open WebUI Install"
echo "=========================================="
echo "Log: $LOG_FILE"
echo ""

# Create checkpoint
CHECKPOINT_ID=$(checkpoint "phase-$PHASE" "Before starting phase $PHASE")
trap "rollback $CHECKPOINT_ID; exit 1" ERR

log "Installing Open WebUI..."

# Create data directory
log "Creating data directory..."
mkdir -p /gx10/brains/code/webui

# Pull Open WebUI image
log "Pulling Open WebUI image..."
docker pull ghcr.io/open-webui/open-webui:main >> "$LOG_FILE" 2>&1

# Start Open WebUI container (HTTP mode - 8080)
# Note: Open WebUI does not support internal HTTPS (KB-011)
log "Starting Open WebUI container (HTTP mode)..."
docker run -d \
  --name open-webui \
  --restart unless-stopped \
  -p 8080:8080 \
  -v /gx10/brains/code/webui:/app/backend/data \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-webui/open-webui:main >> "$LOG_FILE" 2>&1

WEBUI_PORT=8080
WEBUI_PROTOCOL="http"

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
echo "Open WebUI: $WEBUI_PROTOCOL://$IP:$WEBUI_PORT" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Note: First access will require admin account creation" | tee -a "$LOG_FILE"

# Mark checkpoint as completed
complete_checkpoint "$CHECKPOINT_ID"

log "Phase 4 completed successfully!"
echo "=========================================="
echo "Phase 4: COMPLETED"
echo "=========================================="
echo "Open WebUI is available at: $WEBUI_PROTOCOL://$IP:$WEBUI_PORT"
