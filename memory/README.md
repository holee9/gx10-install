# Memory - Knowledge Base System

## Purpose

이 시스템은 프로젝트 진행 중 발생한 모든 유형의 실수와 오류를 기록하고, 해결 방법을 문서화하여 반복 실수를 방지하는 지식 베이스입니다.

## Folder Structure

```
memory/
├── README.md                 # 이 파일
├── errors/                   # 자동 감지된 기술적 오류
├── lessons-learned/          # 프로세스/커뮤니케이션 실수
├── templates/                # 문서 템플릿
└── auto-detected/            # 자동화 스크립트 결과
```

## Categories

### 1. Code Errors (errors/)

기술적 오류, 버그, 빌드 실패 등 자동 감지 가능한 문제

**자동 감지 sources**:
- Git commit failures
- LSP errors (TypeScript, Python, etc.)
- Build failures
- Test failures
- Runtime errors

### 2. Process Mistakes (lessons-learned/)

프로세스 오류, 커뮤니케이션 실수, 워크플로우 실패

**수작성 항목**:
- 잘못된 의사결정 프로세스
- 커뮤니케이션 오류
- 작업 우선순위 실수
- 협업 실패 사례

## Documentation Format

모든 기록은 ADR (Architecture Decision Record) 형식을 따릅니다:

### Required Fields

1. **Date**: 발생일
2. **Category**: 오류 유형
3. **Problem**: 문제 설명
4. **Root Cause**: 근본 원인 분석
5. **Impact**: 영향 평가
6. **Solution**: 적용한 해결책
7. **Prevention**: 재발 방지 대책
8. **References**: 관련 링크 (이슈, 커밋, PR)

### Tags

- `severity: critical|high|medium|low`
- `type: code|process|communication`
- `status: resolved|mitigated|investigating`
- `recurrence: first-time|repeat|prevented`

## Workflow

### Auto-Detection

1. Git hook이 실패를 감지
2. `auto-detected/`에 임시 기록 생성
3. 분석 후 `errors/`로 이동 및 상세 기록

### Manual Recording

1. `templates/`에서 적절한 템플릿 선택
2. 실수/오류 상세 기록
3. `lessons-learned/` 또는 `errors/`에 저장
4. 관련 태그 추가

## Search & Reference

### Finding Past Mistakes

```bash
# 특정 태그 검색
grep -r "severity: critical" memory/

# 카테고리별 검색
find memory/errors/ -name "*.md"
find memory/lessons-learned/ -name "*.md"
```

### Before Making Decisions

1. 유사한 상황의 과거 실수 검색
2. 해결책 참조
3. 재발 방지 대책 확인

## Maintenance

- **Monthly Review**: 모든 기록 검토 및 관련성 업데이트
- **Quarterly Cleanup**: 해결된 문제와 재발 방지된 항목 아카이빙
- **Tag Update**: 새로운 카테고리나 유형이 필요할 때 태그 시스템 업데이트

---

## 📝 문서 정보

**작성자**: alfrad (MoAI Reviewer)
**생성일**: 2026-02-02
**목적**: GX10 프로젝트 지식 베이스 시스템
**버전**: 1.0.0
