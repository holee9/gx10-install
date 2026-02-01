# MoAI Foundation Core Examples

실용적인 예시를 통해 MoAI Foundation Core의 6가지 핵심 원칙을 학습합니다.

---

## Example 1: TRUST 5 Quality Gate 적용

**Scenario**: 새로운 기능을 개발한 후 TRUST 5 품질 게이트를 통과시키는 상황

**Input**:
```python
# 개발된 코드에 TRUST 5 검증 요청
Task(
    subagent_type="core-quality",
    prompt="Validate code quality using TRUST 5 framework",
    context={
        "target_path": "/src/features/user_auth.py",
        "validation_level": "strict"
    }
)
```

**Output**:
```markdown
TRUST 5 Validation Report
=========================

Test-first: PASS (87% coverage, threshold: 85%)
Readable: PASS (naming conventions compliant)
Unified: PASS (black + isort formatting verified)
Secured: PASS (no OWASP vulnerabilities detected)
Trackable: PASS (commit messages follow conventional format)

Overall Status: APPROVED for merge
```

**Explanation**: TRUST 5의 5가지 품질 기준(Test-first, Readable, Unified, Secured, Trackable)을 자동으로 검증하여 코드 품질을 보장합니다. 85% 이상 테스트 커버리지, 일관된 코드 스타일, 보안 취약점 부재를 확인합니다.

---

## Example 2: SPEC-First DDD 3단계 워크플로우

**Scenario**: 사용자 인증 기능을 SPEC-First DDD 방식으로 개발하는 전체 과정

**Input**:
```bash
# Phase 1: SPEC 생성
/moai:1-plan "JWT 기반 사용자 인증 시스템 구현"

# Phase 2: DDD 실행 (Phase 1 완료 후 /clear 실행)
/clear
/moai:2-run SPEC-001

# Phase 3: 문서화
/moai:3-sync SPEC-001
```

**Output**:
```markdown
Phase 1 Result (.moai/specs/SPEC-001/spec.md):
==============================================
ID: SPEC-001
Title: JWT Authentication System
EARS Format:
- [Ubiquitous] System shall hash passwords using bcrypt
- [Event-driven] When user submits credentials, system shall validate and return JWT
- [State-driven] While token is valid, user shall access protected resources
- [Unwanted] System shall not store plain-text passwords
Token Usage: 28K/30K

Phase 2 Result:
===============
ANALYZE: Requirements analyzed, 5 acceptance criteria identified
PRESERVE: Existing behavior protected, characterization tests created
IMPROVE: Implementation complete, code optimized
Coverage: 92% (threshold: 85%)
Token Usage: 165K/180K

Phase 3 Result:
===============
API Documentation: Generated (docs/api/auth.md)
Architecture Diagram: Created (docs/diagrams/auth-flow.mermaid)
Token Usage: 35K/40K
```

**Explanation**: SPEC-First DDD는 3단계로 진행됩니다. Phase 1에서 EARS 형식으로 요구사항을 정의하고, Phase 2에서 ANALYZE-PRESERVE-IMPROVE 사이클로 구현하며, Phase 3에서 문서를 생성합니다. 각 Phase 사이에 /clear를 실행하여 토큰을 절약합니다.

---

## Example 3: 에이전트 위임 패턴 (복잡한 작업)

**Scenario**: 10개 이상의 파일이 관련된 복잡한 마이크로서비스 개발

**Input**:
```python
# 복잡한 작업: 순차 + 병렬 위임 조합
async def develop_microservice():
    # Phase 1: 순차 실행 (의존성 있음)
    design = await Task(
        subagent_type="api-designer",
        prompt="Design REST API for order management service"
    )

    # Phase 2: 병렬 실행 (독립적)
    backend, frontend, tests = await Promise.all([
        Task(
            subagent_type="backend-expert",
            prompt="Implement API endpoints",
            context={"design": design}
        ),
        Task(
            subagent_type="frontend-expert",
            prompt="Create admin dashboard UI",
            context={"design": design}
        ),
        Task(
            subagent_type="ddd-implementer",
            prompt="Generate integration tests",
            context={"design": design}
        )
    ])

    # Phase 3: 최종 검증
    validation = await Task(
        subagent_type="core-quality",
        prompt="Validate complete implementation",
        context={"components": [backend, frontend, tests]}
    )

    return validation
```

**Output**:
```markdown
Delegation Report
=================

Phase 1 (Sequential):
- api-designer: Completed in 45s
  - 12 endpoints designed
  - OpenAPI spec generated

Phase 2 (Parallel - 3 agents):
- backend-expert: Completed in 120s
  - 8 API handlers implemented
  - Database models created
- frontend-expert: Completed in 90s
  - 6 React components created
  - Admin dashboard ready
- ddd-implementer: Completed in 75s
  - 24 integration tests generated
  - Mock data prepared

Phase 3 (Validation):
- core-quality: TRUST 5 PASSED
  - Coverage: 89%
  - No security issues
  - Code style compliant

Total Time: 195s (vs 330s sequential)
Efficiency Gain: 41%
```

**Explanation**: 복잡한 작업은 순차/병렬 위임을 조합합니다. 의존성이 있는 작업(API 설계)은 먼저 순차 실행하고, 독립적인 작업(백엔드, 프론트엔드, 테스트)은 병렬로 실행하여 전체 시간을 41% 단축합니다.

---

## Common Patterns

### Pattern 1: Token Budget 관리

토큰 예산을 효율적으로 관리하는 패턴입니다.

