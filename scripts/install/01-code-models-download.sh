#!/bin/bash
#############################################
# GX10 Auto Installation Script - Phase 1
# Code Models Download
#
# Reference: PRD.md Section "Functional Requirements > 1. Code Brain"
# - KV Cache: 16K context window (line 169)
# - Memory optimization: 50-60GB total allocation
#
# Author: omc-developer
# Created: 2026-02-01
# Modified: 2026-02-01
#
# Reviewed-By: alfrad (2026-02-01)
#############################################

# alfrad review:
# ✅ PRD.md 참조 추가로 요구사항 추적 가능성 확보
# ✅ Author 정보와 작성일 명시로 책임 소명 명확화
# ✅ KV Cache 16K 설정으로 PRD 요구사항 준수 (line 169)
# ✅ 환경변수 OLLAMA_NUM_CTX=16384 설정 적절
# ⚠️ 확인: 7B, 16B 모델에도 동일한 KV Cache 적용 필요 여부 검토 필요
# 💡 제안: 향후 KV Cache 값을 환경별로 설정 가능하도록 파라미터화 권장

#
# Document-ID: DOC-SCR-001
# Document-Name: GX10 Auto-Installation Script - Phase 01
# Reference: GX10-03-Final-Implementation-Guide.md Section "Phase 1: Code Models Download"
# Reference: GX10-09-Two-Brain-Optimization.md Section "KV Cache Optimization"
#
# Version: 2.0.0
# Status: RELEASED
# Dependencies: DOC-SCR-000 (Phase 0)
#

set -e
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/state-manager.sh"
source "$SCRIPT_DIR/lib/error-handler.sh"
source "$SCRIPT_DIR/lib/security.sh"

# Initialize configuration
init_config

LOG_FILE="$GX10_LOGS_DIR/01-code-models-download.log"
mkdir -p "$GX10_LOGS_DIR"

# Initialize state management
init_state
init_checkpoint_system

# Initialize phase log
PHASE="01"
init_log "$PHASE" "$(basename "$0" .sh)"

echo "=========================================="
echo "GX10 Phase 1: Code Models Download"
echo "=========================================="
echo "Log: $LOG_FILE"
echo "WARNING: This may take 40-60 minutes"
echo ""

# Create checkpoint
CHECKPOINT_ID=$(checkpoint "phase-$PHASE" "Before starting phase $PHASE")
trap "rollback $CHECKPOINT_ID; exit 1" ERR

log "Starting code models download..."

# Configure KV Cache size for 16K context window (PRD requirement)
# Reference: README.md - Current model stack (kqwen-coder:latest, qwen3:30b, devstral-small-2, gemma4:26b)
log "Configuring Ollama environment for ${OLLAMA_NUM_CTX} context window..."
export OLLAMA_NUM_CTX="$OLLAMA_NUM_CTX"
log "OLLAMA_NUM_CTX set to $OLLAMA_NUM_CTX"

# Main coding model (32B) - 30min, 20GB
log "Downloading $CODE_MODEL_PRIMARY with ${OLLAMA_NUM_CTX} KV Cache (this will take ~30 minutes)..."
echo "Progress: Model download is running in background. Check log for details."
time ollama pull "$CODE_MODEL_PRIMARY" >> "$LOG_FILE" 2>&1
log "$CODE_MODEL_PRIMARY downloaded successfully!"

# Fast response model (7B) - 10min, 5GB
log "Downloading $CODE_MODEL_SECONDARY (this will take ~10 minutes)..."
time ollama pull "$CODE_MODEL_SECONDARY" >> "$LOG_FILE" 2>&1
log "$CODE_MODEL_SECONDARY downloaded successfully!"

# DeepSeek alternative (16B) - 15min, 10GB
log "Downloading $CODE_MODEL_ALTERNATIVE (this will take ~15 minutes)..."
time ollama pull "$CODE_MODEL_ALTERNATIVE" >> "$LOG_FILE" 2>&1
log "$CODE_MODEL_ALTERNATIVE downloaded successfully!"

# Embedding model
log "Downloading $EMBEDDING_MODEL model..."
time ollama pull "$EMBEDDING_MODEL" >> "$LOG_FILE" 2>&1
log "$EMBEDDING_MODEL downloaded successfully!"

# Verification
log "Verifying installed models..."
echo "" | tee -a "$LOG_FILE"
echo "=== Installed Models ===" | tee -a "$LOG_FILE"
ollama list | tee -a "$LOG_FILE"

# Quick test
log "Running quick test with primary model..."
echo "" | tee -a "$LOG_FILE"
echo "=== Quick Test ($CODE_MODEL_PRIMARY) ===" | tee -a "$LOG_FILE"
echo "Testing: Write a Python hello world function..." | tee -a "$LOG_FILE"
time ollama run "$CODE_MODEL_PRIMARY" "def hello(): print('Hello GX10')" >> "$LOG_FILE" 2>&1

# Mark checkpoint as completed
complete_checkpoint "$CHECKPOINT_ID"

log "Phase 1 completed successfully!"
echo "=========================================="
echo "Phase 1: COMPLETED"
echo "=========================================="
echo "Models installed:"
echo "  - $CODE_MODEL_PRIMARY (Main)"
echo "  - $CODE_MODEL_SECONDARY (Fast)"
echo "  - $CODE_MODEL_ALTERNATIVE (Alternative)"
echo "  - $EMBEDDING_MODEL (Embedding)"
