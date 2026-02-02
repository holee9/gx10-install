#!/bin/bash
#############################################
# GX10 Auto Installation Script - Phase 1
# Initial Setup and System Update
#
# Reference: PRD.md Section "Implementation Phases > Phase 1"
# - DGX OS prerequisites
# - System packages installation
#
# Author: omc-developer
# Created: 2026-02-01
# Modified: 2026-02-01
#
# Reviewed-By: alfrad (2026-02-01)
#############################################

# alfrad review:
# ✅ DGX OS 사전 요구사항 준수로 환경 적합성 확보
# ✅ 시스템 패키지 설치로 기반 환경 구축
# ✅ 에러 처리(set -e, set -u) 적절
# 💡 참고: DGX OS 7.2.3 특화 패키지 목록 주기적 업데이트 필요

# alfrad review (v2.0.0 updates):
# ✅ 라이브러리 시스템 도입 (lib/logger.sh, state-manager.sh, error-handler.sh, security.sh)
# ✅ 체크포인트 시스템으로 실패 시 롤백 가능
# ✅ init_log로 Phase 로그 초기화
# ✅ 문서 메타데이터 추가 (DOC-SCR-001, Version 2.0.0)
# ⚠️ 확인: lib/* 파일들이 scripts/install/lib/ 폴더에 존재해야 함

#
# Document-ID: DOC-SCR-001
# Document-Name: GX10 Auto-Installation Script - Phase 01
# Reference: GX10-03-Final-Implementation-Guide.md Section "Phase 1: Initial Setup"
# Reference: GX10-09-Two-Brain-Optimization.md Section "Environment Preparation"
#
# Version: 2.0.0
# Status: RELEASED
# Dependencies: None
#

set -e  # Exit on error
set -u  # Exit on undefined variable

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/state-manager.sh"
source "$SCRIPT_DIR/lib/error-handler.sh"
source "$SCRIPT_DIR/lib/security.sh"

LOG_FILE="/gx10/runtime/logs/01-initial-setup.log"
mkdir -p /gx10/runtime/logs

# Initialize state management
init_state
init_checkpoint_system

# Initialize phase log
PHASE="01"
init_log "$PHASE" "$(basename "$0" .sh)"

echo "=========================================="
echo "GX10 Phase 1: Initial Setup"
echo "=========================================="
echo "Log: $LOG_FILE"
echo ""

# Create checkpoint
CHECKPOINT_ID=$(checkpoint "phase-$PHASE" "Before starting phase $PHASE")
trap "rollback $CHECKPOINT_ID; exit 1" ERR

log "Starting system update..."

# System update
log "Updating system packages..."
sudo apt update >> "$LOG_FILE" 2>&1
sudo apt upgrade -y >> "$LOG_FILE" 2>&1

# Install essential packages
log "Installing essential packages..."
sudo apt install -y \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    htop \
    btop \
    tmux \
    vim \
    neovim \
    tree \
    jq \
    unzip \
    net-tools \
    openssh-server \
    python3-pip \
    python3-venv >> "$LOG_FILE" 2>&1

# SSH configuration
log "Configuring SSH..."
sudo systemctl enable ssh >> "$LOG_FILE" 2>&1
sudo systemctl start ssh >> "$LOG_FILE" 2>&1

# Firewall configuration
log "Configuring firewall..."
sudo ufw allow ssh >> "$LOG_FILE" 2>&1
sudo ufw allow 11434/tcp >> "$LOG_FILE" 2>&1  # Ollama
sudo ufw allow 8080/tcp >> "$LOG_FILE" 2>&1   # Open WebUI
sudo ufw allow 5678/tcp >> "$LOG_FILE" 2>&1   # n8n
sudo ufw --force enable >> "$LOG_FILE" 2>&1

# Verification
log "Verifying installation..."
echo "" | tee -a "$LOG_FILE"
echo "=== Verification ===" | tee -a "$LOG_FILE"
echo "SSH Status:" | tee -a "$LOG_FILE"
sudo systemctl status ssh --no-pager | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "UFW Status:" | tee -a "$LOG_FILE"
sudo ufw status | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Disk Usage:" | tee -a "$LOG_FILE"
df -h | tee -a "$LOG_FILE"

# Mark checkpoint as completed
complete_checkpoint "$CHECKPOINT_ID"

log "Phase 1 completed successfully!"
echo "=========================================="
echo "Phase 1: COMPLETED"
echo "=========================================="
