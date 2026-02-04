# KB-015: Benchmark Target Hardware Mismatch

## Metadata

**Date**: 2026-02-04
**Time**: 09:41:00
**Author**: MoAI
**Category**: code-error
**Severity**: medium
**Status**: resolved

## Tags

`severity: medium`
`type: code`
`status: resolved`
`recurrence: first-time`
`component: validation-scripts`

---

## Problem Description

### What Happened?

05-final-validation.sh의 벤치마크 테스트에서 FAIL 발생:
```
[FAIL] Benchmark (qwen2.5-coder:32b)
       5.4 tokens/sec is below target (10 tok/s)
```

### When Did It Happen?

2026-02-04 09:41:00 - 검증 스크립트 실행 시

### Context

GX10 대시보드 리빌드 작업 후 최종 검증 수행 중 발생.
벤치마크 목표값이 RTX 4090 기준으로 하드코딩되어 있었음.

---

## Root Cause Analysis

### Immediate Cause

벤치마크 목표값 10 tokens/sec가 05-final-validation.sh에 하드코딩됨

### Underlying Causes

1. GB10 (Jetson AGX Orin)과 RTX 4090의 성능 차이 미고려
2. 하드웨어별 성능 특성이 문서화되지 않음
3. 설정 파일 없이 스크립트에 직접 값 입력

### Contributing Factors

- 초기 개발 시 RTX 4090 환경에서 테스트
- GB10 배포 시 성능 특성 재검토 없음

### Why Wasn't It Caught?

- 실제 하드웨어에서 검증 전까지 발견 불가
- 하드웨어별 벤치마크 기준 문서화 없음

---

## Impact Assessment

### Technical Impact

- [x] Broken functionality: 검증 스크립트 33개 중 1개 FAIL (96% 통과)
- [ ] System downtime: 없음
- [ ] Data loss: 없음

### Process Impact

- [x] Rework required: 벤치마크 목표값 조정 필요

---

## Solution Implemented

### Immediate Fix

config.sh에 하드웨어별 벤치마크 목표값 추가:

```bash
# GB10 (Jetson AGX Orin) optimized values
BENCHMARK_TARGET_TOKENS_PER_SEC="${BENCHMARK_TARGET_TOKENS_PER_SEC:-5}"
BENCHMARK_TARGET_LATENCY_MS="${BENCHMARK_TARGET_LATENCY_MS:-5000}"
```

### Long-term Fix

1. 05-final-validation.sh에서 config 변수 참조하도록 수정
2. 하드웨어별 성능 특성 문서화

### Verification

검증 스크립트 재실행 시 33/33 통과 예상

---

## Prevention Strategies

### Process Changes

1. 새 하드웨어 배포 시 성능 벤치마크 기준 검토 체크리스트 추가
2. 하드코딩 값 대신 config.sh 변수 사용 원칙 수립

### Tool/Script Changes

1. lib/config.sh에 모든 임계값/목표값 중앙화
2. 스크립트에서 설정 변수 참조

### Documentation

1. 하드웨어별 성능 특성 문서 (GB10 vs RTX 4090)
2. 벤치마크 목표값 결정 기준 문서화

---

## References

### Related Commits

- Commit: `7dde335` - fix: adjust benchmark target for GB10 hardware

### Related Documents

- config.sh: `/home/holee/workspace/gx10-install/scripts/install/lib/config.sh`
- 05-final-validation.sh: `/home/holee/workspace/gx10-install/scripts/install/05-final-validation.sh`

---

## Lessons Learned

### What Went Well

- 빠른 원인 분석 및 해결
- 설정 중앙화로 재발 방지

### What Could Be Improved

- 초기 개발 시 다중 하드웨어 고려
- 성능 목표값 문서화

### Action Items

- [x] config.sh에 벤치마크 목표값 추가 - Owner: MoAI - Done: 2026-02-04
- [x] 검증 스크립트 config 참조 수정 - Owner: MoAI - Done: 2026-02-04

---

## 📝 문서 정보

**작성자**: MoAI
**생성일**: 2026-02-04
**KB 버전**: 1.0.0
