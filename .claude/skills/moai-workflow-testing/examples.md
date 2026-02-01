# Development Workflow Testing Examples

실용적인 예시를 통해 DDD, 디버깅, 성능 최적화, 코드 리뷰 워크플로우를 학습합니다.

---

## Example 1: DDD 사이클 실행 (RED-GREEN-REFACTOR)

**Scenario**: 사용자 인증 기능을 DDD 방식으로 개발

**Input**:
```python
from moai_workflow_testing import DDDManager, TestSpecification, TestType

# DDD 매니저 초기화
ddd_manager = DDDManager(
    project_path="/project/src",
    context7_client=context7
)

# 테스트 스펙 정의
test_spec = TestSpecification(
    name="test_user_authentication",
    description="Test user authentication with valid credentials",
    test_type=TestType.UNIT,
    requirements=[
        "Valid email format required",
        "Password minimum 8 characters",
        "Return JWT token on success"
    ],
    acceptance_criteria=[
        "Valid credentials return access_token and refresh_token",
        "Invalid credentials return 401 Unauthorized",
        "Missing fields return 400 Bad Request"
    ]
)

# DDD 사이클 실행
cycle_results = await ddd_manager.run_full_ddd_cycle(
    specification=test_spec,
    target_function="authenticate_user"
)
```

**Output**:
```json
{
  "tdd_cycle": {
    "phase": "completed",
    "iterations": 3
  },
  "red_phase": {
    "status": "completed",
    "tests_generated": 5,
    "tests": [
      {
        "name": "test_authenticate_valid_credentials",
        "status": "FAIL",
        "reason": "authenticate_user not implemented"
      },
      {
        "name": "test_authenticate_invalid_password",
        "status": "FAIL",
        "reason": "authenticate_user not implemented"
      },
      {
        "name": "test_authenticate_missing_email",
        "status": "FAIL",
        "reason": "authenticate_user not implemented"
      },
      {
        "name": "test_authenticate_returns_jwt",
        "status": "FAIL",
        "reason": "authenticate_user not implemented"
      },
      {
        "name": "test_authenticate_token_expiry",
        "status": "FAIL",
        "reason": "authenticate_user not implemented"
      }
    ]
  },
  "green_phase": {
    "status": "completed",
    "implementation_file": "src/auth/service.py",
    "tests_passing": 5,
    "tests_failing": 0
  },
  "refactor_phase": {
    "status": "completed",
    "improvements": [
      "Extracted password hashing to separate function",
      "Added type hints to all functions",
      "Simplified token generation logic"
    ],
    "tests_still_passing": true
  },
  "coverage": {
    "total": 92,
    "threshold": 85,
    "status": "PASS"
  },
  "context7_patterns_applied": [
    "JWT best practices 2025",
    "Password hashing with bcrypt",
    "Secure token storage patterns"
  ]
}
```

```python
# 생성된 테스트 코드 (RED Phase)
# tests/test_auth_service.py

import pytest
from src.auth.service import authenticate_user
from src.auth.exceptions import InvalidCredentialsError

class TestAuthentication:
    @pytest.fixture
    def valid_user(self, db_session):
        return create_test_user(
            email="test@example.com",
            password="SecurePass123!"
        )

    async def test_authenticate_valid_credentials(self, valid_user):
        """Valid credentials should return tokens."""
        result = await authenticate_user(
            email="test@example.com",
            password="SecurePass123!"
        )

        assert "access_token" in result
        assert "refresh_token" in result
        assert result["token_type"] == "bearer"

    async def test_authenticate_invalid_password(self, valid_user):
        """Invalid password should raise error."""
        with pytest.raises(InvalidCredentialsError):
            await authenticate_user(
                email="test@example.com",
                password="WrongPassword"
            )

    async def test_authenticate_missing_email(self):
        """Missing email should raise validation error."""
        with pytest.raises(ValueError):
            await authenticate_user(
                email="",
                password="SecurePass123!"
            )
```

**Explanation**: DDD 매니저는 Context7에서 최신 패턴을 가져와 RED(실패하는 테스트 생성) → GREEN(테스트 통과하는 구현) → REFACTOR(코드 개선) 사이클을 자동으로 수행합니다. 커버리지 85% 이상을 보장합니다.

---

## Example 2: AI 기반 디버깅

**Scenario**: 프로덕션 에러를 AI로 분석하고 해결책 제시

