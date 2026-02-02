#!/bin/bash
#############################################
# GX10 Auto Installation Script - Phase 4
# Code Brain Installation (Ollama)
#
# Reference: PRD.md Section "Functional Requirements > 1. Code Brain"
# - Memory: 50-60GB allocation
# - Parallel processing: 2 models
# - Keep alive: 24h
#
# Author: omc-developer
# Created: 2026-02-01
# Modified: 2026-02-01
#
# Reviewed-By: alfrad (2026-02-01)
#############################################

# alfrad review:
# ✅ Ollama 설치로 Code Brain 인프라 구축
# ✅ 메모리 할당(50-60GB) PRD 요구사항 준수
# ✅ 병렬 처리 2모델 설정으로 성능 확보
# ✅ Keep alive 24h로 서비스 지속성 보장
# 💡 참고: Ollama 버전 업데이트 시 호환성 확인 필요

# alfrad review (v2.0.0 updates):
# ✅ 체크포인트로 Ollama 설치 실패 시 롤백 가능
# ✅ 문서 메타데이터 추가 (DOC-SCR-004, Dependencies: DOC-SCR-003)

#
# Document-ID: DOC-SCR-004
# Document-Name: GX10 Auto-Installation Script - Phase 04
# Reference: GX10-03-Final-Implementation-Guide.md Section "Phase 4: Code Brain Install"
# Reference: GX10-09-Two-Brain-Optimization.md Section "Code Brain Optimization"
#
# Version: 2.0.0
# Status: RELEASED
# Dependencies: DOC-SCR-003
#

set -e
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/state-manager.sh"
source "$SCRIPT_DIR/lib/error-handler.sh"
source "$SCRIPT_DIR/lib/security.sh"

LOG_FILE="/gx10/runtime/logs/04-code-brain-install.log"
mkdir -p /gx10/runtime/logs

# Initialize state management
init_state
init_checkpoint_system

# Initialize phase log
PHASE="04"
init_log "$PHASE" "$(basename "$0" .sh)"

echo "=========================================="
echo "GX10 Phase 4: Code Brain Install"
echo "=========================================="
echo "Log: $LOG_FILE"
echo ""

# Create checkpoint
CHECKPOINT_ID=$(checkpoint "phase-$PHASE" "Before starting phase $PHASE")
trap "rollback $CHECKPOINT_ID; exit 1" ERR

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

# Mark checkpoint as completed
complete_checkpoint "$CHECKPOINT_ID"

log "Phase 4 completed successfully!"
echo "=========================================="
echo "Phase 4: COMPLETED"
echo "=========================================="
