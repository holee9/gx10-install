#!/bin/bash
################################################################################
# DOC-SCR-AUDIT: GX10 Installation Scripts Verification Audit
#
# Purpose: Comprehensive validation of all installation script enhancements
# Author: Claude Sonnet 4.5 (MoAI-ADK v11.0.0)
# Date: 2026-02-02
#
# Usage: ./audit.sh
# Exit codes: 0 (all pass), 1 (any failure)
################################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED++))
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_info() {
    echo "[INFO] $1"
}

################################################################################
# Test 1: Metadata Completeness Check
# 모든 설치 스크립트에 DOC-SCR- 메타데이터 접두사가 있는지 확인
################################################################################

test_metadata() {
    print_header "검사 1: 메타데이터 완전성 확인"

    local missing_metadata=0
    local scripts_without_meta=()

    for script in "${SCRIPT_DIR}"/*.sh; do
        if [[ "$(basename "$script")" == "audit.sh" ]]; then
            continue
        fi

        if ! grep -q "DOC-SCR-" "$script"; then
            scripts_without_meta+=("$(basename "$script")")
            ((missing_metadata++))
        fi
    done

    if [[ $missing_metadata -eq 0 ]]; then
        print_pass "모든 스크립트에 DOC-SCR- 메타데이터가 있습니다"
    else
        print_fail "$missing_metadata 개의 스크립트에 메타데이터가 누락되었습니다:"
        for script in "${scripts_without_meta[@]}"; do
            print_info "  - $script"
        done
        echo ""
        echo "수정 제안: 각 스크립트 상단에 다음 형식의 메타데이터 추가:"
        echo "  # DOC-SCR-XXX: 스크립트 설명"
    fi
}

################################################################################
# Test 2: Hardcoded Password Check
# 하드코딩된 비밀번호가 없는지 확인
################################################################################

test_hardcoded_passwords() {
    print_header "검사 2: 하드코딩된 비밀번호 확인"

    local hardcoded_found=0

    # grep -v로 제외할 패턴: prompt, read, 변수 참조
    local results
    results=$(grep -rn "PASSWORD=" "${SCRIPT_DIR}"/*.sh 2>/dev/null | \
              grep -v "prompt\|read\|\${" || true || echo "")

    if [[ -z "$results" ]]; then
        print_pass "하드코딩된 비밀번호가 없습니다"
    else
        print_fail "하드코딩된 비밀번호가 발견되었습니다:"
        echo "$results"
        echo ""
        echo "수정 제안: 사용자 입력을 받도록 변경하세요."
        echo "  예: read -s -p '비밀번호 입력: ' PASSWORD"
    fi
}

################################################################################
# Test 3: HTTPS/Certificate Check
# 04-webui-install.sh에 HTTPS 설정이 포함되어 있는지 확인
################################################################################

test_https_config() {
    print_header "검사 3: HTTPS/인증서 설정 확인"

    local webui_script="${SCRIPT_DIR}/04-webui-install.sh"

    if [[ ! -f "$webui_script" ]]; then
        print_fail "04-webui-install.sh 파일을 찾을 수 없습니다"
        return
    fi

    local has_cert=0
    local has_443=0

    if grep -q "generate_cert" "$webui_script"; then
        ((has_cert++))
    fi

    if grep -q "443" "$webui_script"; then
        ((has_443++))
    fi

    if [[ $has_cert -gt 0 ]] && [[ $has_443 -gt 0 ]]; then
        print_pass "HTTPS 설정이 올바르게 구현되어 있습니다 (인증서 생성 + 443 포트)"
    else
        print_fail "HTTPS 설정이 불완전합니다:"
        [[ $has_cert -eq 0 ]] && print_info "  - 인증서 생성 기능 (generate_cert) 누락"
        [[ $has_443 -eq 0 ]] && print_info "  - HTTPS 포트 (443) 설정 누락"
        echo ""
        echo "수정 제안: 04-webui-install.sh에 다음 기능 추가:"
        echo "  1. 자체 서명된 인증서 생성 함수 구현"
        echo "  2. HTTPS 포트 (443) 설정 추가"
    fi
}

################################################################################
# Test 4: Library Sourcing Check
# 모든 스크립트가 라이브러리를 올바르게 소싱하는지 확인
################################################################################

test_library_sourcing() {
    print_header "검사 4: 라이브러리 소싱 확인"

    # 각 스크립트는 최소 4개의 라이브러리 소싱 (lib/logger.sh 등)
    local source_count
    source_count=$(grep -rn "source.*lib/" "${SCRIPT_DIR}"/*.sh 2>/dev/null | wc -l)

    # 예상: 5개 스크립트 × 4개 라이브러리 = 20개 이상
    local expected=20

    if [[ $source_count -ge $expected ]]; then
        print_pass "라이브러리 소싱이 충분합니다 ($source_count 개 발견, 예상: $expected+)"
    else
        print_fail "라이브러리 소싱이 부족합니다 ($source_count 개 발견, 예상: $expected+)"
        echo ""
        echo "수정 제안: 각 스크립트에 다음 라이브러리 추가:"
        echo "  source \"\${SCRIPT_ROOT}/lib/logger.sh\""
        echo "  source \"\${SCRIPT_ROOT}/lib/state-manager.sh\""
        echo "  source \"\${SCRIPT_ROOT}/lib/error-handler.sh\""
        echo "  source \"\${SCRIPT_ROOT}/lib/security.sh\""
    fi
}

################################################################################
# Test 5: Checkpoint Implementation Check
# 체크포인트 및 롤백 기능 구현 확인
################################################################################

test_checkpoints() {
    print_header "검사 5: 체크포인트 및 롤백 기능 확인"

    local checkpoint_count
    checkpoint_count=$(grep -rn "checkpoint\|rollback\|init_state" "${SCRIPT_DIR}"/*.sh 2>/dev/null | wc -l)

    # 예상: 10개 스크립트 × 최소 3개 = 30개 이상
    local expected=30

    if [[ $checkpoint_count -ge $expected ]]; then
        print_pass "체크포인트/롤백 기능이 충분합니다 ($checkpoint_count 개 발견, 예상: $expected+)"
    else
        print_fail "체크포인트/롤백 기능이 부족합니다 ($checkpoint_count 개 발견, 예상: $expected+)"
        echo ""
        echo "수정 제안: 각 스크립트에 다음 기능 추가:"
        echo "  1. create_checkpoint: 상태 저장 함수"
        echo "  2. rollback_checkpoint: 롤백 함수"
        echo "  3. init_state: 초기 상태 초기화"
    fi
}

################################################################################
# Test 6: Quantization Strategy Check
# 양자화 전략이 문서화되어 있는지 확인
################################################################################

test_quantization() {
    print_header "검사 6: 양자화 전략 확인"

    local quant_found
    quant_found=$(grep -rn "quant\|int8\|INT8" "${SCRIPT_DIR}"/*.sh 2>/dev/null || true)

    if [[ -n "$quant_found" ]]; then
        print_pass "양자화 전략이 문서화되어 있습니다"
        echo "$quant_found" | head -5
    else
        print_warning "양자화 관련 문서를 찾을 수 없습니다 (선택 사항)"
        echo ""
        echo "참고: 양자화 전략은 선택적 최적화 항목입니다."
        echo "필요시 01-code-models-download.sh에 다음 내용 추가:"
        echo "  # 양자화 전략: INT8 모델 사용으로 메모리 절약"
    fi
}

################################################################################
# Summary Report
################################################################################

print_summary() {
    print_header "감사 결과 요약"

    echo -e "${GREEN}통과: $PASSED${NC}"
    echo -e "${RED}실패: $FAILED${NC}"
    echo ""

    if [[ $FAILED -eq 0 ]]; then
        echo -e "${GREEN}모든 검사를 통과했습니다!${NC}"
        return 0
    else
        echo -e "${RED}일부 검사가 실패했습니다. 위의 수정 제안을 참고하세요.${NC}"
        return 1
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    echo "=========================================="
    echo "GX10 설치 스크립트 감사"
    echo "MoAI-ADK v11.0.0 | 2026-02-02"
    echo "=========================================="

    test_metadata
    test_hardcoded_passwords
    test_https_config
    test_library_sourcing
    test_checkpoints
    test_quantization

    print_summary
}

# Run main function
main "$@"
