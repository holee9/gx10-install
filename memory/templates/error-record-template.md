# Error Record Template

## Metadata

**Date**: YYYY-MM-DD
**Time**: HH:MM:SS
**Author**: [이름 또는 식별자]
**Category**: [code-error|process-mistake|communication-error]
**Severity**: [critical|high|medium|low]
**Status**: [investigating|resolved|mitigated|prevented]

## Tags

`severity: [critical|high|medium|low]`
`type: [code|process|communication]`
`status: [resolved|mitigated|investigating]`
`recurrence: [first-time|repeat|prevented]`
`component: [affected-component]`

---

## Problem Description

### What Happened?

[구체적으로 무슨 일이 일어났는지 설명]

### When Did It Happen?

[발생 시점과 상황]

### Context

[어떤 작업을 하다가 발생했는지, 관련 배경]

---

## Root Cause Analysis

### Immediate Cause

[직접적인 원인]

### Underlying Causes

[근본적인 원인 - 왜 이런 일이 발생했는지]

### Contributing Factors

[원인에 기여한 요소들]

### Why Wasn't It Caught?

[왜 미리 감지되지 않았는지]

---

## Impact Assessment

### Technical Impact

- [ ] System downtime: [duration]
- [ ] Data loss: [description]
- [ ] Performance degradation: [metrics]
- [ ] Broken functionality: [description]

### Process Impact

- [ ] Delayed deliverables: [what, how long]
- [ ] Rework required: [description]
- [ ] Team morale: [impact]

### Business Impact

- [ ] Cost: [estimated cost]
- [ ] Customer impact: [description]
- [ ] Reputation: [impact]

---

## Solution Implemented

### Immediate Fix

[당장 적용한 해결책]

### Long-term Fix

[장기적인 해결책]

### Verification

[해결책이 효과가 있었는지 어떻게 확인했는지]

---

## Prevention Strategies

### Process Changes

1. [프로세스 변경 사항 1]
2. [프로세스 변경 사항 2]

### Tool/Script Changes

1. [도구/스크립트 변경 사항 1]
2. [도구/스크립트 변경 사항 2]

### Education/Documentation

1. [교육/문서화 필요 사항 1]
2. [교육/문서화 필요 사항 2]

### Monitoring

[모니터링 방법 추가]

---

## References

### Related Issues

- Issue: #[number]
- PR: #[number]
- Commit: [hash]

### Related Documents

- [Document name](link)
- [Related error record](link)

### External Resources

- [Resource 1](link)
- [Resource 2](link)

---

## Lessons Learned

### What Went Well

[잘 진행된 부분]

### What Could Be Improved

[개선이 필요한 부분]

### Action Items

- [ ] [Action item 1] - Owner: [name] - Due: [date]
- [ ] [Action item 2] - Owner: [name] - Due: [date]

---

## Review History

| Date | Reviewer | Changes |
|------|----------|---------|
| YYYY-MM-DD | [name] | [change description] |

---

## 📝 문서 정보

**작성자**: alfrad (MoAI Reviewer)
**템플릿 버전**: 1.0.0
**생성일**: 2026-02-02
