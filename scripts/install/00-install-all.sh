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

# alfrad review (v2.0.0 updates):
# ✅ 보안 강화: admin password 대화형 프롬프트로 하드코딩 제거
# ✅ HTTPS 지원: 443 포트로 SSL 인증서 적용
# ✅ 문서 메타데이터 추가 (DOC-SCR-000, Version 2.0.0)
# ✅ 의존성 명시로 모든 Phase 스크립트 관계 명확
# ⚠️ 확인: get_admin_password 함수가 lib/security.sh에 구현되어 있어야 함
# 💡 제안: 비밀번호 복잡도 검증 로직이 security.sh에 있는지 확인 필요

#
# Document-ID: DOC-SCR-000
# Document-Name: GX10 Auto-Installation Script - Master Orchestrator
# Reference: GX10-03-Final-Implementation-Guide.md Section "Implementation Phases"
# Reference: GX10-09-Two-Brain-Optimization.md Section "P0 Optimizations"
#
# Version: 2.0.0
# Status: RELEASED
# Dependencies: DOC-SCR-001, DOC-SCR-002, DOC-SCR-003, DOC-SCR-004, DOC-SCR-005, DOC-SCR-006, DOC-SCR-007, DOC-SCR-008, DOC-SCR-009, DOC-SCR-010
#

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

# Security: Get admin password before starting phases
log "Configuring security credentials..."

# Source security library
source "$SCRIPT_DIR/lib/security.sh"

# Get admin password (from GX10_PASSWORD env or interactive prompt)
ADMIN_PASSWORD=$(get_admin_password)

if [ -z "$ADMIN_PASSWORD" ]; then
    log "ERROR: Failed to get admin password"
    log "Installation cannot proceed without valid admin credentials"
    exit 1
fi

# Export for all child scripts
export GX10_ADMIN_PASSWORD="$ADMIN_PASSWORD"

log "Security credentials configured successfully"

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
log "Access Information:"
log "1. Review the installation report"
log "2. Open WebUI: https://$(hostname -I | awk '{print $1}'):443"
log "3. n8n Automation: http://$(hostname -I | awk '{print $1}'):5678"
log "   Username: admin"
log "   Password: [Set during installation - check .admin_password file]"
log "4. Check brain status: /gx10/api/status.sh"
log ""
log "Security Note: Default admin password has been configured."
