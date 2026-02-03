#!/bin/bash
#############################################
# GX10 Auto Installation Script - Phase 5
# Final Validation (Fully Automated)
#
# This script automatically tests ALL components:
# - System resources (GPU, Memory, Disk)
# - Code Brain (Ollama + Models)
# - Vision Brain (Docker + GPU)
# - Brain switching (both directions)
# - Open WebUI (HTTP response)
# - Dashboard (Health, Metrics, External access)
#
# NO manual intervention required.
#
# Author: omc-developer
# Created: 2026-02-01
# Modified: 2026-02-03
#
# Version: 3.0.0
# Status: RELEASED
# Related: KB-014 (Automated validation enhancement)
#############################################

set -u
# Note: set -e removed to allow test continuation on failures

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/state-manager.sh"
source "$SCRIPT_DIR/lib/error-handler.sh"

LOG_FILE="/gx10/runtime/logs/05-final-validation.log"
REPORT_FILE="/gx10/runtime/logs/validation-report.txt"
mkdir -p /gx10/runtime/logs

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Network
IP=$(hostname -I | awk '{print $1}')

# Initialize phase log
PHASE="05"
init_state 2>/dev/null || true
init_checkpoint_system 2>/dev/null || true
init_log "$PHASE" "$(basename "$0" .sh)" 2>/dev/null || true

#############################################
# Test Helper Functions
#############################################

test_pass() {
    local test_name="$1"
    local details="${2:-}"
    ((TESTS_PASSED++))
    ((TESTS_TOTAL++))
    echo -e "${GREEN}[PASS]${NC} $test_name" | tee -a "$LOG_FILE"
    echo "[PASS] $test_name" >> "$REPORT_FILE"
    [ -n "$details" ] && echo "       $details" | tee -a "$LOG_FILE" "$REPORT_FILE"
}

test_fail() {
    local test_name="$1"
    local details="${2:-}"
    ((TESTS_FAILED++))
    ((TESTS_TOTAL++))
    echo -e "${RED}[FAIL]${NC} $test_name" | tee -a "$LOG_FILE"
    echo "[FAIL] $test_name" >> "$REPORT_FILE"
    [ -n "$details" ] && echo "       $details" | tee -a "$LOG_FILE" "$REPORT_FILE"
}

section_header() {
    local title="$1"
    echo "" | tee -a "$LOG_FILE" "$REPORT_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}  $title${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    echo "=== $title ===" >> "$REPORT_FILE"
}

#############################################
# Main Script
#############################################

echo "==========================================" | tee "$LOG_FILE"
echo "GX10 Phase 5: Final Validation (Automated)" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"
echo "Log: $LOG_FILE" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Initialize report
cat > "$REPORT_FILE" << EOF
==========================================
GX10 VALIDATION REPORT
==========================================
Generated: $(date)
Hostname: $(hostname)
==========================================

EOF

# Save original brain state for restoration
ORIGINAL_BRAIN=$(cat /gx10/runtime/active_brain.json 2>/dev/null | jq -r '.brain' 2>/dev/null || echo "unknown")
echo -e "${YELLOW}Current Brain State: $ORIGINAL_BRAIN${NC}" | tee -a "$LOG_FILE"
echo "Original Brain State: $ORIGINAL_BRAIN" >> "$REPORT_FILE"

#############################################
# TEST 1: System Resources
#############################################
section_header "1. System Resources"

# Test 1.1: GPU Detection
if nvidia-smi > /dev/null 2>&1; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
    GPU_MEMORY=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1)
    test_pass "GPU Detection" "$GPU_NAME ($GPU_MEMORY)"
else
    test_fail "GPU Detection" "nvidia-smi not responding"
fi

# Test 1.2: Memory (>100GB required)
TOTAL_MEM_GB=$(free -g | awk '/^메모리:|^Mem:/ {print $2}')
if [ "$TOTAL_MEM_GB" -ge 100 ]; then
    test_pass "Memory Check" "${TOTAL_MEM_GB}GB total (≥100GB required)"
else
    test_fail "Memory Check" "${TOTAL_MEM_GB}GB total (<100GB)"
