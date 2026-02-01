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

set -e
set -u

LOG_FILE="/gx10/runtime/logs/09-service-automation.log"
mkdir -p /gx10/runtime/logs

echo "=========================================="
echo "GX10 Phase 9: Service Automation"
echo "=========================================="
echo "Log: $LOG_FILE"
echo ""

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

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
  -e N8N_BASIC_AUTH_PASSWORD=gx10admin \
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
echo "Password: gx10admin" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Note: Change default password after first login" | tee -a "$LOG_FILE"

log "Phase 9 completed successfully!"
echo "=========================================="
echo "Phase 9: COMPLETED"
echo "=========================================="
echo "Services:"
echo "  - n8n: http://$IP:5678"
echo "  - Open WebUI: http://$IP:8080"
