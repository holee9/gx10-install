#!/bin/bash
#############################################
# GX10 Auto Installation Script - Phase 2
# Directory Structure Creation
#############################################

set -e
set -u

LOG_FILE="/gx10/runtime/logs/02-directory-structure.log"
mkdir -p /gx10/runtime/logs

echo "=========================================="
echo "GX10 Phase 2: Directory Structure"
echo "=========================================="
echo "Log: $LOG_FILE"
echo ""

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

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

log "Phase 2 completed successfully!"
echo "=========================================="
echo "Phase 2: COMPLETED"
echo "=========================================="
