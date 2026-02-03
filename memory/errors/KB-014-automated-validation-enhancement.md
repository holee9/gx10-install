# KB-014: Automated Validation Enhancement

## Issue

기존 `05-final-validation.sh` 스크립트가 현재 Brain 상태를 고려하지 않고 테스트를 수행하여, Vision Brain 모드에서 실행 시 Ollama 테스트가 실패하는 문제.

## Root Cause

1. 현재 Brain 상태를 확인하지 않고 Ollama 테스트 시도
2. Brain 전환 없이 순차적으로 모든 테스트 수행
3. 테스트 결과 PASS/FAIL 판정 부재
4. 개별 테스트 실패 시 전체 스크립트 중단 (`set -e`)

## Solution

완전 자동화된 검증 스크립트로 재작성 (v3.0.0):

### 주요 개선 사항

1. **자동 Brain 전환**: Code Brain 테스트 전 자동 전환, Vision Brain 테스트 전 자동 전환
2. **개별 테스트 판정**: 각 테스트마다 PASS/FAIL 명시
3. **실패 허용**: `set -e` 제거로 개별 테스트 실패 시에도 계속 진행
4. **종합 리포트**: 총 테스트 수, 통과 수, 실패 수, 통과율 표시

### 테스트 항목 (총 20개)

| 카테고리 | 테스트 | 설명 |
|----------|--------|------|
| 1. System | GPU Detection | nvidia-smi 응답 |
| | Memory Check | ≥100GB 확인 |
| | Disk Space | ≥500GB 여유 |
| | Directory Structure | /gx10 구조 확인 |
| 2. Code Brain | Ollama Service | systemd 상태 |
| | Ollama API | 포트 11434 응답 |
| | AI Models | 4개 모델 설치 확인 |
| | Model Response | 실제 응답 테스트 |
| 3. Vision Brain | Docker Access | docker ps 권한 |
| | Vision Image | 이미지 존재 확인 |
| | Vision Switch | 전환 시간 ≤30s |
| | Vision GPU | 컨테이너 내 CUDA |
| 4. Switching | Code Switch | 전환 시간 ≤30s |
| | State Verification | JSON 상태 확인 |
| | Post-Switch Ollama | 전환 후 API 응답 |
| 5. WebUI | Container Running | 컨테이너 상태 |
| | HTTP Response | 포트 8080 응답 |
| | WebUI-Ollama Link | 내부 연결 확인 |
| 6. API Scripts | status.sh | 실행 권한 |
| | switch.sh | 실행 권한 |
| | predict.sh | 실행 권한 |
| | benchmark.sh | 실행 권한 |

### 출력 예시

```
==========================================
GX10 Phase 5: Final Validation (Automated)
==========================================

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. System Resources
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[PASS] GPU Detection
       NVIDIA GB10 ([N/A])
[PASS] Memory Check
       119GB total (≥100GB required)
...

==========================================
✅ ALL TESTS PASSED
==========================================

  Passed: 20
  Failed: 0
  Total:  20
  Rate:   100%
```

## Prevention

검증 스크립트 작성 시:
- 테스트 대상의 현재 상태를 먼저 확인
- 필요한 전제 조건을 자동으로 설정
- 개별 테스트 실패가 전체를 중단시키지 않도록 설계
- 명확한 PASS/FAIL 판정 및 종합 요약 제공

## Document Info

| Field | Value |
|-------|-------|
| **KB ID** | KB-014 |
| **Category** | Validation / Automation |
| **Severity** | Medium |
| **Status** | Resolved |
| **Created** | 2026-02-03 |
| **Script Version** | 05-final-validation.sh v3.0.0 |
