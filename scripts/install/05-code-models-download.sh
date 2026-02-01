#!/bin/bash
#############################################
# GX10 Auto Installation Script - Phase 5
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

set -e
set -u

LOG_FILE="/gx10/runtime/logs/05-code-models-download.log"
mkdir -p /gx10/runtime/logs

echo "=========================================="
echo "GX10 Phase 5: Code Models Download"
echo "=========================================="
echo "Log: $LOG_FILE"
echo "WARNING: This may take 40-60 minutes"
echo ""

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting code models download..."

# Configure KV Cache size for 16K context window (PRD requirement)
# Reference: PRD.md line 169 - "qwen2.5-coder:32b: 24GB (16K KV Cache)"
log "Configuring Ollama environment for 16K KV Cache..."
export OLLAMA_NUM_CTX=16384
log "OLLAMA_NUM_CTX set to 16384 (16K context window)"

# Main coding model (32B) - 30min, 20GB
log "Downloading Qwen2.5-Coder 32B with 16K KV Cache (this will take ~30 minutes)..."
echo "Progress: Model download is running in background. Check log for details."
time ollama pull qwen2.5-coder:32b >> "$LOG_FILE" 2>&1
log "Qwen2.5-Coder 32B downloaded successfully!"

# Fast response model (7B) - 10min, 5GB
log "Downloading Qwen2.5-Coder 7B (this will take ~10 minutes)..."
time ollama pull qwen2.5-coder:7b >> "$LOG_FILE" 2>&1
log "Qwen2.5-Coder 7B downloaded successfully!"

# DeepSeek alternative (16B) - 15min, 10GB
log "Downloading DeepSeek-Coder V2 16B (this will take ~15 minutes)..."
time ollama pull deepseek-coder-v2:16b >> "$LOG_FILE" 2>&1
log "DeepSeek-Coder V2 16B downloaded successfully!"

# Embedding model
log "Downloading Nomic Embed Text model..."
time ollama pull nomic-embed-text >> "$LOG_FILE" 2>&1
log "Nomic Embed Text downloaded successfully!"

# Verification
log "Verifying installed models..."
echo "" | tee -a "$LOG_FILE"
echo "=== Installed Models ===" | tee -a "$LOG_FILE"
ollama list | tee -a "$LOG_FILE"

# Quick test
log "Running quick test with 32B model..."
echo "" | tee -a "$LOG_FILE"
echo "=== Quick Test (32B Model) ===" | tee -a "$LOG_FILE"
echo "Testing: Write a Python hello world function..." | tee -a "$LOG_FILE"
time ollama run qwen2.5-coder:32b "def hello(): print('Hello GX10')" >> "$LOG_FILE" 2>&1

log "Phase 5 completed successfully!"
echo "=========================================="
echo "Phase 5: COMPLETED"
echo "=========================================="
echo "Models installed:"
echo "  - qwen2.5-coder:32b (Main)"
echo "  - qwen2.5-coder:7b (Fast)"
echo "  - deepseek-coder-v2:16b (Alternative)"
echo "  - nomic-embed-text (Embedding)"