```python
# SPEC Phase: 30K 예산
Task(subagent_type="workflow-spec", prompt="Create SPEC")
# → SPEC 완료 후 반드시 /clear 실행 (45-50K 절약)

# DDD Phase: 180K 예산
Task(subagent_type="ddd-implementer", prompt="Implement with DDD")
# → 선택적 파일 로딩, 필요한 파일만 로드

# Docs Phase: 40K 예산
Task(subagent_type="workflow-docs", prompt="Generate documentation")
# → 결과 캐싱 및 템플릿 재사용
```

모니터링 방법:
- /context 명령으로 현재 토큰 사용량 확인
- 150K 초과 시 /clear 권장
- 50+ 메시지 후 컨텍스트 초기화 고려

### Pattern 2: Progressive Disclosure 구조

스킬 문서를 3단계로 구조화하는 패턴입니다.

```markdown
## Quick Reference (30초, ~1000 토큰)
- 핵심 개념만 포함
- 즉시 사용 가능한 정보

## Implementation Guide (5분, ~3000 토큰)
- 단계별 워크플로우
- 실용적인 예시

## Advanced Patterns (10+분, ~5000 토큰)
- 심층 기술 정보
- 엣지 케이스 처리
```

파일 분리 기준:
- SKILL.md: 500줄 이하 (핵심 내용)
- modules/: 상세 내용 (무제한)
- examples.md: 실행 가능한 예시

### Pattern 3: 조건부 위임 (분석 기반)

문제 유형에 따라 적절한 에이전트를 선택하는 패턴입니다.

```python
# 먼저 문제 분석
analysis = await Task(
    subagent_type="debug-helper",
    prompt="Analyze the error and classify type"
)

# 분석 결과에 따라 위임
if analysis.type == "security":
    await Task(subagent_type="security-expert", prompt="Fix security issue")
elif analysis.type == "performance":
    await Task(subagent_type="performance-expert", prompt="Optimize performance")
elif analysis.type == "logic":
    await Task(subagent_type="backend-expert", prompt="Fix business logic")
else:
    await Task(subagent_type="debug-expert", prompt="General debugging")
```

---

## Anti-Patterns (피해야 할 패턴)

### Anti-Pattern 1: 직접 실행

**Problem**: Alfred가 에이전트 위임 없이 직접 코드를 작성하거나 수정함

```python
# 잘못된 예시
def alfred_direct_execution():
    # Alfred가 직접 파일 수정 - 절대 금지!
    with open("src/app.py", "w") as f:
        f.write("# Direct modification")
```

**Solution**: 모든 작업은 전문 에이전트에게 위임

```python
# 올바른 예시
await Task(
    subagent_type="backend-expert",
    prompt="Modify src/app.py to add new feature",
    context={"requirements": feature_spec}
)
```

### Anti-Pattern 2: Phase 간 /clear 누락

**Problem**: SPEC Phase 완료 후 /clear 없이 DDD Phase 진행하여 토큰 낭비

```bash
# 잘못된 예시
/moai:1-plan "feature"  # 30K 사용
/moai:2-run SPEC-001    # 이전 컨텍스트 유지 → 토큰 부족!
```

**Solution**: Phase 완료 후 반드시 /clear 실행

```bash
# 올바른 예시
/moai:1-plan "feature"  # 30K 사용
/clear                  # 컨텍스트 초기화 (45-50K 절약)
/moai:2-run SPEC-001    # 새로운 180K 예산으로 시작
```

### Anti-Pattern 3: 과도한 순차 실행

**Problem**: 독립적인 작업을 불필요하게 순차 실행

```python
# 잘못된 예시 - 비효율적
backend = await Task(subagent_type="backend-expert", ...)
frontend = await Task(subagent_type="frontend-expert", ...)  # 대기 불필요
docs = await Task(subagent_type="docs-generator", ...)       # 대기 불필요
```

**Solution**: 독립적인 작업은 병렬 실행

```python
# 올바른 예시 - 효율적
backend, frontend, docs = await Promise.all([
    Task(subagent_type="backend-expert", ...),
    Task(subagent_type="frontend-expert", ...),
    Task(subagent_type="docs-generator", ...)
])
```

### Anti-Pattern 4: TRUST 5 검증 생략

**Problem**: 품질 게이트 없이 코드 머지

```bash
# 잘못된 예시
git add . && git commit -m "Add feature" && git push
# → 테스트 커버리지, 보안 취약점 미확인
```

**Solution**: 머지 전 반드시 TRUST 5 검증

```python
# 올바른 예시
validation = await Task(
    subagent_type="core-quality",
    prompt="Validate with TRUST 5 before merge"
)

if validation.passed:
    # 안전하게 머지
    await Task(subagent_type="git-manager", prompt="Create PR and merge")
else:
    # 이슈 해결 후 재검증
    await Task(subagent_type="debug-expert", prompt="Fix validation issues")
```

---

## Quick Decision Matrix

작업 복잡도에 따른 에이전트 선택 가이드:

| 복잡도 | 파일 수 | 에이전트 수 | 실행 패턴 |
|--------|---------|------------|----------|
| Simple | 1개 | 1-2개 | 순차 |
| Medium | 3-5개 | 2-3개 | 순차 |
| Complex | 10+개 | 5+개 | 순차+병렬 혼합 |

토큰 예산 배분:

| Phase | 예산 | 전략 |
|-------|------|------|
| SPEC | 30K | 요구사항만 로드 |
| DDD | 180K | 선택적 파일 로딩 |
| Docs | 40K | 결과 캐싱 |
| Total | 250K | Phase 분리 |

---

Version: 1.0.0
Last Updated: 2025-12-06
---

## 📝 문서 정보

**작성자**:

- AI: Claude Sonnet 4.5
- 환경: MoAI-ADK v11.0.0
- 작성일: 2026-02-01

**리뷰어**:

- drake

