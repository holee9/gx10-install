#!/bin/bash
#############################################
# GX10 Complete Installation Script
# Runs all phases sequentially
#
# IMPORTANT: This script assumes Phase 0 (00-sudo-prereqs.sh)
# has already been run with sudo. This script runs WITHOUT sudo.
#
# Usage:
#   # Step 1 (sudo, one-time): sudo ./00-sudo-prereqs.sh
#   # Step 2 (no sudo):        ./00-install-all.sh
#
# For 2nd+ GX10 deployment:
#   git clone https://github.com/holee9/gx10-install.git
#   cd gx10-install/scripts/install
#   sudo ./00-sudo-prereqs.sh   # Step 1: sudo (reboot/re-login after)
#   ./00-install-all.sh          # Step 2: no sudo
#
# Author: omc-developer
# Created: 2026-02-01
# Modified: 2026-02-03
#############################################

set -e
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/gx10/runtime/logs"
MAIN_LOG="$LOG_DIR/install-all.log"

# ==========================================
# Pre-flight checks
# ==========================================
echo "=========================================="
echo "GX10 Automated Installation"
echo "=========================================="
echo ""

# Check Phase 0 was completed
if [ ! -d "/gx10/brains/code/models" ]; then
  echo "ERROR: /gx10 directory structure not found."
  echo "Phase 0 must be run first:"
  echo "  sudo ./00-sudo-prereqs.sh"
  exit 1
fi

# Check Ollama is running
if ! curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
  echo "ERROR: Ollama service not responding."
  echo "Try: sudo systemctl restart ollama"
  exit 1
fi

# Check docker access
if ! docker ps > /dev/null 2>&1; then
  echo "ERROR: Docker access denied."
  echo "Try: newgrp docker (or re-login after Phase 0)"
  exit 1
fi

echo "Pre-flight checks passed:"
echo "  [OK] /gx10 directory structure exists"
echo "  [OK] Ollama service responding"
echo "  [OK] Docker access available"
echo ""
echo "This will run the following phases (NO sudo required):"
echo "  Phase 1: AI Model Download (~11 min)"
echo "  Phase 2: Vision Brain Docker Build (~5 min)"
echo "  Phase 3: Brain Switch API (~1 min)"
echo "  Phase 4: Open WebUI Install (~3 min)"
echo "  Phase 5: Final Validation (~2 min)"
echo "  Phase 6: Dashboard Install (~3 min)"
echo ""
echo "Total estimated time: ~28 minutes"
echo ""
echo "Log: $MAIN_LOG"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Installation cancelled."
  exit 1
fi

mkdir -p "$LOG_DIR"

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$MAIN_LOG"
}

log "Starting GX10 automated installation (post Phase 0)..."

# ==========================================
# Phase scripts (all run WITHOUT sudo)
# ==========================================
SCRIPTS=(
  "01-code-models-download.sh"
  "02-vision-brain-build.sh"
  "03-brain-switch-api.sh"
  "04-webui-install.sh"
  "05-final-validation.sh"
  "06-dashboard-install.sh"
)

TOTAL=${#SCRIPTS[@]}
for i in "${!SCRIPTS[@]}"; do
  SCRIPT="${SCRIPTS[$i]}"
  PHASE=$((i+1))

  echo "" | tee -a "$MAIN_LOG"
  log "=========================================="
  log "Phase $PHASE/$TOTAL: $SCRIPT"
  log "=========================================="

  if [ ! -f "$SCRIPT_DIR/$SCRIPT" ]; then
    log "ERROR: Script not found: $SCRIPT"
    exit 1
  fi

  chmod +x "$SCRIPT_DIR/$SCRIPT"

  if bash "$SCRIPT_DIR/$SCRIPT" >> "$MAIN_LOG" 2>&1; then
    log "Phase $PHASE completed successfully!"
  else
    log "ERROR: Phase $PHASE failed!"
    log "Check log: $MAIN_LOG"
    log "You can retry this phase:"
    echo "  cd $SCRIPT_DIR"
    echo "  ./$SCRIPT"
    exit 1
  fi
done

log "=========================================="
log "INSTALLATION COMPLETED SUCCESSFULLY!"
log "=========================================="
log ""
log "Access Information:"
log "  Dashboard:    http://$(hostname -I | awk '{print $1}'):9000"
log "  Open WebUI:   http://$(hostname -I | awk '{print $1}'):8080"
log "  Brain Status: /gx10/api/status.sh"
log "  Brain Switch: /gx10/api/switch.sh [code|vision]"
log ""
log "Installation Report: $LOG_DIR/installation-report.txt"