**Input**:
```python
from moai_workflow_testing import AIDebugger

# AI 디버거 초기화
debugger = AIDebugger(context7_client=context7)

# 에러 발생 상황
try:
    result = await process_payment(order_id="ORD-123")
except Exception as e:
    # AI 디버깅 실행
    analysis = await debugger.debug_with_context7_patterns(
        exception=e,
        context={
            "file": "src/payments/processor.py",
            "function": "process_payment",
            "order_id": "ORD-123"
        },
        project_path="/project/src"
    )
```

**Output**:
```json
{
  "error_analysis": {
    "exception_type": "ConnectionResetError",
    "message": "Connection reset by peer during payment gateway request",
    "location": {
      "file": "src/payments/processor.py",
      "line": 142,
      "function": "process_payment"
    },
    "classification": {
      "category": "network",
      "severity": "high",
      "is_transient": true
    }
  },
  "root_cause": {
    "primary": "Payment gateway connection timeout without retry mechanism",
    "contributing_factors": [
      "No connection pooling configured",
      "Missing circuit breaker pattern",
      "Insufficient timeout settings"
    ]
  },
  "solutions": [
    {
      "priority": 1,
      "title": "Add retry mechanism with exponential backoff",
      "description": "Implement tenacity retry for transient network failures",
      "code_suggestion": "```python\nfrom tenacity import retry, stop_after_attempt, wait_exponential\n\n@retry(\n    stop=stop_after_attempt(3),\n    wait=wait_exponential(multiplier=1, min=4, max=10)\n)\nasync def process_payment(order_id: str):\n    ...\n```",
      "effort": "low",
      "impact": "high"
    },
    {
      "priority": 2,
      "title": "Implement circuit breaker pattern",
      "description": "Add circuit breaker to prevent cascade failures",
      "code_suggestion": "Use pybreaker library with 5-failure threshold",
      "effort": "medium",
      "impact": "high"
    },
    {
      "priority": 3,
      "title": "Configure connection pooling",
      "description": "Use httpx with connection pool for better resource management",
      "effort": "low",
      "impact": "medium"
    }
  ],
  "context7_references": [
    "Python retry patterns 2025",
    "Circuit breaker best practices",
    "httpx connection pooling guide"
  ],
  "related_errors": [
    {
      "file": "src/payments/gateway.py",
      "similar_issue": true,
      "recommendation": "Apply same fix"
    }
  ]
}
```

**Explanation**: AI 디버거는 예외를 분류하고, 근본 원인을 분석하며, Context7에서 최신 해결 패턴을 가져와 우선순위별 해결책을 제시합니다. 코드 제안과 노력/영향 평가가 포함됩니다.

---

## Example 3: 자동화된 코드 리뷰 (TRUST 5)

**Scenario**: PR 전 코드베이스에 대한 포괄적인 품질 검사

**Input**:
```python
from moai_workflow_testing import AutomatedCodeReviewer

# 코드 리뷰어 초기화
reviewer = AutomatedCodeReviewer(context7_client=context7)

# 코드베이스 리뷰 실행
review_report = await reviewer.review_codebase(
    project_path="/project/src",
    changed_files=[
        "src/auth/service.py",
        "src/auth/router.py",
        "src/models/user.py"
    ],
    review_config={
        "trust_score_min": 0.85,
        "check_security": True,
        "check_performance": True,
        "check_maintainability": True
    }
)
```

**Output**:
```json
{
  "review_summary": {
    "overall_trust_score": 0.87,
    "status": "APPROVED_WITH_SUGGESTIONS",
    "files_reviewed": 3,
    "total_issues": 8,
    "critical_issues": 0,
    "major_issues": 2,
    "minor_issues": 6
  },
  "trust_5_breakdown": {
    "test_first": {
      "score": 0.92,
      "status": "PASS",
      "coverage": "92%",
      "details": "All new functions have corresponding tests"
    },
    "readable": {
      "score": 0.85,
      "status": "PASS",
      "issues": [
        {
          "file": "src/auth/service.py",
          "line": 45,
          "issue": "Function 'proc_auth' should use descriptive name",
          "suggestion": "Rename to 'process_authentication'"
        }
      ]
    },
    "unified": {
      "score": 0.90,
      "status": "PASS",
      "details": "Code formatting consistent with project standards"
    },
    "secured": {
      "score": 0.82,
      "status": "PASS",
      "issues": [
        {
          "file": "src/auth/router.py",
          "line": 23,
          "issue": "Missing rate limiting on login endpoint",
          "severity": "major",
          "suggestion": "Add @limiter.limit('5/minute') decorator"
        },
        {
          "file": "src/auth/service.py",
          "line": 67,
          "issue": "Password logged in debug mode",
          "severity": "major",
          "suggestion": "Remove password from log statement"
        }
      ]
    },
    "trackable": {
      "score": 0.88,
      "status": "PASS",
      "details": "Commit messages follow conventional format"
    }
  },
  "performance_analysis": {
    "bottlenecks_detected": 1,
    "issues": [
      {
        "file": "src/models/user.py",
        "line": 34,
        "issue": "N+1 query in user permissions loading",
        "suggestion": "Use selectinload for eager loading"
      }
    ]
  },
  "maintainability_score": 0.85,
  "recommendations": [
    "Add type hints to 3 functions",
    "Extract duplicate code in authentication flow",
    "Add docstrings to public methods"
  ],
  "auto_fixable": [
    {
      "file": "src/auth/service.py",
      "fix": "Add type hints",
      "apply_command": "moai-workflow fix --file src/auth/service.py --type hints"
    }
  ]
}
```

