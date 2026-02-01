# GX10 통합 가이드 및 실행 표준

## 문서 버전: 1.0
## 작성일: 2026-02-01

---

## 📋 목차

1. [문서 개요](#1-문서-개요)
2. [Execution Plan 완성](#2-execution-plan-완성)
3. [API 표준 명세](#3-api-표준-명세)
4. [실제 사용 시나리오](#4-실제-사용-시나리오)
5. [장애 대응 플레이북](#5-장애-대응-플레이북)
6. [보안 및 권한 관리](#6-보안-및-권한-관리)
7. [자동화 워크플로우](#7-자동화-워크플로우)
8. [운영 체크리스트](#8-운영-체크리스트)

---

## 1. 문서 개요

### 1.1 목적

본 문서는 기존 GX10 문서들(GX10-01~05)의 내용을 통합하고, 누락되거나 보완이 필요한 부분을 완성하여 실제 운영 가능한 **완전한 실행 표준**을 제공합니다.

### 1.2 문서 구조

| 섹션 | 내용 | 출처 |
|------|------|------|
| Execution Plan 완성 | JSON Schema, YAML 예시, 버전 관리 | GX10-02 보완 |
| API 표준 명세 | OpenAPI 3.0 기반 전체 API 명세 | GX10-02 보완 |
| 실제 사용 시나리오 | End-to-End 워크플로우 예시 3개 | 신규 작성 |
| 장애 대응 플레이북 | 4가지 시나리오별 대응 절차 | GX10-02 보완 |
| 보안 및 권한 관리 | RBAC, 로그 필터링, 네트워크 보안 | GX10-02 보완 |
| 자동화 워크플로우 | n8n 노드 정의, 예제 워크플로우 | 신규 작성 |
| 운영 체크리스트 | 일일/주간/월간 운영 점검 항목 | 신규 작성 |

### 1.3 사용 대상

- **시스템 관리자**: GX10 전체 시스템 운영
- **개발자**: Execution Plan 작성 및 Code Brain 활용
- **DevOps 엔지니어**: API 연동 및 자동화 구축
- **AI 연구자**: Vision Brain 성능 검증

---

## 2. Execution Plan 완성

### 2.1 Execution Plan 정의

> **Execution Plan**은 개발자 PC 또는 상위 AI(Claude Code)가 작성하며, GX10 Code Brain은 본 문서에 따라 **임의 판단 없이 실행만 수행**합니다.

### 2.2 JSON Schema v1.0

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "GX10 Execution Plan v1.0",
  "type": "object",
  "required": ["project_name", "version", "root_dir", "files", "tests"],
  "properties": {
    "project_name": {
      "type": "string",
      "description": "프로젝트 이름 (영문, 하이픈 허용)",
      "pattern": "^[a-zA-Z0-9_-]+$"
    },
    "version": {
      "type": "string",
      "description": "Execution Plan 버전 (semantic versioning)",
      "pattern": "^\\d+\\.\\d+\\.\\d+$"
    },
    "root_dir": {
      "type": "string",
      "description": "프로젝트 루트 절대 경로"
    },
    "description": {
      "type": "string",
      "description": "계획 설명 (선택사항)"
    },
    "constraints": {
      "type": "object",
      "properties": {
        "language": {
          "type": "string",
          "enum": ["python", "javascript", "typescript", "java", "cpp", "rust", "go"]
        },
        "framework": {
          "type": "string",
          "examples": ["fastapi", "django", "flask", "express", "spring", "gin"]
        },
        "python_version": {
          "type": "string",
          "pattern": "^3\\.[0-9]+$"
        },
        "style_guide": {
          "type": "string",
          "enum": ["pep8", "google", "numpy", "prettier", "eslint", "standard"]
        },
        "max_file_lines": {
          "type": "integer",
          "minimum": 100,
          "default": 500
        }
      },
      "required": ["language"]
    },
    "files": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "required": ["path", "responsibility"],
        "properties": {
          "path": {
            "type": "string",
            "description": "파일 상대 경로"
          },
          "responsibility": {
            "type": "string",
            "description": "파일이 담당할 기능·책임"
          },
          "dependencies": {
            "type": "array",
            "items": { "type": "string" },
            "description": "의존하는 다른 파일들의 상대 경로"
          },
          "test_target": {
            "type": "string",
            "description": "테스트 파일 경로"
          },
          "optional": {
            "type": "boolean",
            "default": false,
            "description": "필수 파일 여부"
          }
        }
      }
    },
    "tests": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "required": ["name", "command"],
        "properties": {
          "name": {
            "type": "string",
            "description": "테스트 이름 (예: unit, integration, e2e)"
          },
          "command": {
            "type": "string",
            "description": "테스트 실행 명령어"
          },
          "success_criteria": {
            "type": "object",
            "properties": {
              "exit_code": {
                "type": "integer",
                "default": 0
              },
              "min_coverage": {
                "type": "number",
                "minimum": 0,
                "maximum": 100,
                "default": 80
              },
              "timeout_seconds": {
                "type": "integer",
                "default": 300
              }
            }
          },
          "retry_on_failure": {
            "type": "object",
            "properties": {
              "enabled": { "type": "boolean", "default": true },
              "max_attempts": { "type": "integer", "default": 3 }
            }
          }
        }
      }
    },
    "implementation_order": {
      "type": "array",
      "items": { "type": "string" },
      "description": "파일 구현 순서 (path 배열)"
    },
    "quality_gates": {
      "type": "object",
      "properties": {
        "required_test_pass": { "type": "boolean", "default": true },
        "required_coverage": { "type": "number", "default": 85 },
        "forbidden_patterns": {
          "type": "array",
          "items": { "type": "string" },
          "description": "코드에 포함되면 안 될 패턴 (정규식)"
        }
      }
    },
    "metadata": {
      "type": "object",
      "properties": {
        "created_by": { "type": "string" },
        "created_at": { "type": "string", "format": "date-time" },
        "reviewer": { "type": "string" }
      }
    }
  }
}
```

### 2.3 YAML 예시 (실제 사용)

```yaml
# execution-plan-user-auth-v1.0.0.yaml

project_name: user-auth-service
version: "1.0.0"
root_dir: /workspace/user-auth-service
description: User authentication and profile management service

constraints:
  language: python
  framework: fastapi
  python_version: "3.11"
  style_guide: pep8
  max_file_lines: 500

files:
  - path: src/config.py
    responsibility: 환경 설정, 데이터베이스 연결 설정
    dependencies: []
    test_target: null
    optional: false

  - path: src/db/models.py
    responsibility: SQLAlchemy 모델 정의 (User, Profile)
    dependencies: []
    test_target: tests/db/test_models.py
    optional: false

  - path: src/db/repository.py
    responsibility: 데이터베이스 접근 계층 (DAO)
    dependencies: [src/db/models.py]
    test_target: tests/db/test_repository.py
    optional: false

  - path: src/auth/jwt.py
    responsibility: JWT 토큰 생성, 검증
    dependencies: []
    test_target: tests/auth/test_jwt.py
    optional: false

  - path: src/core/use_cases.py
    responsibility: 사용자 생성, 조회, 수정, 삭제 비즈니스 로직
    dependencies: [src/db/repository.py, src/auth/jwt.py]
    test_target: tests/core/test_use_cases.py
    optional: false

  - path: src/api/users.py
    responsibility: 사용자 관련 라우트 (GET /users, POST /users 등)
    dependencies: [src/core/use_cases.py]
    test_target: tests/api/test_users.py
    optional: false

  - path: src/main.py
    responsibility: FastAPI 애플리케이션 진입점, 라우터 등록
    dependencies: [src/api/users.py, src/config.py]
    test_target: tests/test_main.py
    optional: false

implementation_order:
  - src/config.py
  - src/db/models.py
  - src/db/repository.py
  - src/auth/jwt.py
  - src/core/use_cases.py
  - src/api/users.py
  - src/main.py

tests:
  - name: unit
    command: "pytest tests/ -v --tb=short"
    success_criteria:
      exit_code: 0
      min_coverage: 85
      timeout_seconds: 300
    retry_on_failure:
      enabled: true
      max_attempts: 3

  - name: integration
    command: "pytest tests/integration/ -v --tb=short"
    success_criteria:
      exit_code: 0
      timeout_seconds: 600

quality_gates:
  required_test_pass: true
  required_coverage: 85
  forbidden_patterns:
    - "^import os$"  # os.environ 대신 config.py 사용
    - "print\\("      # print 대신 logging 사용

metadata:
  created_by: "developer-name"
  created_at: "2026-02-01T18:00:00Z"
  reviewer: "tech-lead-name"
```

### 2.4 버전 관리 규칙

```
Execution Plan 버전은 프로젝트와 독립적으로 유지:

v1.0.0 → v1.0.1: 오타 수정, 설명 개선
v1.0.0 → v1.1.0: 파일/테스트 추가, 제약 조정
v1.0.0 → v2.0.0: 구조 변경, 파이프라인 재설계

- Git에서 `execution-plans/` 디렉토리로 관리
- 각 계획은 `execution-plans/{project_name}-{version}.yaml` 형태로 저장
- 최신 버전은 symlink로 `execution-plans/{project_name}-latest.yaml`
```

---

## 3. API 표준 명세

### 3.1 API 개요

GX10은 RESTful API를 통해 외부 시스템과 통신합니다. 모든 API는 JSON 형식의 요청/응답을 사용합니다.

**Base URL**: `http://gx10-brain.local:8080/api` (기본)

### 3.2 Brain 상태 조회 API

```yaml
GET /api/brain/status
```

**Response 200:**

```json
{
  "success": true,
  "data": {
    "active_brain": "code-brain",
    "health": "healthy",
    "container_status": {
      "cpu_usage_percent": 45.2,
      "memory_usage_mb": 12800,
      "gpu_usage_percent": 75.0,
      "gpu_memory_mb": 24576
    },
    "timestamp": "2026-02-01T19:00:00Z"
  },
  "meta": {
    "timestamp": "2026-02-01T19:00:00Z",
    "request_id": "req-abc123",
    "version": "1.0"
  }
}
```

### 3.3 Brain 전환 API

```yaml
POST /api/brain/switch
```

**Request Body:**

```json
{
  "target_brain": "code-brain",
  "reason": "Code implementation task",
  "force": false
}
```

**Response 200:**

```json
{
  "success": true,
  "data": {
    "result": "success",
    "target_brain": "code-brain",
    "estimated_duration_seconds": 10
  },
  "meta": {
    "timestamp": "2026-02-01T19:05:00Z",
    "request_id": "req-def456",
    "version": "1.0"
  }
}
```

### 3.4 작업 실행 API

```yaml
POST /api/task/execute
```

**Request Body:**

```json
{
  "task_type": "code_implementation",
  "payload": {
    "execution_plan_path": "/workspace/user-auth-service/execution-plan-v1.0.0.yaml"
  },
  "priority": "normal",
  "timeout_seconds": 3600,
  "callback_url": "https://myserver/webhook/task-complete"
}
```

**Response 202:**

```json
{
  "success": true,
  "data": {
    "task_id": "task-abc123",
    "status": "queued",
    "position_in_queue": 1,
    "estimated_wait_seconds": 5
  },
  "meta": {
    "timestamp": "2026-02-01T19:10:00Z",
    "request_id": "req-ghi789",
    "version": "1.0"
  }
}
```

### 3.5 작업 상태 조회 API

```yaml
GET /api/task/{task_id}
```

**Response 200 (Processing):**

```json
{
  "success": true,
  "data": {
    "task_id": "task-abc123",
    "status": "processing",
    "current_phase": "implementation",
    "progress": 60,
    "started_at": "2026-02-01T19:10:00Z"
  },
  "meta": {
    "timestamp": "2026-02-01T19:20:00Z",
    "request_id": "req-jkl012",
    "version": "1.0"
  }
}
```

**Response 200 (Success):**

```json
{
  "success": true,
  "data": {
    "task_id": "task-abc123",
    "status": "success",
    "result": {
      "output_dir": "/workspace/user-auth-service",
      "files_created": [
        "src/config.py",
        "src/db/models.py",
        "src/core/use_cases.py",
        "src/api/users.py",
        "src/main.py"
      ],
      "test_results": {
        "unit": {
          "exit_code": 0,
          "coverage": 88.5
        }
      },
      "duration_seconds": 1247
    },
    "completed_at": "2026-02-01T19:30:47Z"
  },
  "meta": {
    "timestamp": "2026-02-01T19:30:47Z",
    "request_id": "req-mno345",
    "version": "1.0"
  }
}
```

### 3.6 표준 에러 응답

```json
{
  "success": false,
  "error": {
    "code": 201,
    "name": "BRAIN_NOT_AVAILABLE",
    "message": "Vision Brain을 사용할 수 없음",
    "details": {
      "reason": "컨테이너 시작 실패",
      "container_logs": "/api/logs/vision-brain-startup-failure"
    }
  },
  "meta": {
    "timestamp": "2026-02-01T19:35:00Z",
    "request_id": "req-pqr678",
    "version": "1.0"
  }
}
```

---

## 4. 실제 사용 시나리오

### 4.1 시나리오 1: 소규모 신규 서비스 개발

**목표**: FastAPI 기반 사용자 인증 서비스 개발

#### Step 1: 개발자 PC - 요구사항 정의

```
기능:
- 사용자 회원가입 (POST /users)
- 이메일 검증
- JWT 기반 인증
- 사용자 프로필 조회/수정
```

#### Step 2: 개발자 PC - Execution Plan 작성

위 [2.3 YAML 예시](#23-yaml-예시-실제-사용) 참조

#### Step 3: GX10에 작업 제출

```bash
curl -X POST http://gx10-brain.local:8080/api/task/execute \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{
    "task_type": "code_implementation",
    "payload": {
      "execution_plan_path": "/workspace/user-auth-service/execution-plan-v1.0.0.yaml"
    },
    "priority": "normal",
    "timeout_seconds": 1800
  }'
```

#### Step 4: 작업 완료 대기

```bash
# 매 30초마다 확인
curl http://gx10-brain.local:8080/api/task/task-abc123
```

#### Step 5: 개발자 PC - 결과 검증

```bash
# 1. 생성된 코드 확인
ls -la /workspace/user-auth-service/src/

# 2. Claude에 코드 리뷰 요청
# 3. 로컬에서 테스트 실행
cd /workspace/user-auth-service
pytest tests/ -v

# 4. 리뷰 의견 반영 필요 시 Execution Plan 수정 후 재제출
```

### 4.2 시나리오 2: 대규모 리팩토링

**목표**: 기존 서비스의 모놀리식 구조를 마이크로서비스로 분리

#### Step 1: 기존 코드베이스 분석

```bash
# Claude Code로 기존 구조 분석
# 의존성 맵핑, 마이크로서비스 경계 식별
```

#### Step 2: Execution Plan 작성

```yaml
project_name: user-service-refactor
version: "2.0.0"
root_dir: /workspace/monolith-to-micro

files:
  # 1. 사용자 도메인 분리
  - path: services/user/src/models.py
    responsibility: 사용자 도메인 모델
  - path: services/user/src/repository.py
    responsibility: 사용자 데이터 접근

  # 2. 주문 도메인 분리
  - path: services/order/src/models.py
    responsibility: 주문 도메인 모델
  - path: services/order/src/events.py
    responsibility: 도메인 이벤트 정의

  # 3. API Gateway
  - path: gateway/src/routes.py
    responsibility: 라우팅, 인증 미들웨어

implementation_order:
  - services/user/src/models.py
  - services/user/src/repository.py
  - services/order/src/models.py
  - services/order/src/events.py
  - gateway/src/routes.py
```

#### Step 3: 점진적 마이그레이션

```bash
# Phase 1: 사용자 서비스 분리
curl -X POST http://gx10-brain.local:8080/api/task/execute \
  -d '{"task_type": "refactor", "execution_plan_path": "..."}'

# Phase 2: 주문 서비스 분리
# Phase 3: API Gateway 구현
```

### 4.3 시나리오 3: Vision Brain 성능 검증

**목표**: YOLOv8 vs YOLOv10 성능 비교

#### Step 1: Vision Brain 활성화

```bash
/gx10/api/switch.sh vision
```

#### Step 2: 벤치마크 Execution Plan 작성

```yaml
project_name: yolo-comparison
version: "1.0.0"
root_dir: /workspace/benchmarks

files:
  - path: benchmarks/yolo_comparison.py
    responsibility: YOLOv8 vs YOLOv10 latency/accuracy 비교
    dependencies: []

tests:
  - name: benchmark
    command: "python benchmarks/yolo_comparison.py"
    success_criteria:
      exit_code: 0
```

#### Step 3: 작업 제출 및 결과 분석

```bash
# Jupyter Notebook에서 결과 시각화
# http://gx10-brain.local:8888
```

---

## 5. 장애 대응 플레이북

### 5.1 Brain이 응답하지 않을 때

**증상**: API 호출 시 timeout (30초 이상)

#### 1단계: 확인

```bash
# Docker 컨테이너 상태 확인
docker ps | grep gx10

# 컨테이너 로그 확인
docker logs --tail 100 gx10-code-brain

# 시스템 리소스 확인
nvidia-smi
free -h
top -b -n1 | head -20
```

#### 2단계: 임시 조치 (30분 내)

```bash
# 시도 1: Brain 재시작
docker restart gx10-code-brain
# 2분 대기 후 상태 확인

# 시도 2: 캐시 정리 후 재시작
docker exec gx10-code-brain python -c "import torch; torch.cuda.empty_cache()"
docker restart gx10-code-brain

# 시도 3: 강제 종료 및 재생성
docker kill gx10-code-brain
/gx10/api/switch.sh code
```

#### 3단계: 진단 (실패 시)

```bash
# 로그 확인
tail -20 /gx10/runtime/logs/code-brain/ERROR-*.jsonl

# GPU 메모리 누수 확인
nvidia-smi -q -d MEMORY
```

### 5.2 Docker 컨테이너가 자주 재시작될 때

**증상**: 컨테이너가 10분마다 자동으로 재시작됨

#### 1단계: 원인별 대응

**OOM (Out of Memory)**
```bash
# 증상: "Killed" 또는 "OOM killer" 메시지
# 대응: 메모리 할당 증가
docker update gx10-code-brain --memory 80g

# 또는 모델 최적화
# - 낮은 precision 사용 (fp32 → fp16)
# - batch size 감소
```

**GPU Out of Memory**
```bash
# 증상: "RuntimeError: CUDA out of memory"
# 대응: GPU 메모리 정리 자동화 추가
# 배치 처리 크기 감소
```

### 5.3 실행 결과가 Execution Plan과 다를 때

**증상**: Code Brain이 생성한 파일 수, 테스트 결과가 계획과 불일치

#### 1단계: 확인

```bash
# 작업 ID 확인
curl http://gx10-brain.local:8080/api/task/{task_id}

# 상세 로그 다운로드
curl http://gx10-brain.local:8080/api/task/{task_id}/logs > task-logs.jsonl
```

#### 2단계: 대응

```bash
# 부분 재실행 (실패한 파일만)
# Execution Plan 수정 후 재제출

# 또는 전체 재실행 (다른 파라미터로)
# timeout 증가, batch 크기 조정 등
```

---

## 6. 보안 및 권한 관리

### 6.1 API 인증

**방식**: JWT Bearer Token

```bash
# 토큰 발급
curl -X POST http://gx10-brain.local:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "..."}'

# 토큰 사용
curl -H "Authorization: Bearer {token}" \
  http://gx10-brain.local:8080/api/brain/status
```

### 6.2 역할 기반 접근 제어 (RBAC)

| 역할 | 권한 |
|------|------|
| **developer** | 작업 제출, 상태 조회 |
| **data_scientist** | Vision Brain 전환, 벤치마크 실행 |
| **admin** | 모든 API 접근 |
| **ci_cd** | 작업 제출 (긴 timeout) |

### 6.3 로그 필터링

```python
# 민감 정보 마스킹
MASK_PATTERNS = [
    (r"password.*=.*", "password=***"),
    (r"api_key.*=.*", "api_key=***"),
    (r"/home/.*?/", "/home/***/"),
]
```

---

## 7. 자동화 워크플로우

### 7.1 n8n 기본 워크플로우

```
[Webhook Trigger] → [Parse Request] → [Validate Plan] →
[Check Status] → [Switch Brain if needed] → [Submit Task] →
[Poll Status] → [Notification] → [Update PM Tool]
```

### 7.2 GitHub Push 자동화

```bash
# GitHub Webhook → n8n → GX10 Code Brain
# 1. 코드 푸시 감지
# 2. Execution Plan 자동 생성
# 3. Code Brain에 제출
# 4. 결과를 Slack에 알림
```

---

## 8. 운영 체크리스트

### 8.1 일일 운영 (Daily)

- [ ] Brain 상태 확인 (`/gx10/api/status.sh`)
- [ ] 디스크 용량 확인 (`df -h`)
- [ ] GPU 메모리 확인 (`nvidia-smi`)
- [ ] 에러 로그 확인 (`tail -20 /gx10/runtime/logs/*/*.jsonl`)
- [ ] 진행 중인 작업 확인

### 8.2 주간 운영 (Weekly)

- [ ] 백업 실행 상태 확인
- [ ] Execution Plan 이력 정리
- [ ] 모델 업데이트 확인
- [ ] 성능 메트릭 분석
- [ ] 보안 패치 확인

### 8.3 월간 운영 (Monthly)

- [ ] 전체 시스템 보안 감사
- [ ] 모델 성능 벤치마크 재실행
- [ ] 문서 업데이트
- [ ] 비용 분석
- [ ] 운영 개선 계획 수립

---

## 부록

### A. 빠른 참조 명령어

```bash
# 상태 확인
/gx10/api/status.sh

# Brain 전환
/gx10/api/switch.sh code     # Code Brain
/gx10/api/switch.sh vision   # Vision Brain
/gx10/api/switch.sh none     # 모두 정지

# Ollama 직접 접근
ollama list
ollama ps
ollama run qwen2.5-coder:32b
```

### B. 포트 참조

| 서비스 | 포트 | 용도 |
|--------|------|------|
| Ollama API | 11434 | LLM 추론 |
| Open WebUI | 8080 | 웹 채팅 |
| Jupyter Lab | 8888 | Vision 노트북 |
| n8n | 5678 | 워크플로우 |
| GX10 API | 8080 | Brain 제어 |

### C. 라이선스

| 구성요소 | 라이선스 |
|----------|----------|
| Qwen2.5-Coder | Apache 2.0 |
| Qwen2.5-VL | Apache 2.0 |
| Ollama | MIT |
| n8n | Sustainable Use |

---

## 📜 수정 이력

문서의 주요 수정 사항을 기록합니다.

| 일자 | 버전 | 설명 | 리뷰어 |
|------|------|------|--------|
| 2026-02-01 | 1.0 | 통합 가이드 및 실행 표준 초안 작성 | drake |

---

## 📝 문서 정보

**작성자**:

- AI: Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)
- 환경: MoAI-ADK v11.0.0 (Claude Code + Korean Language Support)
- 작성일: 2026-02-01

**리뷰어**:

- drake

**문서 버전**: 1.0

**최종 수정**: 2026-02-01

**상태**: 완료

본 문서는 GX10 프로젝트의 통합 운영 가이드로, 기존 문서들의 내용을 완성하고 실제 운영에 필요한 모든 표준을 포함합니다.
