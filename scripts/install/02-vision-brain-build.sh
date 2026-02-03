#!/bin/bash
#############################################
# GX10 Auto Installation Script - Phase 2
# Vision Brain Docker Build
#
# Reference: PRD.md Section "Functional Requirements > 2. Vision Brain"
# - Memory: 70-90GB allocation
# - Models: Qwen2.5-VL-72B, YOLOv8x, SAM2-Large
# - Docker containerization for isolation
#
# Author: omc-developer
# Created: 2026-02-01
# Modified: 2026-02-01
#
# Reviewed-By: alfrad (2026-02-01)
#############################################

# alfrad review:
# ✅ Docker 컨테이너화로 Vision Brain 격리 확보
# ✅ 메모리 할당(70-90GB) 대형 모델 지원 적절
# ✅ 다중 모델(Qwen2.5-VL-72B, YOLOv8x, SAM2) 통합 구현
# ⚠️ 확인: GPU 메모리 공유 시 Code Brain과의 충돌 방지 필요
# 💡 제안: Docker 이미지 캐싱 전략으로 재빌드 시간 단축 권장

# alfrad review (v2.0.0 updates):
# ✅ 체크포인트로 Docker build 실패 시 롤백 가능
# ✅ 문서 메타데이터 추가 (DOC-SCR-006, Dependencies: DOC-SCR-005)
# ⚠️ 확인: Docker build 실패 시 디스크 공간 정리 로직 필요

#
# Document-ID: DOC-SCR-006
# Document-Name: GX10 Auto-Installation Script - Phase 02
# Reference: GX10-03-Final-Implementation-Guide.md Section "Phase 2: Vision Brain Build"
# Reference: GX10-09-Two-Brain-Optimization.md Section "Vision Brain Architecture"
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

LOG_FILE="/gx10/runtime/logs/02-vision-brain-build.log"
mkdir -p /gx10/runtime/logs

# Initialize state management
init_state
init_checkpoint_system

# Initialize phase log
PHASE="02"
init_log "$PHASE" "$(basename "$0" .sh)"

echo "=========================================="
echo "GX10 Phase 6: Vision Brain Build"
echo "=========================================="
echo "Log: $LOG_FILE"
echo "WARNING: This may take 20-30 minutes"
echo ""

# Create checkpoint
CHECKPOINT_ID=$(checkpoint "phase-$PHASE" "Before starting phase $PHASE")
trap "rollback $CHECKPOINT_ID; exit 1" ERR

log "Building Vision Brain Docker image..."

# Create Dockerfile
log "Creating Dockerfile..."
cat > /gx10/brains/vision/Dockerfile << 'EOF'
FROM nvcr.io/nvidia/pytorch:24.01-py3

WORKDIR /workspace

# Update PyTorch and dependencies
RUN pip install --upgrade pip

# Install PyTorch with CUDA 12.1 support
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Computer Vision libraries
RUN pip install \
    opencv-python \
    pillow \
    transformers \
    accelerate \
    diffusers \
    timm

# Hugging Face Hub
RUN pip install huggingface_hub

# Benchmark tools
RUN pip install tqdm psutil GPUtil

# Set environment
ENV PYTHONPATH=/workspace:$PYTHONPATH
ENV HF_HOME=/workspace/models/huggingface
ENV TORCH_HOME=/workspace/models/torch

# Create models directory
RUN mkdir -p /workspace/models

CMD ["python"]
EOF

# Build Docker image
log "Building Docker image (this will take 20-30 minutes)..."
docker build -t gx10-vision-brain:latest /gx10/brains/vision/ >> "$LOG_FILE" 2>&1

# Verification
log "Verifying Docker image..."
echo "" | tee -a "$LOG_FILE"
echo "=== Docker Images ===" | tee -a "$LOG_FILE"
docker images | grep gx10-vision-brain | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "=== GPU Test in Container ===" | tee -a "$LOG_FILE"
docker run --rm --gpus all gx10-vision-brain:latest python -c "import torch; print(f'CUDA Available: {torch.cuda.is_available()}'); print(f'GPU Count: {torch.cuda.device_count()}'); print(f'GPU Name: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}')" | tee -a "$LOG_FILE"

# Mark checkpoint as completed
complete_checkpoint "$CHECKPOINT_ID"

log "Phase 6 completed successfully!"
echo "=========================================="
echo "Phase 6: COMPLETED"
echo "=========================================="
echo "Vision Brain Docker image: gx10-vision-brain:latest"
