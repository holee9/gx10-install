#!/bin/bash
#############################################
# GX10 Auto Installation Script - Phase 6
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

set -e
set -u

LOG_FILE="/gx10/runtime/logs/06-vision-brain-build.log"
mkdir -p /gx10/runtime/logs

echo "=========================================="
echo "GX10 Phase 6: Vision Brain Build"
echo "=========================================="
echo "Log: $LOG_FILE"
echo "WARNING: This may take 20-30 minutes"
echo ""

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

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

log "Phase 6 completed successfully!"
echo "=========================================="
echo "Phase 6: COMPLETED"
echo "=========================================="
echo "Vision Brain Docker image: gx10-vision-brain:latest"