fi

# Test 1.3: Disk Space (>500GB free required)
FREE_DISK_GB=$(df -BG / | awk 'NR==2 {gsub("G",""); print $4}')
if [ "$FREE_DISK_GB" -ge 500 ]; then
    test_pass "Disk Space" "${FREE_DISK_GB}GB free (≥500GB required)"
else
    test_fail "Disk Space" "${FREE_DISK_GB}GB free (<500GB)"
fi

# Test 1.4: Directory Structure
if [ -d "/gx10/api" ] && [ -d "/gx10/brains" ] && [ -d "/gx10/runtime" ]; then
    test_pass "Directory Structure" "/gx10/{api,brains,runtime} exist"
else
    test_fail "Directory Structure" "Missing /gx10 directories"
fi

#############################################
# TEST 2: Code Brain (Ollama)
#############################################
section_header "2. Code Brain (Ollama)"

# Switch to Code Brain first
echo -e "${YELLOW}Switching to Code Brain...${NC}" | tee -a "$LOG_FILE"
if sudo /gx10/api/switch.sh code >> "$LOG_FILE" 2>&1; then
    sleep 3
    echo "Switched to Code Brain" >> "$REPORT_FILE"
else
    echo "Warning: Brain switch may require manual sudo" | tee -a "$LOG_FILE"
fi

# Test 2.1: Ollama Service
if systemctl is-active --quiet ollama 2>/dev/null; then
    test_pass "Ollama Service" "systemd service active"
else
    # Try to start it
    sudo systemctl start ollama 2>/dev/null
    sleep 3
    if systemctl is-active --quiet ollama 2>/dev/null; then
        test_pass "Ollama Service" "started successfully"
    else
        test_fail "Ollama Service" "not running"
    fi
fi

