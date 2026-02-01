#!/bin/bash
#############################################
# GX10 Auto Installation Script - Phase 3
# Environment Configuration
#############################################

set -e
set -u

LOG_FILE="/gx10/runtime/logs/03-environment-config.log"
mkdir -p /gx10/runtime/logs

echo "=========================================="
echo "GX10 Phase 3: Environment Config"
echo "=========================================="
echo "Log: $LOG_FILE"
echo ""

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Configuring environment variables..."

# Add environment variables to .bashrc
log "Adding GX10 environment variables to .bashrc..."
cat >> ~/.bashrc << 'EOF'

# === GX10 AI System Configuration ===
export GX10_HOME="/gx10"
export OLLAMA_MODELS="/gx10/brains/code/models"
export HF_HOME="/gx10/brains/vision/models/huggingface"
export TORCH_HOME="/gx10/brains/vision/models/torch"

# === Memory Optimization (GX10-08, GX10-09 P0) ===
# Code Brain: 50-60GB (Option A: Aggressive Expansion)
export GX10_CODE_BRAIN_MEMORY=60  # GB (recommended)
# Vision Brain: 70-90GB
export GX10_VISION_BRAIN_MEMORY=90  # GB

# === Ollama Configuration (Code Brain) ===
# KV Cache: 16K context (4x expansion, +40% quality)
export OLLAMA_NUM_CTX=16384
# GPU: Single GPU usage (avoid fragmentation)
export OLLAMA_NUM_GPU=1
# Max Loaded Models: 3 (32B main, 7B sub, 16B math)
export OLLAMA_MAX_LOADED_MODELS=3
# Memory Limit: 60GB for Code Brain
export OLLAMA_MAX_VRAM=60000  # MB
# Flash Attention: Enabled (faster inference)
export OLLAMA_FLASH_ATTENTION=1

# CUDA (DGX OS pre-configured)
export PATH="/usr/local/cuda/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"

# Aliases
alias gx="cd /gx10"
alias brain-status="/gx10/api/status.sh"
alias brain-switch="/gx10/api/switch.sh"
alias code-brain="sudo systemctl start ollama"
alias vision-brain="sudo docker start gx10-vision-brain"
alias stop-brains="sudo systemctl stop ollama && sudo docker stop gx10-vision-brain"
EOF

# Source .bashrc
log "Sourcing .bashrc..."
source ~/.bashrc

# Add user to docker group
log "Adding user to docker group..."
sudo usermod -aG docker $USER >> "$LOG_FILE" 2>&1

# Create Ollama service configuration
log "Configuring Ollama service..."
sudo mkdir -p /etc/systemd/system/ollama.service.d
cat << 'EOF' | sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null
[Service]
# Memory limit for Code Brain: 60GB
MemoryLimit=60G
# Environment variables
Environment="OLLAMA_NUM_CTX=16384"
Environment="OLLAMA_NUM_GPU=1"
Environment="OLLAMA_MAX_LOADED_MODELS=3"
Environment="OLLAMA_MAX_VRAM=60000"
Environment="OLLAMA_FLASH_ATTENTION=1"
EOF

# Reload systemd
log "Reloading systemd daemon..."
sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1

# Verification
log "Verifying environment..."
echo "" | tee -a "$LOG_FILE"
echo "=== Environment Variables ===" | tee -a "$LOG_FILE"
echo "GX10_HOME: $GX10_HOME" | tee -a "$LOG_FILE"
echo "OLLAMA_MODELS: $OLLAMA_MODELS" | tee -a "$LOG_FILE"
echo "HF_HOME: $HF_HOME" | tee -a "$LOG_FILE"
echo "GX10_CODE_BRAIN_MEMORY: ${GX10_CODE_BRAIN_MEMORY}GB" | tee -a "$LOG_FILE"
echo "GX10_VISION_BRAIN_MEMORY: ${GX10_VISION_BRAIN_MEMORY}GB" | tee -a "$LOG_FILE"
echo "OLLAMA_NUM_CTX: ${OLLAMA_NUM_CTX:-16384}" | tee -a "$LOG_FILE"
echo "OLLAMA_MAX_LOADED_MODELS: ${OLLAMA_MAX_LOADED_MODELS:-3}" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "=== Docker Group ===" | tee -a "$LOG_FILE"
groups | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "=== Ollama Service Configuration ===" | tee -a "$LOG_FILE"
sudo systemctl cat ollama.service | grep -A5 "\[Service\]" | tee -a "$LOG_FILE" || echo "Ollama service not yet installed (Phase 4)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Note: You may need to log out and log back in for docker group to take effect" | tee -a "$LOG_FILE"

log "Phase 3 completed successfully!"
echo "=========================================="
echo "Phase 3: COMPLETED"
echo "=========================================="
echo "IMPORTANT: Run 'newgrp docker' or log out/in for docker group changes"
echo ""
echo "Memory Configuration Applied:"
echo "  - Code Brain: ${GX10_CODE_BRAIN_MEMORY}GB (Option A: 50-60GB)"
echo "  - Vision Brain: ${GX10_VISION_BRAIN_MEMORY}GB"
echo "  - KV Cache: 16K tokens (4x expansion)"
echo "  - Max Models: 3 (32B, 7B, 16B)"
echo ""
echo "Reference: GX10-08-CodeBrain-Memory-Optimization.md"
echo "Reference: GX10-09-Two-Brain-Optimization.md"
