#!/bin/bash
#############################################
# GX10 Complete Installation Script
# Runs all phases sequentially
#############################################

set -e
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/gx10/runtime/logs"
mkdir -p "$LOG_DIR"

MAIN_LOG="$LOG_DIR/install-all.log"

echo "=========================================="
echo "GX10 Complete Installation"
echo "=========================================="
echo "Log: $MAIN_LOG"
echo ""
echo "This will run all 10 installation phases."
echo "Total estimated time: 2-3 hours"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Installation cancelled."
  exit 1
fi

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$MAIN_LOG"
}

log "Starting complete GX10 installation..."

# Array of scripts
SCRIPTS=(
  "01-initial-setup.sh"
  "02-directory-structure.sh"
  "03-environment-config.sh"
  "04-code-brain-install.sh"
  "05-code-models-download.sh"
  "06-vision-brain-build.sh"
  "07-brain-switch-api.sh"
  "08-webui-install.sh"
  "09-service-automation.sh"
  "10-final-validation.sh"
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
    log "You can retry individual phases:"
    echo "  cd $SCRIPT_DIR"
    echo "  sudo ./$SCRIPT"
    exit 1
  fi
done

log "=========================================="
log "INSTALLATION COMPLETED SUCCESSFULLY!"
log "=========================================="
log "Installation Report: $LOG_DIR/installation-report.txt"
log ""
log "Next Steps:"
log "1. Review the installation report"
log "2. Test Open WebUI: http://$(hostname -I | awk '{print $1}'):8080"
log "3. Test n8n: http://$(hostname -I | awk '{print $1}'):5678"
log "4. Check brain status: /gx10/api/status.sh"
