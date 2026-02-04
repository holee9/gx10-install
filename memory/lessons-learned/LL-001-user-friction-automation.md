# LL-001: User Friction Must Be Automated

## Metadata

**Date**: 2026-02-04
**Author**: MoAI
**Category**: process
**Severity**: high
**Status**: resolved

## Tags

`severity: high`
`type: process`
`status: resolved`
`recurrence: first-time`

---

## Problem Description

테마 변경 시 localStorage에 이전 설정이 남아있어 사용자가 수동으로 개발자 도구를 열어 localStorage를 초기화해야 하는 번거로운 상황 발생.

---

## Root Cause

- 코드 변경으로 인한 사용자 환경 영향을 고려하지 않음
- 마이그레이션 없이 설정 구조 변경
- 사용자에게 수동 작업을 요구하는 해결책 제시

---

## Lesson Learned

### HARD Rule

**사용자에게 수동 작업을 요구하는 해결책은 금지**

코드로 해결할 수 있는 문제를 사용자에게 떠넘기지 않는다:
- localStorage 초기화 → 코드에서 자동 마이그레이션
- 캐시 클리어 → 버전 기반 캐시 무효화
- 설정 파일 수정 → 자동 마이그레이션 스크립트

### Prevention Checklist

1. 설정/상태 구조 변경 시 마이그레이션 코드 포함
2. 기존 사용자 데이터 자동 변환
3. 사용자 개입 없이 업데이트 적용 가능하도록 설계

---

## Correct Approach

**Before (Wrong)**:
```javascript
// 사용자가 직접 localStorage.removeItem() 실행 필요
const stored = localStorage.getItem('theme');
if (stored) use(stored);
```

**After (Correct)**:
```javascript
// 코드에서 자동으로 마이그레이션
localStorage.setItem('theme', 'dark');
document.documentElement.setAttribute('data-theme', 'dark');
```

---

## 📝 문서 정보

**작성자**: MoAI
**생성일**: 2026-02-04
