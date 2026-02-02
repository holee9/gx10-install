#!/bin/bash
#############################################
# GX10 Auto Installation Script - Phase 2
# Directory Structure Creation
#
# Reference: PRD.md Section "Technical Approach > 2. Two Brain 아키텍처"
# - Code Brain: /gx10/brains/code
# - Vision Brain: /gx10/brains/vision
# - API: /gx10/api
# - Runtime: /gx10/runtime
#
# Author: omc-developer
# Created: 2026-02-01
# Modified: 2026-02-01
#
# Reviewed-By: alfrad (2026-02-01)
#############################################

# alfrad review:
# ✅ Two Brain 아키텍처 디렉토리 구조 정확히 구현
# ✅ PRD.md 기술 접근법 참조로 설계 의도 명확
# ✅ 경로 표준화로 관리 용이성 확보
# 💡 제안: 디렉토리 생성 실패 시 상세 에러 로그 추가 권장

# alfrad review (v2.0.0 updates):
# ✅ 라이브러리 시스템 및 체크포인트 도입
# ✅ 문서 메타데이터 추가 (DOC-SCR-002, Dependencies: DOC-SCR-001)
# ✅ init_log로 Phase 로그 초기화

#
# Document-ID: DOC-SCR-002
# Document-Name: GX10 Auto-Installation Script - Phase 02
# Reference: GX10-03-Final-Implementation-Guide.md Section "Phase 2: Directory Structure"
# Reference: GX10-09-Two-Brain-Optimization.md Section "Two Brain Architecture"
#
# Version: 2.0.0
# Status: RELEASED
# Dependencies: DOC-SCR-001
#

set -e
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/state-manager.sh"
source "$SCRIPT_DIR/lib/error-handler.sh"
source "$SCRIPT_DIR/lib/security.sh"

LOG_FILE="/gx10/runtime/logs/02-directory-structure.log"
mkdir -p /gx10/runtime/logs

# Initialize state management
init_state
init_checkpoint_system

# Initialize phase log
PHASE="02"
init_log "$PHASE" "$(basename "$0" .sh)"

echo "=========================================="
echo "GX10 Phase 2: Directory Structure"
echo "=========================================="
echo "Log: $LOG_FILE"
echo ""

# Create checkpoint
CHECKPOINT_ID=$(checkpoint "phase-$PHASE" "Before starting phase $PHASE")
trap "rollback $CHECKPOINT_ID; exit 1" ERR

log "Creating GX10 directory structure..."

# Create base structure
log "Creating base directories..."
sudo mkdir -p /gx10/{brains,runtime,api,automation,system}

# Create Code Brain directories
log "Creating Code Brain directories..."
sudo mkdir -p /gx10/brains/code/{models,prompts,execution,logs}

# Create Vision Brain directories
log "Creating Vision Brain directories..."
sudo mkdir -p /gx10/brains/vision/{models,cuda,benchmarks,logs}

# Create runtime directories
log "Creating runtime directories..."
sudo mkdir -p /gx10/runtime/{locks,logs}

# Create API directory
log "Creating API directory..."
sudo mkdir -p /gx10/api

# Create automation directories
log "Creating automation directories..."
sudo mkdir -p /gx10/automation/{n8n,mcp}

# Create system directories
log "Creating system directories..."
sudo mkdir -p /gx10/system/{monitoring,update,backup}

# Set ownership
log "Setting ownership..."
sudo chown -R $USER:$USER /gx10

# Verification
log "Verifying directory structure..."
echo "" | tee -a "$LOG_FILE"
echo "=== Directory Tree ===" | tee -a "$LOG_FILE"
tree /gx10 -L 2 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "=== Permissions ===" | tee -a "$LOG_FILE"
ls -la /gx10 | tee -a "$LOG_FILE"

# Mark checkpoint as completed
complete_checkpoint "$CHECKPOINT_ID"

log "Phase 2 completed successfully!"
echo "=========================================="
echo "Phase 2: COMPLETED"
echo "=========================================="