**Explanation**: TRUST 5 프레임워크(Test-first, Readable, Unified, Secured, Trackable)를 기준으로 코드를 분석합니다. 보안 이슈(비밀번호 로깅, 레이트 리밋 누락)와 성능 문제(N+1 쿼리)를 식별하고, 자동 수정 가능한 항목을 표시합니다.

---

## Common Patterns

### Pattern 1: CI/CD 통합

GitHub Actions와 워크플로우를 통합하는 패턴입니다.

```yaml
# .github/workflows/development-workflow.yml
name: Development Workflow

on: [push, pull_request]

jobs:
  quality-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.13'

      - name: Install dependencies
        run: uv sync

      - name: Run Development Workflow
        run: |
          moai-workflow execute \
            --project . \
            --mode ci \
            --quality-gates strict \
            --output workflow-results.json

      - name: Check Quality Gates
        run: |
          python -c "
          import json
          with open('workflow-results.json') as f:
              results = json.load(f)
          if results['trust_score'] < 0.85:
              exit(1)
          if results['critical_issues'] > 0:
              exit(1)
          "

      - name: Upload Results
        uses: actions/upload-artifact@v4
        with:
          name: workflow-results
          path: workflow-results.json
```

### Pattern 2: 성능 프로파일링

함수 단위 성능 분석 패턴입니다.

```python
from moai_workflow_testing import PerformanceProfiler

# 프로파일러 초기화
profiler = PerformanceProfiler(context7_client=context7)

# 프로파일링 시작
profiler.start_profiling(
    profile_types=['cpu', 'memory', 'line'],
    sample_interval=0.001
)

# 대상 코드 실행
result = expensive_function()

# 프로파일링 종료 및 분석
profile_results = profiler.stop_profiling()
bottlenecks = await profiler.detect_bottlenecks(profile_results)

# 결과
print(f"총 실행 시간: {profile_results['total_time']:.2f}s")
print(f"피크 메모리: {profile_results['peak_memory']}MB")
print(f"병목 지점: {len(bottlenecks)}개")

for bottleneck in bottlenecks:
    print(f"  - {bottleneck['location']}: {bottleneck['issue']}")
    print(f"    제안: {bottleneck['suggestion']}")
```

### Pattern 3: 엔터프라이즈 품질 게이트

다단계 품질 검증 패턴입니다.

```python
from moai_workflow_testing import QualityGateManager

# 품질 게이트 설정
quality_config = {
    "pre_commit": {
        "lint": {"enabled": True, "fail_on_warning": False},
        "format": {"enabled": True, "auto_fix": True}
    },
    "pre_push": {
        "unit_tests": {"enabled": True, "min_coverage": 85},
        "type_check": {"enabled": True}
    },
    "ci_pipeline": {
        "integration_tests": {"enabled": True},
        "security_scan": {"enabled": True, "fail_on_high": True},
        "performance_test": {"enabled": True, "regression_threshold": 10}
    },
    "pre_deploy": {
        "e2e_tests": {"enabled": True},
        "approval_required": True
    }
}

gate_manager = QualityGateManager(quality_config)

# 특정 단계 검증
result = await gate_manager.validate_workflow_stage(
    stage="ci_pipeline",
    artifacts={
        "test_results": test_output,
        "coverage_report": coverage_data,
        "security_scan": security_results
    }
)

if not result['passed']:
    print("품질 게이트 실패:")
    for validation in result['validations'].values():
        if validation['status'] != 'passed':
            print(f"  - {validation['name']}: {validation['reason']}")
```

---

## Anti-Patterns (피해야 할 패턴)

