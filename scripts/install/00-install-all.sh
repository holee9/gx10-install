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

# Load centralized configuration
source "$SCRIPT_DIR/lib/config.sh"
init_config

# Use configured paths
LOG_DIR="$GX10_LOGS_DIR"
MAIN_LOG="$LOG_DIR/install-all.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Pre-flight helper functions
test_pass() {
    local test_name="$1"
    local details="${2:-}"
    echo -e "${GREEN}[OK]${NC} $test_name"
    [ -n "$details" ] && echo "     $details"
}

test_fail() {
    local test_name="$1"
    local details="${2:-}"
    echo -e "${RED}[FAIL]${NC} $test_name"
    [ -n "$details" ] && echo "     $details"
}

section_header() {
    local title="$1"
    echo ""
    echo -e "${YELLOW}--- $title ---${NC}"
}

# ==========================================
# Pre-flight checks (comprehensive)
# ==========================================
preflight_check() {
    section_header "Pre-flight Checks"
    local errors=0

    # 1. Disk space check (need MIN_DISK_SPACE_GB from config.sh)
    echo "Checking disk space..."
    local available_gb=$(df -BG /gx10 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'G')
    if [[ -z "$available_gb" ]]; then
        available_gb=$(df -BG / | tail -1 | awk '{print $4}' | tr -d 'G')
    fi
    if [[ "$available_gb" -lt "$MIN_DISK_SPACE_GB" ]]; then
        test_fail "Disk space" "${available_gb}GB available, need ${MIN_DISK_SPACE_GB}GB"
        ((errors++))
    else
        test_pass "Disk space" "${available_gb}GB available"
    fi

    # 2. Memory check
    echo "Checking memory..."
    local mem_gb=$(free -g | awk '/^Mem:|^메모리:/{print $2}')
    if [[ "$mem_gb" -lt "$MIN_MEMORY_GB" ]]; then
        test_fail "Memory" "${mem_gb}GB available, need ${MIN_MEMORY_GB}GB"
        ((errors++))
    else
        test_pass "Memory" "${mem_gb}GB available"
    fi

    # 3. GPU check
    echo "Checking GPU..."
    if command -v nvidia-smi &>/dev/null; then
        local gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
        local gpu_memory=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1)
        if [[ -n "$gpu_name" ]]; then
            test_pass "GPU" "$gpu_name ($gpu_memory)"
        else
            test_fail "GPU" "nvidia-smi found but no GPU detected"
            ((errors++))
        fi
    else
        test_fail "GPU" "nvidia-smi not found"
        ((errors++))
    fi

    # 4. Network connectivity
    echo "Checking network..."
    if curl -s --max-time 5 https://ollama.com > /dev/null 2>&1; then
        test_pass "Network" "Internet connectivity OK"
    else
        test_fail "Network" "Cannot reach ollama.com"
        ((errors++))
    fi

    # 5. Docker availability
    echo "Checking Docker..."
    if docker info &>/dev/null; then
        local docker_version=$(docker --version | awk '{print $3}' | tr -d ',')
        test_pass "Docker" "Docker daemon accessible (v$docker_version)"
    else
        test_fail "Docker" "Docker not accessible (run 00-sudo-prereqs.sh first)"
        ((errors++))
    fi

    # 6. Phase 0 completion check
    echo "Checking Phase 0 completion..."
    if [ -d "$OLLAMA_MODELS_DIR" ]; then
        test_pass "Phase 0" "/gx10 directory structure exists"
    else
        test_fail "Phase 0" "$GX10_BASE_DIR directory structure not found"
        ((errors++))
    fi

    # 7. Ollama service check
    echo "Checking Ollama service..."
    if curl -s "$OLLAMA_API_URL/api/version" > /dev/null 2>&1; then
        local ollama_version=$(curl -s "$OLLAMA_API_URL/api/version" | jq -r '.version' 2>/dev/null || echo "unknown")
        test_pass "Ollama" "Service responding (v$ollama_version)"
    else
        test_fail "Ollama" "Service not responding on $OLLAMA_API_URL"
        ((errors++))
    fi

    # 8. Required tools check
    echo "Checking required tools..."
    local missing_tools=""
    for tool in curl jq bc git; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools="$missing_tools $tool"
        fi
    done
    if [[ -z "$missing_tools" ]]; then
        test_pass "Required tools" "curl, jq, bc, git available"
    else
        test_fail "Required tools" "Missing:$missing_tools"
        ((errors++))
    fi

    echo ""
    if [[ $errors -gt 0 ]]; then
        echo -e "${RED}Pre-flight checks failed with $errors errors${NC}"
        echo "Please fix the issues above before continuing."
        return 1
    fi

    echo -e "${GREEN}All pre-flight checks passed${NC}"
    return 0
}

# ==========================================
# Main Script Start
# ==========================================
echo "=========================================="
echo "GX10 Automated Installation"
echo "=========================================="

# Run comprehensive pre-flight checks
if ! preflight_check; then
    echo ""
    echo "Installation aborted due to pre-flight check failures."
    echo "Please resolve the issues above and try again."
    exit 1
fi

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
log "  Dashboard:    http://$(hostname -I | awk '{print $1}'):$DASHBOARD_PORT"
log "  Open WebUI:   http://$(hostname -I | awk '{print $1}'):$WEBUI_PORT"
log "  Brain Status: $GX10_API_DIR/status.sh"
log "  Brain Switch: $GX10_API_DIR/switch.sh [code|vision]"
log ""
log "Installation Report: $LOG_DIR/installation-report.txt"
