#!/bin/bash
#############################################
# GX10 Complete Installation Script
# Runs all phases sequentially
#
# Reference: PRD.md Section "Implementation Phases"
# - Phase 1-6: Auto installation scripts
# - Sequential execution with error handling
#
# Author: omc-developer
# Created: 2026-02-01
# Modified: 2026-02-01
#
# Reviewed-By: alfrad (2026-02-01)
#############################################

# alfrad review:
# ✅ 전체 설치 프로세스 조율 스크립트로서 책임 범위 명확
# ✅ PRD.md 구현 단계 참조로 요구사항 추적 가능
# ✅ 순차 실행 및 에러 핸들링 전략 적절
# ⚠️ 확인: 개별 단계 실패 시 롤백 메커니즘 검토 필요
# 💡 제안: 진행 상황 시각화(Progress Bar) 추가 권장

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
