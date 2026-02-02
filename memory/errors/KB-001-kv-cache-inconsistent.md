# KB-001: KV Cache 설정 일관성 부족

## Metadata

**Date**: 2026-02-01
**Time**: 22:47:00
**Author**: alfrad (MoAI Reviewer)
**Category**: code-error
**Severity**: medium
**Status**: mitigated

## Tags

`severity: medium`
`type: code`
`status: mitigated`
`recurrence: first-time`
`component: 05-code-models-download.sh`

---

## Problem Description

### What Happened?

Phase 5 스크립트(`05-code-models-download.sh`)에서 KV Cache 설정이 메인 모델(qwen2.5-coder:32b)에만 적용되고, 7B 및 16B 모델에는 적용되지 않았습니다.

### When Did It Happen?

코드 리뷰 중인 2026-02-01 22:47경 발견

### Context

GX10 Code Brain 설치 단계에서 Ollama 모델 다운로드 시 환경변수 `OLLAMA_NUM_CTX=16384`가 설정되었으나, 이는 32B 모델 다운로드 전에만 설정되었습니다.

---

## Root Cause Analysis

### Immediate Cause

스크립트가 모델 다운로드 전에 환경변수를 한 번만 설정하고, 각 모델 다운로드마다 별도로 설정하지 않았습니다.

### Underlying Causes

1. Ollama가 각 모델 로드 시 환경변수를 읽는다는 동작을 명확히 이해하지 못함
2. 모든 모델이 동일한 KV Cache 설정을 필요로 한다는 가정

### Contributing Factors

- PRD.md에 16K context window 요구사항이 명시되어 있었으나(line 169), 구현 시 전체 모델에 적용하는 것을 간과
- 코드 리뷰에서 이 문제가 발견될 때까지 감지되지 않음

### Why Wasn't It Caught?

1. 구현 시점에서는 32B 모델만 고려
2. 테스트가 각 모델의 context window 크기를 검증하지 않음
3. LSP나 정적 분석 도구로는 감지 불가능한 논리적 오류

---

## Impact Assessment

### Technical Impact

- [ ] System downtime: 없음
- [ ] Data loss: 없음
- [x] Performance degradation: 7B/16B 모델이 기본 context window (4K)로 동작하여 장거리 코드 생성 시 성능 저하
- [x] Broken functionality: 16K context 요구사항 부분 미준수

### Process Impact

- [x] Rework required: PR 생성 후 수정 필요
- [ ] Team morale: 없음

### Business Impact

- [ ] Cost: 없음
- [x] Customer impact: 장거리 코드 분석 기능 제한
- [ ] Reputation: 없음

---

## Solution Implemented

### Immediate Fix

리뷰 코멘트로 문제 지정:
```bash
# alfrad review:
# ⚠️ 확인: 7B, 16B 모델에도 동일한 KV Cache 적용 필요 여부 검토 필요
# 💡 제안: 향후 KV Cache 값을 환경별로 설정 가능하도록 파라미터화 권장
```

### Long-term Fix

1. 각 모델 다운로드 전에 `OLLAMA_NUM_CTX`를 설정하거나,
2. 스크립트 시작 부분에서 전역으로 설정하여 모든 다운로드에 적용

### Verification

코드 리뷰 통과 - 실제 모델 실행 검증 필요 (추후 테스트 단계)

---

## Prevention Strategies

### Process Changes

1. **모델별 설정 검증 체크리스트 추가**: Code Brain 설치 완료 후 각 모델의 context window 크기 확인
2. **PRD 요구사항 매핑**: PRD.md에 명시된 모든 요구사항이 구현에 반영되었는지 검증 단계 추가

### Tool/Script Changes

1. **환경변수 파라미터화**:
```bash
# scripts/install/05-code-models-download.sh
KV_CACHE_SIZE=${KV_CACHE_SIZE:-16384}  # Default 16K
export OLLAMA_NUM_CTX=$KV_CACHE_SIZE
```

2. **모델 설정 검증 스크립트**:
```bash
# 각 모델 로드 후 context window 크기 확인
ollama run qwen2.5-coder:7b "echo $(ollama show qwen2.5-coder:7b --num_ctx)"
```

### Education/Documentation

1. 개발자 가이드에 Ollama 환경변수 설정 best practice 추가
2. 모델별 요구사항 검증 체크리스트 작성

### Monitoring

1. 설치 로그에 KV Cache 설정 값 포함
2. 모델 로드 시 실제 context window 크기 로깅

---

## References

### Related Issues

- PR: #feature/auto-installation-scripts
- Commit: 30e3b39 (review(alfrad): 05-code-models-download.sh 리뷰 의견 추가)

### Related Documents

- [PRD.md line 169](../PRD.md#L169) - "qwen2.5-coder:32b: 24GB (16K KV Cache)"
- [05-code-models-download.sh](../scripts/install/05-code-models-download.sh) - 수정된 스크립트

### External Resources

- [Ollama Environment Variables](https://github.com/ollama/ollama/blob/main/docs/api.md#environment-variables)
- [Context Window Best Practices](https://example.com)  # TODO: Add actual reference

---

## Lessons Learned

### What Went Well

- 코드 리뷰 단계에서 문제 조기 발견
- PRD 요구사항 참조로 추적 가능성 확보

### What Could Be Improved

- 구현 전 모델별 요구사항 명세화
- 환경변수 설정에 대한 단위 테스트

### Action Items

- [x] 리뷰 코멘트 추가 - Owner: alfrad - Due: 2026-02-01 ✅
- [ ] KV Cache 파라미터화 구현 - Owner: developer - Due: TBD
- [ ] 모델별 context window 검증 스크립트 작성 - Owner: tester - Due: TBD

---

## Review History

| Date | Reviewer | Changes |
|------|----------|---------|
| 2026-02-01 | alfrad | Initial record created from code review |

---

## 📝 문서 정보

**작성자**: alfrad (MoAI Reviewer)
**생성일**: 2026-02-02
**문서 ID**: KB-001
**상태**: Mitigated (리뷰 코멘트 추가, 구현 대기)
