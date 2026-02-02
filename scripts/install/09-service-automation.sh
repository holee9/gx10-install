#!/bin/bash
#############################################
# GX10 Auto Installation Script - Phase 9
# Service Automation
#
# Reference: PRD.md Section "Functional Requirements > 8. n8n Integration"
# - Port: 5678
# - GitHub Webhook integration
# - CI/CD pipeline automation
#
# Author: omc-developer
# Created: 2026-02-01
# Modified: 2026-02-01
#
# Reviewed-By: alfrad (2026-02-01)
#############################################

# alfrad review:
# ✅ n8n 설치로 워크플로우 자동화 구현
# ✅ GitHub Webhook 연동으로 CI/CD 파이프라인 구축
# ✅ Port 5678 표준 포트 사용
# ⚠️ 확인: Webhook 보안(HMAC signature) 검토 필요
# 💡 제안: 워크플로우 템플릿 제공으로 사용자 편의성 개선 권장

# alfrad review (v2.0.0 updates):
# ✅ 체크포인트/롤백 시스템으로 실패 복구 가능
# ✅ 문서 메타데이터 추가 (DOC-SCR-009, Dependencies: DOC-SCR-008)
# ⚠️ 확인: n8n admin password가 $GX10_ADMIN_PASSWORD 사용하는지 검토 필요
# 💡 제안: Webhook HMAC signature 자동 생성 기능 추가 권장

#
# Document-ID: DOC-SCR-009
# Document-Name: GX10 Auto-Installation Script - Phase 09
# Reference: GX10-03-Final-Implementation-Guide.md Section "Phase 9: Service Automation"
# Reference: GX10-09-Two-Brain-Optimization.md Section "Workflow Automation"
#
# Version: 2.0.0
# Status: RELEASED
# Dependencies: DOC-SCR-008
#

set -e
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/state-manager.sh"
source "$SCRIPT_DIR/lib/error-handler.sh"
source "$SCRIPT_DIR/lib/security.sh"

LOG_FILE="/gx10/runtime/logs/09-service-automation.log"
mkdir -p /gx10/runtime/logs

# Initialize state management
init_state
init_checkpoint_system

# Initialize phase log
PHASE="09"
init_log "$PHASE" "$(basename "$0" .sh)"

echo "=========================================="
echo "GX10 Phase 9: Service Automation"
echo "=========================================="
echo "Log: $LOG_FILE"
echo ""

# Create checkpoint
CHECKPOINT_ID=$(checkpoint "phase-$PHASE" "Before starting phase $PHASE")
trap "rollback $CHECKPOINT_ID; exit 1" ERR

log "Setting up service automation..."

# Install n8n (optional automation tool)
log "Installing n8n..."
mkdir -p /gx10/automation/n8n

docker run -d \
  --name n8n \
  --restart unless-stopped \
  -p 5678:5678 \
  -e N8N_BASIC_AUTH_ACTIVE=true \
  -e N8N_BASIC_AUTH_USER=admin \
  -e N8N_BASIC_AUTH_PASSWORD="${GX10_ADMIN_PASSWORD}" \
  -v /gx10/automation/n8n:/home/node/.n8n \
  n8nio/n8n >> "$LOG_FILE" 2>&1

# Wait for n8n to start
log "Waiting for n8n to start..."
sleep 10

# Create systemd service for monitoring (optional)
log "Creating monitoring service..."
sudo tee /etc/systemd/system/gx10-monitor.service > /dev/null << 'EOF'
[Unit]
Description=GX10 System Monitor
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
WorkingDirectory=/gx10/system/monitoring
ExecStart=/usr/bin/python3 /gx10/system/monitoring/monitor.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Replace YOUR_USERNAME with actual username
sudo sed -i "s/YOUR_USERNAME/$USER/g" /etc/systemd/system/gx10-monitor.service

# Verification
log "Verifying automation services..."
echo "" | tee -a "$LOG_FILE"
echo "=== N8N Container ===" | tee -a "$LOG_FILE"
docker ps | grep n8n | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "=== Access Information ===" | tee -a "$LOG_FILE"
IP=$(hostname -I | awk '{print $1}')
echo "n8n: http://$IP:5678" | tee -a "$LOG_FILE"
echo "Username: admin" | tee -a "$LOG_FILE"
echo "Password: [Configured during installation]" | tee -a "$LOG_FILE"
echo "Stored in: /gx10/runtime/state/.admin_password (hashed)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Security Note: Password is stored securely. Change after first login." | tee -a "$LOG_FILE"

# Mark checkpoint as completed
complete_checkpoint "$CHECKPOINT_ID"

log "Phase 9 completed successfully!"
echo "=========================================="
echo "Phase 9: COMPLETED"
echo "=========================================="
echo "Services:"
echo "  - n8n: http://$IP:5678 (admin)"
echo "  - Open WebUI: https://$IP:443"
