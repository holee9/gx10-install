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

# alfrad review (v2.0.0 updates):
# ✅ 보안 강화 완료: HTTPS 지원 (443 포트), SSL 인증서 자동 생성
# ✅ WEBUI_SECRET_KEY로 세션 관리 보안 개선
# ✅ 체크포인트 시스템으로 실패 시 롤백 가능
# ✅ HTTP fallback 메커니즘으로 인증서 실패 시에도 계속 진행
# ⚠️ 확인: generate_cert 함수가 lib/security.sh에 구현되어야 함
# ⚠️ 확인: Open WebUI 컨테이너가 8443 포트 내부 listening 지원해야 함
# 💡 제안: SSL 인증서 만료 기간 설정 가능하게 권장 (default 365일)
# 💡 참고: 자체 서명 인증서는 브라우저 경고 표시됨 - 사용자 안내 필요

#
# Document-ID: DOC-SCR-008
# Document-Name: GX10 Auto-Installation Script - Phase 04
# Reference: GX10-03-Final-Implementation-Guide.md Section "Phase 4: WebUI Install"
# Reference: GX10-09-Two-Brain-Optimization.md Section "User Interface Integration"
#
# Version: 2.0.0
# Status: RELEASED
# Dependencies: DOC-SCR-004
#

set -e
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/state-manager.sh"
source "$SCRIPT_DIR/lib/error-handler.sh"
source "$SCRIPT_DIR/lib/security.sh"

LOG_FILE="/gx10/runtime/logs/04-webui-install.log"
mkdir -p /gx10/runtime/logs

# Initialize state management
init_state
init_checkpoint_system

# Initialize phase log
PHASE="04"
init_log "$PHASE" "$(basename "$0" .sh)"

echo "=========================================="
echo "GX10 Phase 8: Open WebUI Install"
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

# Certificate directory for HTTPS
CERT_DIR="/gx10/runtime/certs"
mkdir -p "$CERT_DIR"

# Get server IP for certificate
SERVER_IP=$(hostname -I | awk '{print $1}')
SERVER_NAME="${SERVER_IP:-localhost}"

# Generate SSL certificate for HTTPS
log "Generating SSL certificate for $SERVER_NAME..."
ENABLE_HTTPS=true

if ! generate_cert "$SERVER_NAME" "$CERT_DIR" >> "$LOG_FILE" 2>&1; then
    log "WARN: Certificate generation failed, falling back to HTTP"
    ENABLE_HTTPS=false
fi

if [ "$ENABLE_HTTPS" = true ]; then
    log "SSL certificate generated successfully"
else
    log "Continuing with HTTP-only configuration"
fi

# Pull and run Open WebUI container
log "Pulling Open WebUI image..."
docker pull ghcr.io/open-webui/open-webui:main >> "$LOG_FILE" 2>&1

# Generate secret key for session management
WEBUI_SECRET="${WEBUI_SECRET:-$(openssl rand -hex 32 2>/dev/null || echo 'default-secret-change-me')}"

log "Starting Open WebUI container..."
if [ "$ENABLE_HTTPS" = true ] && [ -f "$CERT_DIR/cert.pem" ] && [ -f "$CERT_DIR/key.pem" ]; then
    log "Starting with HTTPS enabled..."
    docker run -d \
      --name open-webui \
      --restart unless-stopped \
      -p 443:8443 \
      -v /gx10/brains/code/webui:/app/backend/data \
      -v "$CERT_DIR/cert.pem:/app/certs/cert.pem:ro" \
      -v "$CERT_DIR/key.pem:/app/certs/key.pem:ro" \
      -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
      -e WEBUI_SECRET_KEY="$WEBUI_SECRET" \
      -e HTTPS_ENABLED=true \
      -e SSL_CERT_PATH=/app/certs/cert.pem \
      -e SSL_KEY_PATH=/app/certs/key.pem \
      --add-host=host.docker.internal:host-gateway \
      ghcr.io/open-webui/open-webui:main >> "$LOG_FILE" 2>&1

    WEBUI_PORT=443
    WEBUI_PROTOCOL="https"
else
    log "Starting with HTTP (fallback mode)..."
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
fi

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
if [ "$ENABLE_HTTPS" = true ]; then
    echo "Security: HTTPS enabled with SSL certificate" | tee -a "$LOG_FILE"
    echo "Certificate: $CERT_DIR/cert.pem" | tee -a "$LOG_FILE"
else
    echo "Security: HTTP mode (certificate generation failed)" | tee -a "$LOG_FILE"
fi
echo "" | tee -a "$LOG_FILE"
echo "Note: First access will require admin account creation" | tee -a "$LOG_FILE"

# Mark checkpoint as completed
complete_checkpoint "$CHECKPOINT_ID"

log "Phase 8 completed successfully!"
echo "=========================================="
echo "Phase 8: COMPLETED"
echo "=========================================="
echo "Open WebUI is available at: $WEBUI_PROTOCOL://$IP:$WEBUI_PORT"
if [ "$ENABLE_HTTPS" = true ]; then
    echo "Security: HTTPS enabled"
else
    echo "Security: HTTP (certificate generation failed)"
fi