### Anti-Pattern 1: 테스트 없이 리팩토링

**Problem**: 테스트 없이 코드 리팩토링 수행

```python
# 잘못된 예시 - 테스트 없음
def refactor_auth_module():
    # 테스트 없이 직접 수정
    rewrite_authentication_logic()
    # → 회귀 버그 위험
    # → 동작 변경 감지 불가
```

**Solution**: DDD 사이클 내에서 리팩토링

```python
# 올바른 예시 - DDD 기반
async def refactor_auth_module():
    # 1. 기존 테스트 확인
    existing_tests = await run_tests("tests/test_auth.py")
    assert existing_tests.all_passing

    # 2. 리팩토링 수행
    apply_refactoring()

    # 3. 테스트 재실행
    after_tests = await run_tests("tests/test_auth.py")
    assert after_tests.all_passing

    # 4. 커버리지 확인
    assert after_tests.coverage >= 85
```

### Anti-Pattern 2: 디버그 로그 프로덕션 배포

**Problem**: 민감한 정보가 포함된 디버그 로그를 프로덕션에 배포

```python
# 잘못된 예시 - 민감 정보 로깅
def authenticate(email: str, password: str):
    logger.debug(f"Login attempt: {email}, password: {password}")  # 위험!
    # ...
```

**Solution**: AI 코드 리뷰로 감지 및 수정

```python
# 올바른 예시 - 안전한 로깅
def authenticate(email: str, password: str):
    logger.info(f"Login attempt for user: {email}")  # 이메일만
    # 비밀번호는 절대 로깅하지 않음

# 코드 리뷰에서 자동 감지
review = await reviewer.review_codebase(project_path)
# → "Password logged in debug mode" 이슈 검출
```

### Anti-Pattern 3: 성능 테스트 생략

**Problem**: 성능 임계값 없이 배포

```python
# 잘못된 예시 - 성능 검증 없음
def deploy():
    run_unit_tests()
    run_integration_tests()
    deploy_to_production()
    # → 성능 회귀 감지 불가
```

**Solution**: 성능 게이트 포함

```python
# 올바른 예시 - 성능 검증 포함
async def deploy():
    run_unit_tests()
    run_integration_tests()

    # 성능 테스트
    perf_results = await profiler.run_benchmark(
        baseline="production",
        threshold={"response_time": 100, "memory": 512}
    )

    if perf_results.regression > 10:  # 10% 이상 저하
        raise PerformanceRegressionError(perf_results)

    deploy_to_production()
```

### Anti-Pattern 4: 수동 코드 리뷰만 의존

**Problem**: 자동화 없이 수동 리뷰만 수행

```python
# 잘못된 예시 - 수동만
def code_review_process():
    # 팀원이 모든 것을 수동으로 검토
    # → 일관성 부족
    # → 보안 이슈 누락 가능
    # → 시간 소요 큼
    pass
```

**Solution**: 자동화 + 수동 리뷰 조합

```python
# 올바른 예시 - 하이브리드
async def code_review_process():
    # 1. 자동화 리뷰 (보안, 성능, 스타일)
    auto_review = await reviewer.review_codebase(project_path)

    # 2. 자동 수정 가능한 이슈 처리
    for fix in auto_review.auto_fixable:
        apply_fix(fix)

    # 3. 수동 리뷰 필요 항목 표시
    if auto_review.critical_issues:
        request_manual_review(auto_review.critical_issues)

    # 4. 품질 게이트 확인
    if auto_review.trust_score >= 0.85:
        approve_pr()
```

---

## CLI Quick Reference

```bash
# 전체 워크플로우 실행
moai-workflow execute --project /project/src --mode full

# 개별 컴포넌트 실행
moai-workflow debug --file app.py --error "AttributeError"
moai-workflow refactor --directory src/ --max-risk medium
moai-workflow profile --target function_name --types cpu,memory
moai-workflow test --spec user_auth.spec --mode ddd
moai-workflow review --project /project/src --trust-score-min 0.8

# CI 모드
moai-workflow ci --commit abc123 --quality-gates strict
```

---

## Quality Metrics

| 메트릭 | 임계값 | 설명 |
|--------|--------|------|
| 테스트 커버리지 | >= 85% | 최소 코드 커버리지 |
| TRUST 점수 | >= 0.85 | 5개 품질 기준 종합 |
| Critical 이슈 | 0 | 치명적 보안/버그 |
| 성능 회귀 | < 10% | 기준 대비 저하 허용 |
| 응답 시간 | < 100ms | API 응답 시간 |

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

