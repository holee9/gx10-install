#!/bin/bash
#############################################
# GX10 Auto Installation Script - Phase 6
# Vision Brain Docker Build
#############################################

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