# Test 2.2: Ollama API Response
if curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
    OLLAMA_VERSION=$(curl -s http://localhost:11434/api/version | jq -r '.version' 2>/dev/null || echo "unknown")
    test_pass "Ollama API" "responding (v$OLLAMA_VERSION)"
else
    test_fail "Ollama API" "not responding on port 11434"
fi

# Test 2.3: Required Models
REQUIRED_MODELS=("qwen2.5-coder:32b" "qwen2.5-coder:7b" "deepseek-coder-v2:16b" "nomic-embed-text")
MODELS_FOUND=0
MODELS_MISSING=""

for model in "${REQUIRED_MODELS[@]}"; do
    if ollama list 2>/dev/null | grep -q "$model"; then
        ((MODELS_FOUND++))
    else
        MODELS_MISSING="$MODELS_MISSING $model"
    fi
done

if [ $MODELS_FOUND -eq ${#REQUIRED_MODELS[@]} ]; then
    test_pass "AI Models" "All ${#REQUIRED_MODELS[@]} models installed"
else
    test_fail "AI Models" "$MODELS_FOUND/${#REQUIRED_MODELS[@]} installed. Missing:$MODELS_MISSING"
fi

# Test 2.4: Model Response Test (using fast 7B model)
echo -e "${YELLOW}Testing model response (qwen2.5-coder:7b)...${NC}" | tee -a "$LOG_FILE"
START_TIME=$(date +%s.%N)
RESPONSE=$(timeout 60 ollama run qwen2.5-coder:7b "Reply with only: OK" 2>/dev/null | head -1)
END_TIME=$(date +%s.%N)
RESPONSE_TIME=$(echo "$END_TIME - $START_TIME" | bc 2>/dev/null || echo "unknown")

if echo "$RESPONSE" | grep -qi "OK"; then
    test_pass "Model Response" "qwen2.5-coder:7b responded in ${RESPONSE_TIME}s"
else
    test_fail "Model Response" "No valid response from model"
fi

#############################################
# TEST 3: Vision Brain (Docker)
#############################################
section_header "3. Vision Brain (Docker)"

# Test 3.1: Docker Access
if docker ps > /dev/null 2>&1; then
    test_pass "Docker Access" "docker daemon accessible"
else
    test_fail "Docker Access" "permission denied or docker not running"
fi

# Test 3.2: Vision Brain Image
if docker images | grep -q "gx10-vision-brain"; then
    IMAGE_SIZE=$(docker images gx10-vision-brain:latest --format "{{.Size}}" 2>/dev/null)
    test_pass "Vision Brain Image" "gx10-vision-brain:latest ($IMAGE_SIZE)"
else
    test_fail "Vision Brain Image" "gx10-vision-brain:latest not found"
fi

# Test 3.3: Switch to Vision Brain
echo -e "${YELLOW}Switching to Vision Brain...${NC}" | tee -a "$LOG_FILE"
SWITCH_START=$(date +%s)
if sudo /gx10/api/switch.sh vision >> "$LOG_FILE" 2>&1; then
    SWITCH_END=$(date +%s)
    SWITCH_TIME=$((SWITCH_END - SWITCH_START))
    if [ $SWITCH_TIME -le 30 ]; then
        test_pass "Vision Brain Switch" "completed in ${SWITCH_TIME}s (≤30s target)"
    else
        test_fail "Vision Brain Switch" "took ${SWITCH_TIME}s (>30s target)"
    fi
else
    test_fail "Vision Brain Switch" "switch command failed"
fi

# Test 3.4: Vision Brain GPU Access
echo -e "${YELLOW}Testing Vision Brain GPU access...${NC}" | tee -a "$LOG_FILE"
VISION_GPU_TEST=$(docker run --rm --gpus all gx10-vision-brain:latest python -c "import torch; print(f'CUDA:{torch.cuda.is_available()},GPU:{torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}')" 2>/dev/null)
if echo "$VISION_GPU_TEST" | grep -q "CUDA:True"; then
    GPU_IN_DOCKER=$(echo "$VISION_GPU_TEST" | grep -o "GPU:.*" | cut -d',' -f1)
    test_pass "Vision Brain GPU" "$GPU_IN_DOCKER"
else
    test_fail "Vision Brain GPU" "CUDA not available in container"
fi

#############################################
# TEST 4: Brain Switching
#############################################
section_header "4. Brain Switching Performance"

# Test 4.1: Switch back to Code Brain (measure time)
echo -e "${YELLOW}Switching back to Code Brain...${NC}" | tee -a "$LOG_FILE"
SWITCH_START=$(date +%s)
if sudo /gx10/api/switch.sh code >> "$LOG_FILE" 2>&1; then
    SWITCH_END=$(date +%s)
    SWITCH_TIME=$((SWITCH_END - SWITCH_START))
    if [ $SWITCH_TIME -le 30 ]; then
        test_pass "Code Brain Switch" "completed in ${SWITCH_TIME}s (≤30s target)"
    else
        test_fail "Code Brain Switch" "took ${SWITCH_TIME}s (>30s target)"
    fi
else
    test_fail "Code Brain Switch" "switch command failed"
fi

# Test 4.2: Verify Code Brain is active
sleep 2
CURRENT_BRAIN=$(cat /gx10/runtime/active_brain.json 2>/dev/null | jq -r '.brain' 2>/dev/null || echo "unknown")
if [ "$CURRENT_BRAIN" == "code" ]; then
    test_pass "Brain State Verification" "active_brain.json shows 'code'"
else
    test_fail "Brain State Verification" "Expected 'code', got '$CURRENT_BRAIN'"
fi

# Test 4.3: Ollama responsive after switch
sleep 2
if curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
    test_pass "Post-Switch Ollama" "API responding after switch"
else
    test_fail "Post-Switch Ollama" "API not responding after switch"
fi

#############################################
# TEST 5: Open WebUI
#############################################
section_header "5. Open WebUI"

# Test 5.1: Container Running
if docker ps | grep -q "open-webui"; then
    CONTAINER_STATUS=$(docker ps --filter "name=open-webui" --format "{{.Status}}" | head -1)
    test_pass "WebUI Container" "running ($CONTAINER_STATUS)"
else
    test_fail "WebUI Container" "not running"
fi

# Test 5.2: HTTP Response
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null || echo "000")
if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "302" ]; then
    test_pass "WebUI HTTP" "responding (HTTP $HTTP_CODE)"
else
    test_fail "WebUI HTTP" "not responding (HTTP $HTTP_CODE)"
fi

# Test 5.3: Ollama Connection from WebUI perspective
OLLAMA_FROM_DOCKER=$(docker exec open-webui curl -s http://host.docker.internal:11434/api/version 2>/dev/null | jq -r '.version' 2>/dev/null || echo "failed")
if [ "$OLLAMA_FROM_DOCKER" != "failed" ] && [ -n "$OLLAMA_FROM_DOCKER" ]; then
    test_pass "WebUI-Ollama Link" "WebUI can reach Ollama (v$OLLAMA_FROM_DOCKER)"
else
    test_fail "WebUI-Ollama Link" "WebUI cannot reach Ollama"
fi

#############################################
# TEST 6: API Scripts
#############################################
section_header "6. API Scripts"

# Test 6.1-6.4: Check all API scripts exist and are executable
API_SCRIPTS=("status.sh" "switch.sh" "predict.sh" "benchmark.sh")
for script in "${API_SCRIPTS[@]}"; do
    if [ -x "/gx10/api/$script" ]; then
        test_pass "API Script" "/gx10/api/$script (executable)"
    else
        test_fail "API Script" "/gx10/api/$script (missing or not executable)"
    fi
done

#############################################
# TEST 7: Dashboard
#############################################
section_header "7. Dashboard"

# Test 7.1: Dashboard Service
if systemctl is-active --quiet gx10-dashboard 2>/dev/null; then
    test_pass "Dashboard Service" "systemd service active"
else
    test_fail "Dashboard Service" "not running"
fi

# Test 7.2: Dashboard Health API
DASHBOARD_HEALTH=$(curl -s http://localhost:9000/api/health 2>/dev/null)
if echo "$DASHBOARD_HEALTH" | jq -e '.status == "ok"' > /dev/null 2>&1; then
    UPTIME=$(echo "$DASHBOARD_HEALTH" | jq -r '.uptime' 2>/dev/null | cut -d'.' -f1)
    test_pass "Dashboard Health" "API responding (uptime: ${UPTIME}s)"
else
    test_fail "Dashboard Health" "not responding on port 9000"
fi

# Test 7.3: Dashboard Status API
DASHBOARD_STATUS=$(curl -s http://localhost:9000/api/status 2>/dev/null)
if echo "$DASHBOARD_STATUS" | jq -e '.cpu and .memory and .gpu' > /dev/null 2>&1; then
    CPU_USAGE=$(echo "$DASHBOARD_STATUS" | jq -r '.cpu.usage' 2>/dev/null)
    MEM_PCT=$(echo "$DASHBOARD_STATUS" | jq -r '.memory.percentage' 2>/dev/null)
    test_pass "Dashboard Metrics" "CPU:${CPU_USAGE}%, Memory:${MEM_PCT}%"
else
    test_fail "Dashboard Metrics" "/api/status not returning valid data"
fi

# Test 7.4: Dashboard External Access
DASHBOARD_EXTERNAL=$(curl -s -o /dev/null -w "%{http_code}" http://$IP:9000/api/health 2>/dev/null || echo "000")
if [ "$DASHBOARD_EXTERNAL" == "200" ]; then
    test_pass "Dashboard External" "accessible from http://$IP:9000"
else
    test_fail "Dashboard External" "not accessible externally (HTTP $DASHBOARD_EXTERNAL)"
fi

# Test 7.5: Dashboard Brain API
DASHBOARD_BRAIN=$(curl -s http://localhost:9000/api/brain 2>/dev/null)
if echo "$DASHBOARD_BRAIN" | jq -e '.active' > /dev/null 2>&1; then
    ACTIVE_BRAIN=$(echo "$DASHBOARD_BRAIN" | jq -r '.active' 2>/dev/null)
    test_pass "Dashboard Brain API" "Brain mode: $ACTIVE_BRAIN"
else
    test_fail "Dashboard Brain API" "/api/brain not returning valid data"
fi

# Test 7.6: Dashboard Storage API
DASHBOARD_STORAGE=$(curl -s http://localhost:9000/api/metrics/storage 2>/dev/null)
if echo "$DASHBOARD_STORAGE" | jq -e '.disks' > /dev/null 2>&1; then
    DISK_COUNT=$(echo "$DASHBOARD_STORAGE" | jq '.disks | length' 2>/dev/null)
    test_pass "Dashboard Storage API" "${DISK_COUNT} disk(s) detected"
else
    test_fail "Dashboard Storage API" "/api/metrics/storage not returning valid data"
fi

# Test 7.7: Dashboard Network API
DASHBOARD_NETWORK=$(curl -s http://localhost:9000/api/metrics/network 2>/dev/null)
if echo "$DASHBOARD_NETWORK" | jq -e '.interfaces' > /dev/null 2>&1; then
    IFACE_COUNT=$(echo "$DASHBOARD_NETWORK" | jq '.interfaces | length' 2>/dev/null)
    PRIMARY_IP=$(echo "$DASHBOARD_NETWORK" | jq -r '.primaryIp // "N/A"' 2>/dev/null)
    test_pass "Dashboard Network API" "${IFACE_COUNT} interfaces, Primary: $PRIMARY_IP"
else
    test_fail "Dashboard Network API" "/api/metrics/network not returning valid data"
fi

#############################################
# FINAL SUMMARY
#############################################
section_header "VALIDATION SUMMARY"

echo "" | tee -a "$LOG_FILE" "$REPORT_FILE"

# Calculate pass rate
if [ $TESTS_TOTAL -gt 0 ]; then
    PASS_RATE=$((TESTS_PASSED * 100 / TESTS_TOTAL))
else
    PASS_RATE=0
fi

# Display summary
echo "==========================================" | tee -a "$LOG_FILE" "$REPORT_FILE"
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED${NC}" | tee -a "$LOG_FILE"
    echo "✅ ALL TESTS PASSED" >> "$REPORT_FILE"
else
    echo -e "${RED}❌ SOME TESTS FAILED${NC}" | tee -a "$LOG_FILE"
    echo "❌ SOME TESTS FAILED" >> "$REPORT_FILE"
fi
echo "==========================================" | tee -a "$LOG_FILE" "$REPORT_FILE"
echo "" | tee -a "$LOG_FILE" "$REPORT_FILE"
echo -e "  ${GREEN}Passed:${NC} $TESTS_PASSED" | tee -a "$LOG_FILE"
echo -e "  ${RED}Failed:${NC} $TESTS_FAILED" | tee -a "$LOG_FILE"
echo -e "  Total:  $TESTS_TOTAL" | tee -a "$LOG_FILE"
echo -e "  Rate:   ${PASS_RATE}%" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE" "$REPORT_FILE"
echo "  Passed: $TESTS_PASSED" >> "$REPORT_FILE"
echo "  Failed: $TESTS_FAILED" >> "$REPORT_FILE"
echo "  Total:  $TESTS_TOTAL" >> "$REPORT_FILE"
echo "  Rate:   ${PASS_RATE}%" >> "$REPORT_FILE"

# Access Information
echo "" | tee -a "$LOG_FILE" "$REPORT_FILE"
echo "ACCESS INFORMATION:" | tee -a "$LOG_FILE" "$REPORT_FILE"
echo "  Dashboard:    http://$IP:9000" | tee -a "$LOG_FILE" "$REPORT_FILE"
echo "  Open WebUI:   http://$IP:8080" | tee -a "$LOG_FILE" "$REPORT_FILE"
echo "  Brain Status: /gx10/api/status.sh" | tee -a "$LOG_FILE" "$REPORT_FILE"
echo "  Brain Switch: sudo /gx10/api/switch.sh [code|vision]" | tee -a "$LOG_FILE" "$REPORT_FILE"
echo "" | tee -a "$LOG_FILE" "$REPORT_FILE"
echo "Report saved: $REPORT_FILE" | tee -a "$LOG_FILE"
echo "Log saved: $LOG_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Completed: $(date)" | tee -a "$LOG_FILE" "$REPORT_FILE"

# Exit with appropriate code
if [ $TESTS_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
