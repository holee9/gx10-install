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

# CUDA (DGX OS pre-configured)
export PATH="/usr/local/cuda/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"

# Aliases
alias gx="cd /gx10"
alias brain-status="/gx10/api/status.sh"
alias brain-switch="/gx10/api/switch.sh"
EOF

# Source .bashrc
log "Sourcing .bashrc..."
source ~/.bashrc

# Add user to docker group
log "Adding user to docker group..."
sudo usermod -aG docker $USER >> "$LOG_FILE" 2>&1

# Verification
log "Verifying environment..."
echo "" | tee -a "$LOG_FILE"
echo "=== Environment Variables ===" | tee -a "$LOG_FILE"
echo "GX10_HOME: $GX10_HOME" | tee -a "$LOG_FILE"
echo "OLLAMA_MODELS: $OLLAMA_MODELS" | tee -a "$LOG_FILE"
echo "HF_HOME: $HF_HOME" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "=== Docker Group ===" | tee -a "$LOG_FILE"
groups | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Note: You may need to log out and log back in for docker group to take effect" | tee -a "$LOG_FILE"

log "Phase 3 completed successfully!"
echo "=========================================="
echo "Phase 3: COMPLETED"
echo "=========================================="
echo "IMPORTANT: Run 'newgrp docker' or log out/in for docker group changes"
