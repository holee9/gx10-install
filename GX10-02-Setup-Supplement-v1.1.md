# GX10 로컬 AI 개발 환경 구축 가이드
  
## v1.0 보완 지침서 (v1.1 준비용)

**작성일:** 2026-02-01  
**상태:** 보완 지침서 초안  
**목적:** GX10 Setup Plan v1.0의 구현 가능성 80~85% → 90%+ 상향 조정

---

## 📋 목차

1. [전반적 평가](#1-전반적-평가)
2. [보완 필요 영역 - 우선순위별](#2-보완-필요-영역---우선순위별)
3. [세부 보완 항목 및 실행 방안](#3-세부-보완-항목-및-실행-방안)
4. [구현 템플릿 및 예시](#4-구현-템플릿-및-예시)
5. [체크리스트](#5-체크리스트)

---

## 1. 전반적 평가

### 1.1 현황 평가

| 평가 항목 | 등급 | 설명 |
|--------|------|------|
| **아키텍처 방향성** | ⭐⭐⭐⭐⭐ (90%) | 개발자 PC / GX10 / n8n·MCP 3분리, Code Brain/Vision Brain 2-구조 모두 업계 관행과 일치하며 현실적 |
| **역할 정의** | ⭐⭐⭐⭐⭐ (90%) | 각 컴포넌트의 책임과 한계가 명확, 품질 통제 방어선이 타당함 |
| **기술 스택 타당성** | ⭐⭐⭐⭐ (85%) | DeepSeek/Qwen + Docker + LoRA/QLoRA 조합은 현실적이나, 모델별 스펙 정의 필요 |
| **리소스 요구사항** | ⭐⭐⭐⭐ (80%) | RAM/VRAM 수치는 타당하나, "필수 최소"와 "권장" 구분 필요 |
| **운영 정책 구체성** | ⭐⭐⭐ (65%) | **가장 보완 필요** - API 명세, Brain 전환 정책, 에러 처리 등 미흡 |
| **모니터링/백업** | ⭐⭐⭐ (60%) | **보완 필요** - 로그 정책, 백업 대상, 복구 절차 미정의 |
| **전체 구현 가능성** | **80~85%** | 세부 보완 시 90%+ 달성 가능 |

### 1.2 강점

✅ 명확한 철학: "코드 품질이 절대 기준"  
✅ 파이프라인 설계: 고성능 모델 → 로컬 LLM 반복 → 다시 고성능 검증 → 자동 실행  
✅ 스코프 관리: GX10은 IDE, 상시 대화, 수동 개발을 하지 않음 (리스크 감소)  
✅ Execution Plan 의무화: 품질 통제의 핵심 방어선  

### 1.3 약점 (보완 필요)

❌ Execution Plan 포맷 미정의 (스키마, JSON 예시 부족)  
❌ GX10 API 명세 부재 (엔드포인트별 I/O 계약 없음)  
❌ Brain 전환 알고리즘 모호 (동시성 제어, 큐잉 전략 미상)  
❌ 로그/모니터링/백업 정책 불완전 (보존 기간, 필터링 규칙 미정)  
❌ Idle Improvement 안전장치 부족 (regression detection, 롤백 정책 모호)  
❌ 오류/장애 대응 플레이북 없음  
❌ 보안/권한 관리 정책 미흡  

---

## 2. 보완 필요 영역 - 우선순위별

### 우선순위 1 (필수) - 즉시 보완

| 번호 | 항목 | 영향도 | 난도 | 예상 시간 |
|------|------|--------|------|----------|
| **1-1** | Execution Plan 스키마 정의 | 🔴 높음 | 중간 | 2-3일 |
| **1-2** | GX10 API 명세서 작성 | 🔴 높음 | 높음 | 3-5일 |
| **1-3** | Brain 전환 & 동시성 제어 알고리즘 | 🔴 높음 | 높음 | 3-5일 |
| **1-4** | 에러 코드 & 응답 포맷 규격화 | 🟠 중간 | 낮음 | 1-2일 |

### 우선순위 2 (높음) - 1주일 내 보완

| 번호 | 항목 | 영향도 | 난도 | 예상 시간 |
|------|------|--------|------|----------|
| **2-1** | 로그/모니터링/백업 정책 | 🟠 중간 | 중간 | 2-3일 |
| **2-2** | Idle Improvement 안전장치 | 🟠 중간 | 높음 | 2-3일 |
| **2-3** | 오류/장애 대응 플레이북 | 🟠 중간 | 중간 | 2-3일 |

### 우선순위 3 (권장) - 2주일 내 보완

| 번호 | 항목 | 영향도 | 난도 | 예상 시간 |
|------|------|--------|------|----------|
| **3-1** | 실제 사용 시나리오 예시 | 🟡 낮음 | 낮음 | 1-2일 |
| **3-2** | 보안/권한 관리 정책 | 🟡 낮음 | 중간 | 1-2일 |
| **3-3** | n8n 워크플로우 노드 설계안 | 🟡 낮음 | 중간 | 2-3일 |

---

## 3. 세부 보완 항목 및 실행 방안

### ✅ 우선순위 1-1: Execution Plan 스키마 정의

#### 현재 상태
```
"Execution Plan은 다음을 반드시 포함한다:
- 디렉토리 구조
- 파일 목록
- 각 파일의 책임
- 구현 순서
- 테스트 기준"
```

#### 보완 사항

**A. JSON Schema 정의** (실제 운영 코드에 포함될 format)

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
          "enum": ["python", "javascript", "typescript", "java", "cpp", "rust"]
        },
        "framework": {
          "type": "string",
          "examples": ["fastapi", "django", "nodejs", "spring"]
        },
        "python_version": {
          "type": "string",
          "pattern": "^3\\.[0-9]+$"
        },
        "style_guide": {
          "type": "string",
          "enum": ["pep8", "google", "numpy", "prettier", "eslint"]
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
                "maximum": 100
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
        "required_coverage": { "type": "number", "default": 80 },
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

**B. YAML 예시 (실제 사용)**

```yaml
project_name: user-service-api
version: "1.0.0"
root_dir: /workspace/user-service-api
description: User authentication and profile management service

constraints:
  language: python
  framework: fastapi
  python_version: "3.11"
  style_guide: pep8
  max_file_lines: 500

files:
  - path: src/main.py
    responsibility: FastAPI 애플리케이션 진입점, 라우터 등록
    dependencies: []
    test_target: tests/test_main.py
    optional: false

  - path: src/api/users.py
    responsibility: 사용자 관련 라우트 (GET /users, POST /users 등)
    dependencies: [src/core/use_cases.py, src/db/models.py]
    test_target: tests/api/test_users.py
    optional: false

  - path: src/core/use_cases.py
    responsibility: 사용자 생성, 조회, 수정, 삭제 비즈니스 로직
    dependencies: [src/db/repository.py]
    test_target: tests/core/test_use_cases.py
    optional: false

  - path: src/db/models.py
    responsibility: SQLAlchemy 모델 정의
    dependencies: []
    test_target: tests/db/test_models.py
    optional: false

  - path: src/db/repository.py
    responsibility: 데이터베이스 접근 계층 (Data Access Object)
    dependencies: [src/db/models.py]
    test_target: tests/db/test_repository.py
    optional: false

  - path: src/auth/jwt.py
    responsibility: JWT 토큰 생성, 검증
    dependencies: []
    test_target: tests/auth/test_jwt.py
    optional: false

  - path: src/config.py
    responsibility: 환경 설정, 데이터베이스 연결 설정
    dependencies: []
    test_target: null
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

**C. 버전 관리 규칙**

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

### ✅ 우선순위 1-2: GX10 API 명세서 작성

#### 보완 사항: OpenAPI 3.0 초안

**A. Brain 상태 조회 API**

```yaml
/api/brain/status:
  get:
    summary: 현재 활성 Brain과 상태 조회
    tags:
      - Brain Management
    responses:
      200:
        description: 성공
        content:
          application/json:
            schema:
              type: object
              properties:
                active_brain:
                  type: string
                  enum: [code-brain, vision-brain, none]
                  description: 현재 활성 Brain 이름
                health:
                  type: string
                  enum: [healthy, degraded, unhealthy]
                container_status:
                  type: object
                  properties:
                    cpu_usage_percent:
                      type: number
                      example: 45.2
                    memory_usage_mb:
                      type: number
                      example: 12800
                    gpu_usage_percent:
                      type: number
                      example: 75.0
                    gpu_memory_mb:
                      type: number
                      example: 24576
                timestamp:
                  type: string
                  format: date-time
                  description: 조회 시각 (ISO 8601)
            example:
              active_brain: "code-brain"
              health: "healthy"
              container_status:
                cpu_usage_percent: 45.2
                memory_usage_mb: 12800
                gpu_usage_percent: 75.0
                gpu_memory_mb: 24576
              timestamp: "2026-02-01T19:00:00Z"
```

**B. Brain 전환 API**

```yaml
/api/brain/switch:
  post:
    summary: Brain 전환 (예: code-brain → vision-brain)
    tags:
      - Brain Management
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            required: [target_brain]
            properties:
              target_brain:
                type: string
                enum: [code-brain, vision-brain]
              reason:
                type: string
                maxLength: 200
              force:
                type: boolean
                default: false
                description: 진행 중인 작업을 강제 종료하고 전환할지 여부
    responses:
      200:
        description: 전환 성공
        content:
          application/json:
            schema:
              type: object
              properties:
                result: { type: string, enum: [success, pending] }
                target_brain: { type: string }
                estimated_duration_seconds: { type: integer }
                timestamp: { type: string, format: date-time }
      400:
        description: 잘못된 요청 (target_brain 값 오류 등)
      409:
        description: 충돌 (이미 전환 중, 다른 작업 진행 중)
      503:
        description: 리소스 부족 (메모리, GPU 등)
```

**C. 작업 실행 API**

```yaml
/api/task/execute:
  post:
    summary: GX10 Code Brain 또는 Vision Brain에서 작업 실행
    tags:
      - Task Execution
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            required: [task_type, payload]
            properties:
              task_type:
                type: string
                enum: [code_implementation, refactor, test, vision_benchmark]
              payload:
                oneOf:
                  - $ref: '#/components/schemas/CodeImplementationPayload'
                  - $ref: '#/components/schemas/VisionBenchmarkPayload'
              priority:
                type: string
                enum: [low, normal, high]
                default: normal
              timeout_seconds:
                type: integer
                default: 3600
              callback_url:
                type: string
                format: uri
                description: 작업 완료 시 결과를 POST할 URL (선택)
    responses:
      202:
        description: 작업 수락 (비동기 처리)
        content:
          application/json:
            schema:
              type: object
              properties:
                task_id:
                  type: string
                  format: uuid
                status: { type: string, enum: [queued, processing] }
                position_in_queue: { type: integer }
                estimated_wait_seconds: { type: integer }

components:
  schemas:
    CodeImplementationPayload:
      type: object
      required: [execution_plan_path]
      properties:
        execution_plan_path:
          type: string
          description: Execution Plan YAML 경로 (절대 또는 프로젝트 상대)
        execution_plan_json:
          type: object
          description: Execution Plan JSON 직접 전달 (경로 대신)
        
    VisionBenchmarkPayload:
      type: object
      required: [model_names, dataset_path]
      properties:
        model_names:
          type: array
          items: { type: string }
          description: 벤치마크 대상 모델 (예: [yolov8, yolov10])
        dataset_path:
          type: string
        metrics:
          type: array
          items:
            type: string
            enum: [latency, throughput, accuracy, memory]
          default: [latency, throughput]
```

**D. 작업 결과 조회 API**

```yaml
/api/task/{task_id}:
  get:
    summary: 특정 작업의 상태 및 결과 조회
    tags:
      - Task Management
    parameters:
      - name: task_id
        in: path
        required: true
        schema: { type: string, format: uuid }
    responses:
      200:
        description: 성공
        content:
          application/json:
            schema:
              type: object
              properties:
                task_id: { type: string }
                status:
                  type: string
                  enum: [queued, processing, success, failed, cancelled]
                created_at: { type: string, format: date-time }
                started_at: { type: string, format: date-time }
                completed_at: { type: string, format: date-time }
                result:
                  type: object
                  properties:
                    output_dir: { type: string }
                    files_created: { type: array, items: { type: string } }
                    test_results: { type: object }
                    duration_seconds: { type: number }
                error:
                  type: object
                  properties:
                    code: { type: string }
                    message: { type: string }
                    details: { type: string }
```

---

### ✅ 우선순위 1-3: Brain 전환 & 동시성 제어 알고리즘

#### 보완 사항: 상세 알고리즘

**A. Brain 전환 상태 머신**

```
상태 다이어그램:

                    ┌─────────────┐
                    │   NONE      │
                    │ (시작/종료)  │
                    └──────┬──────┘
                           │
                      switch_to_X
                           │
                           ▼
                    ┌─────────────────┐
                    │ TRANSITIONING   │
                    │ (X로 전환 중)    │
                    └──────┬──────────┘
                           │
                ┌──────────┴──────────┐
                │                     │
           success              failure
                │                     │
                ▼                     ▼
        ┌──────────┐           ┌────────────┐
        │   X_OK   │           │ X_FAILED   │
        │(X 활성)  │           │(실패)      │
        └────┬─────┘           └─────┬──────┘
             │                       │
             │                  retry/fallback
             │                       │
             ├───────────┬───────────┤
             │   switch  │   switch  │
             ▼           ▼           ▼
        ┌─────────────────┐    ┌───────────┐
        │  TRANSITIONING  │    │ NONE      │
        │  (Y로 전환 중)   │    │(초기화)   │
        └────────────────┘    └───────────┘
```

**B. 전환 절차 상세**

```
1. 전환 요청 도착 (target_brain=vision-brain)
   └─ 권한 확인, 요청 유효성 검증

2. 현재 Brain 상태 확인
   ├─ Case A: NONE (아무것도 활성 아님)
   │   └─ vision-brain 컨테이너 start → 상태 모니터링
   │
   ├─ Case B: code-brain 활성, force=false
   │   ├─ 진행 중 작업 확인
   │   ├─ 작업 있으면 → 409 Conflict (상태: waiting_for_current_job)
   │   └─ 작업 없으면 → code-brain 컨테이너 stop → vision-brain 시작
   │
   └─ Case C: code-brain 활성, force=true
       ├─ 진행 중 작업 강제 종료 (로그 저장)
       ├─ 타임아웃 15초 설정
       ├─ code-brain 컨테이너 stop
       └─ vision-brain 시작

3. 도중 상태 업데이트 (polling용)
   ├─ TRANSITIONING
   ├─ health check 주기 1초
   └─ 타임아웃 60초

4. 완료
   ├─ 성공: VISION_OK, 응답 200
   └─ 실패: VISION_FAILED, 롤백 시도 후 NONE
```

**C. 동시성 제어 - 큐잉 전략**

```
작업 큐 구조:

┌─────────────────────────┐
│  /runtime/locks/        │
├─────────────────────────┤
│ brain.lock              │  (현재 활성 Brain 정보)
│ switch.lock             │  (전환 중 표시)
│ task_queue.json         │  (대기 중인 작업)
└─────────────────────────┘

task_queue.json 예시:
{
  "queued_tasks": [
    {
      "task_id": "uuid-1",
      "priority": "high",
      "task_type": "code_implementation",
      "queued_at": "2026-02-01T19:05:00Z",
      "position": 1
    },
    {
      "task_id": "uuid-2",
      "priority": "normal",
      "queued_at": "2026-02-01T19:06:00Z",
      "position": 2
    }
  ]
}

우선순위 규칙:
  high    → 즉시 실행 (현재 작업 완료 후)
  normal  → FIFO
  low     → Brain 여유 시간에만 처리 (idle time)
```

**D. 동시성 제어 - 락 메커니즘**

```python
# 의사코드 (실제 구현 시 참고)

class BrainLockManager:
    LOCK_DIR = "/runtime/locks"
    LOCK_TIMEOUT = 30  # 초
    
    def acquire_brain_lock(self, brain_name):
        """뇌 실행 락 획득"""
        lock_file = f"{LOCK_DIR}/brain.lock"
        
        # 1. 기존 락 확인
        if exists(lock_file):
            lock_info = load_json(lock_file)
            if time.time() - lock_info['acquired_at'] > LOCK_TIMEOUT:
                # 좀비 락 정리
                remove(lock_file)
            else:
                raise LockBusyError(lock_info['holder'])
        
        # 2. 새 락 생성
        lock_info = {
            "brain": brain_name,
            "acquired_at": time.time(),
            "pid": os.getpid()
        }
        write_json(lock_file, lock_info)
        return lock_file
    
    def release_brain_lock(self):
        """뇌 실행 락 해제"""
        lock_file = f"{LOCK_DIR}/brain.lock"
        remove(lock_file)
```

---

### ✅ 우선순위 1-4: 에러 코드 & 응답 포맷 규격화

#### 보완 사항: 표준 에러 정의

**A. 에러 코드 규격**

```yaml
errors:
  # 100번대: 요청 유효성
  EXE_PLAN_INVALID:
    code: 101
    http_status: 400
    message: "Execution Plan이 유효하지 않음"
    examples:
      - "JSON schema validation failed"
      - "필수 필드 누락: files"
    recovery: "Execution Plan JSON 스키마 확인 후 재시도"

  EXE_PLAN_NOT_FOUND:
    code: 102
    http_status: 404
    message: "Execution Plan 파일을 찾을 수 없음"

  # 200번대: Brain/리소스 문제
  BRAIN_NOT_AVAILABLE:
    code: 201
    http_status: 503
    message: "요청한 Brain을 사용할 수 없음"
    examples:
      - "Brain이 시작되지 않음"
      - "Brain 상태 오류: unhealthy"

  BRAIN_BUSY:
    code: 202
    http_status: 409
    message: "Brain이 다른 작업을 처리 중"
    details:
      current_task_id: "uuid"
      estimated_availability_seconds: 300

  RESOURCE_LIMIT_EXCEEDED:
    code: 203
    http_status: 503
    message: "시스템 리소스 부족"
    examples:
      - "메모리 부족: 필요 70GB, 사용 가능 40GB"
      - "GPU 메모리 부족: 필요 48GB, 사용 가능 24GB"

  # 300번대: 작업 실행 오류
  TASK_EXECUTION_FAILED:
    code: 301
    http_status: 500
    message: "작업 실행 중 오류 발생"
    details:
      phase: "implementation"  # [initialization, implementation, testing, verification]
      file: "src/api/users.py"
      error_log_url: "/api/logs/task-uuid-1"

  TEST_FAILURE:
    code: 302
    http_status: 400
    message: "테스트 실패"
    details:
      test_name: "unit"
      exit_code: 1
      coverage: 72  # (required: 85)
      failure_summary: "3개 테스트 실패: test_user_creation, ..."

  # 400번대: Brain 전환 오류
  BRAIN_SWITCH_IN_PROGRESS:
    code: 401
    http_status: 409
    message: "Brain 전환이 진행 중"
    estimated_seconds: 45

  BRAIN_SWITCH_FAILED:
    code: 402
    http_status: 500
    message: "Brain 전환 실패"
    recovery: "로그 확인 후 수동 개입 필요"

  # 500번대: 인증/권한
  UNAUTHORIZED:
    code: 501
    http_status: 401
    message: "인증 필요"

  FORBIDDEN:
    code: 502
    http_status: 403
    message: "권한 부족"
    examples:
      - "해당 작업 타입에 대한 권한 없음"
```

**B. 표준 응답 포맷**

```json
{
  "success": true,
  "data": {
    "task_id": "uuid",
    "status": "processing"
  },
  "meta": {
    "timestamp": "2026-02-01T19:05:00Z",
    "request_id": "req-uuid",
    "version": "1.0"
  }
}
```

오류 응답:
```json
{
  "success": false,
  "error": {
    "code": 201,
    "name": "BRAIN_NOT_AVAILABLE",
    "message": "Vision Brain을 사용할 수 없음",
    "details": {
      "reason": "컨테이너 시작 실패",
      "container_logs": "https://gx10/logs/vision-brain-startup-failure"
    }
  },
  "meta": {
    "timestamp": "2026-02-01T19:05:00Z",
    "request_id": "req-uuid",
    "version": "1.0"
  }
}
```

---

### ✅ 우선순위 2-1: 로그/모니터링/백업 정책

#### 보완 사항: 상세 정책

**A. 로그 정책**

```yaml
logging_policy:
  
  log_levels:
    INFO: "일반 작업 진행 상황 (작업 시작/완료, Brain 상태 변경)"
    WARN: "주의 필요 상황 (리소스 부족 경고, 재시도 발생)"
    ERROR: "오류 (작업 실패, Brain 다운)"
    DEBUG: "상세 추적용 (내부 상태, 함수 호출 추적)"

  retention:
    INFO: 30일
    WARN: 60일
    ERROR: 90일
    DEBUG: 7일

  formats:
    code_brain: 
      type: "jsonl"  # 각 라인이 독립적인 JSON
      fields: [timestamp, level, task_id, phase, message, context]
      example: |
        {"timestamp":"2026-02-01T19:05:00Z","level":"INFO","task_id":"uuid-1","phase":"implementation","message":"Starting implementation of src/api/users.py"}

    vision_brain:
      type: "jsonl"
      fields: [timestamp, level, benchmark_id, model_name, metric, value]
      example: |
        {"timestamp":"2026-02-01T19:10:00Z","level":"INFO","benchmark_id":"bench-1","model_name":"yolov8","metric":"latency_ms","value":42.3}

  sensitive_data_filtering:
    mask_patterns:
      - pattern: "password.*=.*"
        replacement: "password=***"
      - pattern: "api_key.*=.*"
        replacement: "api_key=***"
      - pattern: "/home/.*?/"
        replacement: "/home/***/"
    
    remove_patterns:
      - "credit_card_.*"
      - "ssn_.*"

  log_storage:
    location: "/runtime/logs"
    structure: |
      /runtime/logs/
      ├─ code-brain/
      │  ├─ 2026-02-01/
      │  │  ├─ INFO-2026-02-01.jsonl
      │  │  ├─ WARN-2026-02-01.jsonl
      │  │  ├─ ERROR-2026-02-01.jsonl
      │  │  └─ DEBUG-2026-02-01.jsonl
      │  └─ archive/
      │
      ├─ vision-brain/
      │  ├─ 2026-02-01/
      │  │  └─ INFO-2026-02-01.jsonl
      │  └─ archive/
      │
      └─ system/
         ├─ brain-switch.jsonl
         └─ api-calls.jsonl
```

**B. 모니터링 항목**

```yaml
monitoring:
  
  metrics:
    # Code Brain
    code_brain_metrics:
      - cpu_usage_percent
      - memory_usage_mb
      - gpu_usage_percent
      - gpu_memory_mb
      - task_success_rate
      - avg_task_duration_seconds
      - test_pass_rate
      - avg_code_coverage_percent

    # Vision Brain
    vision_brain_metrics:
      - model_inference_latency_ms
      - model_throughput_fps
      - model_accuracy_percent
      - cuda_utilization_percent
      - memory_bandwidth_percent

    # System
    system_metrics:
      - active_brain
      - task_queue_length
      - avg_task_wait_time_seconds
      - brain_uptime_hours
      - disk_usage_percent

  dashboards:
    - name: "Realtime Status"
      refresh_seconds: 5
      panels: [cpu, memory, gpu, active_brain, queue_length]

    - name: "Code Brain Performance"
      refresh_seconds: 60
      panels: [task_success_rate, avg_duration, code_coverage, test_pass_rate]

    - name: "Vision Brain Benchmarks"
      refresh_seconds: 60
      panels: [latency_by_model, throughput_by_model, accuracy]

  alerting:
    rules:
      - name: "Low Memory Alert"
        condition: "memory_usage_mb > 90% of max"
        action: "notify"
        channels: [email, slack]

      - name: "Brain Down Alert"
        condition: "brain_health == unhealthy for 2 minutes"
        action: "notify + attempt_restart"
        channels: [email, slack, pagerduty]

      - name: "High Task Queue"
        condition: "task_queue_length > 50"
        action: "notify"
        channels: [slack]
```

**C. 백업 정책**

```yaml
backup_policy:
  
  backup_targets:
    # 1. 모델 가중치
    model_weights:
      source: "/docker/code-brain/models"
      destination: "/backup/models/code-brain"
      frequency: "daily"
      retention: "7 days"
      strategy: "full"
      compression: "tar.gz"

    # 2. LoRA/QLoRA 어댑터
    adapters:
      source: "/docker/code-brain/adapters"
      destination: "/backup/adapters"
      frequency: "after each Idle Improvement"
      retention: "30 days"
      compression: "tar.gz"

    # 3. Execution Plan 이력
    execution_plans:
      source: "/workspace/**/execution-plans"
      destination: "/backup/execution-plans"
      frequency: "daily"
      retention: "90 days"
      compression: "none"  # JSON 유지

    # 4. 작업 결과
    task_results:
      source: "/runtime/task-results"
      destination: "/backup/task-results"
      frequency: "weekly"
      retention: "180 days"
      compression: "tar.gz"

    # 5. 로그
    logs:
      source: "/runtime/logs"
      destination: "/backup/logs"
      frequency: "weekly"
      retention: "365 days"
      compression: "tar.gz"

  restore_procedure:
    steps:
      1: "대상 버전 확인 및 선택"
      2: "Brain 상태 정지 (stop containers)"
      3: "백업 복원 시작 (restore command)"
      4: "무결성 확인 (checksums)"
      5: "Brain 재시작"
      6: "헬스 체크"
    
    rollback_conditions:
      - "task success rate < 80% (이전 72시간 대비)"
      - "avg task duration > 150% (이전 평균 대비)"
      - "test pass rate < 85%"

  off_site_backup:
    enabled: true
    destination: "s3://gx10-backups"
    frequency: "daily"
    retention: "90 days"
    encryption: "AES-256"
```

---

### ✅ 우선순위 2-2: Idle Improvement 안전장치

#### 보완 사항: 안전 메커니즘

**A. 학습 데이터 필터링**

```yaml
idle_improvement:
  
  data_filtering:
    # 어떤 작업 결과를 학습에 사용할지
    include_criteria:
      - status: "success"
        condition: "test_pass_rate >= 95"
      - status: "success_with_fixes"
        condition: "iterations <= 3"  # 수정이 많지 않은 경우
    
    exclude_criteria:
      - failures:
          - "resource_timeout"
          - "external_service_error"
      - suspicious:
          - "identical_to_previous_attempt"
          - "coverage_regression"
      - edge_cases:
          - "file_size > 2000 lines"  # 매우 큰 파일
          - "circular_dependency_detected"

    quality_score:
      formula: |
        quality = 
          (test_pass_rate * 0.4) +
          (code_coverage * 0.3) +
          (code_review_score * 0.2) +
          (maintainability_index * 0.1)
      
      min_threshold: 75  # 75 이상만 학습 데이터로 사용
      
      breakdown:
        test_pass_rate: "0~100"
        code_coverage: "0~100"
        code_review_score: "Claude 리뷰 점수 (0~100)"
        maintainability_index: "복잡도 분석 (0~100)"

  sampling:
    strategy: "stratified"
    categories:
      - "file_type: [api, core, db, auth, util]"
      - "framework: [fastapi, django, nodejs]"
      - "complexity: [simple, medium, complex]"
    
    sample_size: 500  # 매 Idle Improvement 당 최대 500 샘플
    
    weighting:
      recent_bias: 0.7  # 최근 데이터에 더 높은 가중치
      frequency_penalty: 0.1  # 반복된 패턴 배제
```

**B. 모델 업데이트 배포 전략**

```yaml
  deployment_strategy:
    
    staging:
      enabled: true
      duration: 24  # 24시간 스테이징
      traffic_split: 10  # 전체 요청의 10%만 staging Brain으로
      
      validation_gates:
        - check_name: "regression_detection"
          metric: "task_success_rate"
          threshold: 95  # 기존 대비 95% 이상 유지
          lookback_hours: 72
        
        - check_name: "performance_check"
          metric: "avg_task_duration"
          threshold: 110  # 110% 이상 증가하면 fail
          lookback_hours: 72
        
        - check_name: "coverage_check"
          metric: "avg_code_coverage"
          threshold: 90  # 90% 이상 유지
          lookback_hours: 72

    promotion_policy:
      automatic: false  # 수동 승인 필요
      approval_required: ["tech-lead", "system-admin"]
      rollout_strategy:
        - phase_1: "10% 트래픽 (1시간)"
        - phase_2: "50% 트래픽 (2시간)"
        - phase_3: "100% 트래픽"
```

**C. Regression Detection & Rollback**

```yaml
  regression_detection:
    
    metrics_to_monitor:
      - metric: "code_brain_task_success_rate"
        baseline: "last_30_days_avg"
        alert_threshold: -5  # 5% 이상 감소 시 알림
        autorollback_threshold: -10  # 10% 이상 감소 시 자동 롤백

      - metric: "avg_implementation_duration"
        baseline: "last_30_days_avg"
        alert_threshold: 20  # 20% 증가 시 알림
        autorollback_threshold: 50  # 50% 증가 시 자동 롤백

      - metric: "avg_code_coverage_percent"
        baseline: "last_30_days_avg"
        alert_threshold: -3  # 3% 감소 시 알림
        autorollback_threshold: -5  # 5% 감소 시 자동 롤백

    detection_window: "1 hour"  # 매 1시간마다 검사
    
    alert_channels: [email, slack, pagerduty]

  automatic_rollback:
    enabled: true
    trigger: "autorollback_threshold 초과 또는 manual approval"
    
    procedure:
      1: "이전 버전 로드"
      2: "Brain 재시작"
      3: "헬스 체크 (30초)"
      4: "롤백 확인 또는 실패 알림"
      5: "로그 저장 (분석용)"
```

**D. Idle Improvement 실행 일정**

```yaml
  scheduling:
    
    conditions_to_start:
      - "no active tasks for 30 minutes"
      - "active_brain_resource_usage < 20%"
      - "current_time outside business hours (after 7pm KST)"
    
    max_duration: 120  # 최대 2시간
    
    background_resource_limits:
      cpu_usage: 40  # 40% 제한
      memory_usage: 30  # 30% 제한
      gpu_usage: 20  # 20% 제한 (Vision Brain 활성 시에만 적용)
    
    frequency: "daily"
    preferred_time: "22:00 KST (밤 10시)"
    
    interruption_policy:
      external_task_priority: true  # 외부 작업 요청 시 즉시 중단
      save_checkpoint: true  # 중단 전 진행 상태 저장
```

---

### ✅ 우선순위 2-3: 오류/장애 대응 플레이북

#### 보완 사항: 실제 대응 절차

**A. Brain이 응답하지 않을 때**

```
상황: API 호출 시 timeout (30초 이상)

1단계: 확인
  □ Docker 컨테이너 상태 확인
    $ docker ps | grep gx10
  □ 컨테이너 로그 확인 (최근 100줄)
    $ docker logs --tail 100 gx10-code-brain
  □ 시스템 리소스 확인
    $ nvidia-smi  (GPU)
    $ free -h     (메모리)
    $ top -b -n1  (CPU)

2단계: 임시 조치 (30분 내)
  ✓ 시도 1: Brain 재시작
    $ docker restart gx10-code-brain
    → 2분 대기 후 상태 확인
    → 성공하면 로그 저장 후 모니터링

  ✓ 시도 2: 캐시 정리 후 재시작
    $ docker exec gx10-code-brain python -c "import torch; torch.cuda.empty_cache()"
    $ docker restart gx10-code-brain
    → 2분 대기

  ✓ 시도 3: 강제 종료 및 재생성
    $ docker kill gx10-code-brain
    $ docker run ... (run script 사용)
    → 3분 대기

3단계: 진단 (실패 시)
  □ /runtime/logs/code-brain/ERROR-*.jsonl 마지막 10개 항목 확인
  □ Docker daemon 상태 확인
    $ systemctl status docker
  □ 디스크 용량 확인
    $ df -h
  □ GPU 메모리 누수 확인
    $ nvidia-smi -q -d MEMORY

4단계: 장기 조치 (필요 시)
  ✓ Vision Brain 활성 상태라면 Code Brain으로 전환 후 재생성
  ✓ 컨테이너 이미지 재빌드
    $ docker build -t gx10-code-brain:latest docker/code-brain/
  ✓ 최근 작업 수동 재시작
  ✓ 기술 리드에 보고
```

**B. Docker 컨테이너가 자주 재시작될 때**

```
상황: 컨테이너가 10분마다 자동으로 재시작됨

1단계: 확인
  □ 컨테이너 재시작 이력 확인
    $ docker inspect gx10-code-brain | grep -A 10 "RestartCount"
  □ 최근 24시간 로그 전체 확인
    $ docker logs --since 24h gx10-code-brain > /tmp/brain-logs-24h.txt
  □ 특정 오류 패턴 검색
    $ grep -E "OOM|OutOfMemory|CUDA|Segmentation|killed" /tmp/brain-logs-24h.txt

2단계: 원인별 대응

  원인: OOM (Out of Memory)
    → 증상: "Killed" 또는 "OOM killer" 메시지
    → 대응:
      1. 메모리 할당 증가
         $ docker run ... -m 80G -e PYTORCH_CUDA_ALLOC_CONF=... (update config)
      2. 모델 최적화
         $ 낮은 precision 사용 (fp32 → fp16)
         $ batch size 감소

  원인: GPU Out of Memory
    → 증상: "RuntimeError: CUDA out of memory"
    → 대응:
      1. GPU 메모리 정리 자동화 추가
      2. 배치 처리 크기 감소
      3. 모델 양자화 검토

  원인: 좀비 프로세스
    → 증상: "Process exited with code 137"
    → 대응:
      1. 컨테이너 정리 정책 추가
         $ docker run ... --rm ...
      2. init 프로세스 개선
         $ docker run ... --init ...

3단계: 수정 확인 (2시간 모니터링)
  □ 1시간마다 상태 확인
    $ docker ps -a | grep gx10-code-brain
  □ 다시 재시작되지 않으면 성공
  □ 실패 시 최상급 기술 팀에 에스컬레이션
```

**C. 실행 결과가 Execution Plan과 다를 때**

```
상황: Code Brain이 생성한 파일 수, 테스트 결과가 계획과 불일치

1단계: 확인
  □ 작업 ID 확인 및 로그 조회
    $ curl https://gx10/api/task/{task_id}
  □ 상세 로그 다운로드
    $ curl https://gx10/api/task/{task_id}/logs > task-logs.jsonl
  □ 생성된 파일 목록 확인
    $ ls -la /workspace/{project}/src/
  □ 테스트 결과 상세 확인
    $ cat /workspace/{project}/test-results.json

2단계: 원인 분류
  
  분류 1: 부분 실패 (일부 파일만 생성됨)
    → 해당 파일의 로그 확인
    → 의존성 문제 또는 리소스 초과 가능성
    → Execution Plan 의존성 재확인

  분류 2: 테스트 실패
    → 테스트 명령 재실행 (로컬에서)
    → pytest 상세 리포트 확인
    → 코드 리뷰 (Claude)

  분류 3: 예상치 못한 구현
    → 생성된 파일 diff 확인
    → Claude 리뷰 의견서 확인
    → 모델 hallucination 가능성 검토

3단계: 대응
  ✓ 부분 재실행 (실패한 파일만)
    → Execution Plan 수정
    → 그 파일 이후 단계만 실행
  
  ✓ 전체 재실행 (다른 파라미터로)
    → Execution Plan 조정
    → timeout 증가, batch 크기 조정 등
  
  ✓ 수동 수정
    → 개발자가 결과 검토 후 수정
    → 수정 사항을 학습 데이터로 기록
```

**D. 성능이 갑자기 저하되었을 때**

```
상황: Code Brain의 작업 완료 시간이 평소 30분에서 2시간으로 증가

1단계: 확인
  □ 시스템 리소스 모니터링
    $ watch -n 1 'nvidia-smi'
    $ watch -n 1 'free -h'
    $ watch -n 1 'top -b -n1 | head -20'

  □ Brain 상태 확인
    $ curl https://gx10/api/brain/status

  □ 작업 큐 상태 확인
    $ curl https://gx10/api/task/queue
    → 대기 작업 많음? (큐 병목)
    → 현재 작업 특이사항? (개별 작업 느림)

  □ 성능 메트릭 비교 (과거 7일)
    → 작업당 평균 시간 추이
    → 성공률 추이
    → 리소스 사용률 추이

2단계: 원인 분석

  원인 1: 큐 병목 (대기 작업 많음)
    → 대응: 새 Brain 추가 또는 우선순위 조정
    → 파라미터: task queue length > 50

  원인 2: 리소스 부족
    → 증상: GPU 사용률 < 20% 인데도 느림 → CPU/메모리 병목
    → 대응: 다른 프로세스 확인 및 정리
    → 명령: $ ps aux | sort -k3 -r | head

  원인 3: 모델 성능 저하
    → 증상: 리소스 충분한데도 느림
    → 대응: 최근 LoRA 업데이트 롤백 검토
    → 확인: regression detection 결과 확인

  원인 4: 네트워크 또는 스토리지 병목
    → 증상: 코드 분석/로드 단계에서만 느림
    → 대응: I/O 캐싱 또는 로컬 SSD 활용

3단계: 조치
  ✓ 즉시 (5분): 현재 작업 상태 확인 및 모니터링 시작
  ✓ 15분 내: 불필요 프로세스 종료, 캐시 정리
  ✓ 1시간 내: 로그 분석 및 근본 원인 파악
  ✓ 필요 시: Brain 재시작 또는 리소스 증설
```

---

### ✅ 우선순위 3-1: 실제 사용 시나리오 예시

#### 보완 사항: End-to-End 워크플로우 예시

**시나리오 1: 소규모 신규 서비스 개발**

```
목표: FastAPI 기반 사용자 인증 서비스 개발

Step 1: 개발자 PC - 요구사항 정의
  - 기능:
    * 사용자 회원가입 (POST /users)
    * 이메일 검증
    * JWT 기반 인증
    * 사용자 프로필 조회/수정

Step 2: 개발자 PC - Execution Plan 작성
  
  project_name: user-auth-service
  version: 1.0.0
  root_dir: /workspace/user-auth-service
  
  files:
    - path: src/config.py
      responsibility: 환경 설정
    - path: src/models.py
      responsibility: SQLAlchemy 모델
    - path: src/auth/jwt.py
      responsibility: JWT 처리
    - path: src/core/use_cases.py
      responsibility: 회원가입/인증 로직
    - path: src/api/users.py
      responsibility: 사용자 라우트
    - path: src/main.py
      responsibility: FastAPI 진입점

  tests:
    - name: unit
      command: pytest tests/ -v
      success_criteria:
        exit_code: 0
        min_coverage: 85

Step 3: GX10에 작업 제출
  
  curl -X POST https://gx10/api/task/execute \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer {token}" \
    -d '{
      "task_type": "code_implementation",
      "payload": {
        "execution_plan_path": "/workspace/user-auth-service/execution-plan-1.0.0.yaml"
      },
      "priority": "normal",
      "timeout_seconds": 1800,
      "callback_url": "https://myserver/webhook/task-complete"
    }'
  
  응답:
  {
    "task_id": "task-abc123",
    "status": "queued",
    "position_in_queue": 2,
    "estimated_wait_seconds": 300
  }

Step 4: 작업 진행 모니터링
  
  # 매 30초마다 확인
  curl https://gx10/api/task/task-abc123
  
  {
    "task_id": "task-abc123",
    "status": "processing",
    "current_phase": "implementation",
    "progress": 60,  # 3/5 파일 완료
    "started_at": "2026-02-01T19:10:00Z"
  }

Step 5: 작업 완료
  
  curl https://gx10/api/task/task-abc123
  
  {
    "task_id": "task-abc123",
    "status": "success",
    "result": {
      "output_dir": "/workspace/user-auth-service",
      "files_created": [
        "src/config.py",
        "src/models.py",
        "src/auth/jwt.py",
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
    "completed_at": "2026-02-01T19:30:00Z"
  }

Step 6: 개발자 PC - 결과 검증
  
  1. 생성된 코드 다운로드/확인
     $ ls -la /workspace/user-auth-service/src/
  
  2. Claude에 코드 리뷰 요청
     → 구조적 개선점, 보안 이슈 검토
  
  3. 로컬에서 테스트 실행
     $ cd /workspace/user-auth-service
     $ pytest tests/ -v
  
  4. 리뷰 의견 반영 필요 시
     → Execution Plan 수정 후 다시 GX10에 제출 (refactor 타입)
```

---

### ✅ 우선순위 3-2: 보안/권한 관리 정책

#### 보완 사항: 접근 제어

**A. API 호출 권한**

```yaml
api_security:
  
  authentication:
    method: "JWT Bearer Token"
    token_issuer: "gx10-auth-service"
    token_lifetime: 3600  # 1시간
    refresh_token_lifetime: 604800  # 7일
    
    token_payload:
      {
        "sub": "user-id",
        "org": "organization-id",
        "roles": ["developer", "admin"],
        "permissions": ["task_execute", "brain_switch", "view_logs"],
        "iat": 1645089600,
        "exp": 1645093200
      }

  authorization_matrix:
    # 역할 기반 접근 제어 (RBAC)
    
    roles:
      developer:
        - api: /api/task/execute
          allowed_task_types: [code_implementation]
          max_timeout: 3600
        - api: /api/task/{task_id}
          allowed_operations: [status, logs]
        - api: /api/brain/status
          allowed_operations: [read]
      
      data_scientist:
        - api: /api/brain/switch
          allowed_targets: [vision-brain]
        - api: /api/task/execute
          allowed_task_types: [vision_benchmark]
        - api: /api/brain/status
          allowed_operations: [read]
      
      admin:
        - api: /api/*
          allowed_operations: ["*"]
      
      ci_cd:
        - api: /api/task/execute
          allowed_task_types: [code_implementation, refactor]
          max_timeout: 7200
          max_concurrent_tasks: 5

  rate_limiting:
    per_user: "100 requests per hour"
    per_ip: "500 requests per hour"
    per_api_endpoint:
      /api/task/execute: "10 per hour"
      /api/brain/switch: "5 per hour"
```

**B. 로그 및 민감 정보 필터링**

```yaml
  sensitive_data_protection:
    
    pii_masking:
      patterns:
        - field: "file_path"
          mask: "/home/***/{project}/"
        - field: "error_message"
          mask: "***"
          if_contains: ["password", "token", "key", "secret"]
        - field: "source_code"
          mask: "REDACTED"
          if_contains: ["API_KEY", "SECRET_KEY"]
    
    log_access_control:
      # 누가 로그를 볼 수 있는가?
      /runtime/logs/code-brain:
        view:
          - roles: [admin, tech-lead]
          - roles: [developer]
            condition: "task_owner"  # 자신의 작업 로그만
      
      /runtime/logs/system:
        view:
          - roles: [admin, system-admin]

    audit_logging:
      # 모든 API 호출 기록
      events_to_log:
        - "api_call"
        - "task_execute"
        - "brain_switch"
        - "model_update"
        - "rollback"
      
      audit_log_retention: "1 year"
      immutability: true  # 감사 로그 변조 불가
```

**C. 네트워크 보안**

```yaml
  network_security:
    
    ip_whitelist:
      - "10.0.0.0/8"  # 내부 네트워크
      - "203.0.113.0/24"  # 사무실
      - "198.51.100.10"  # CI/CD 서버 IP
    
    firewall_rules:
      inbound:
        - port: 443
          protocol: https
          source: "whitelist"
        - port: 22
          protocol: ssh
          source: "admin_only"
      
      outbound:
        - destination: "pypi.org"
          port: 443
          purpose: "package download"
        - destination: "huggingface.co"
          port: 443
          purpose: "model download"
```

---

### ✅ 우선순위 3-3: n8n 워크플로우 노드 설계안

#### 보완 사항: 자동화 워크플로우 예시

**A. 기본 워크플로우 구조**

```
[Webhook Trigger]
    ↓
[Parse Request Body]
    ↓
[Validate Execution Plan]
    ↓
[Check GX10 Status]
    ↓
[Switch Brain if needed]
    ↓
[Submit Task to GX10]
    ↓
[Poll Task Status]
    ↓
[Success/Failure Notification]
    ↓
[Update Project Management Tool]
```

**B. n8n 노드 정의**

```json
{
  "workflow": {
    "name": "GX10-Task-Execution",
    "nodes": [
      {
        "type": "webhook",
        "name": "GitHub-Push-Webhook",
        "parameters": {
          "path": "github-push",
          "method": "POST"
        }
      },
      {
        "type": "http",
        "name": "Get-GX10-Status",
        "parameters": {
          "url": "https://gx10/api/brain/status",
          "method": "GET",
          "headers": {
            "Authorization": "Bearer {{ $env.GX10_TOKEN }}"
          }
        }
      },
      {
        "type": "if",
        "name": "Check-Brain-Health",
        "parameters": {
          "conditions": {
            "0": {
              "field": "{{ $node['Get-GX10-Status'].json.body.health }}",
              "operator": "equals",
              "value": "healthy"
            }
          }
        }
      },
      {
        "type": "http",
        "name": "Switch-to-Code-Brain",
        "parameters": {
          "url": "https://gx10/api/brain/switch",
          "method": "POST",
          "headers": {
            "Authorization": "Bearer {{ $env.GX10_TOKEN }}",
            "Content-Type": "application/json"
          },
          "body": {
            "target_brain": "code-brain",
            "reason": "Triggered by GitHub push"
          }
        }
      },
      {
        "type": "http",
        "name": "Submit-Task-to-GX10",
        "parameters": {
          "url": "https://gx10/api/task/execute",
          "method": "POST",
          "headers": {
            "Authorization": "Bearer {{ $env.GX10_TOKEN }}",
            "Content-Type": "application/json"
          },
          "body": {
            "task_type": "code_implementation",
            "payload": {
              "execution_plan_path": "{{ $node['Parse-Payload'].json.body.execution_plan }}"
            },
            "priority": "normal",
            "timeout_seconds": 3600
          }
        }
      },
      {
        "type": "loop",
        "name": "Poll-Task-Status",
        "parameters": {
          "iterations": 60,
          "delay_ms": 10000
        }
      },
      {
        "type": "http",
        "name": "Get-Task-Result",
        "parameters": {
          "url": "https://gx10/api/task/{{ $node['Submit-Task-to-GX10'].json.body.task_id }}",
          "method": "GET",
          "headers": {
            "Authorization": "Bearer {{ $env.GX10_TOKEN }}"
          }
        }
      },
      {
        "type": "if",
        "name": "Check-Task-Complete",
        "parameters": {
          "conditions": {
            "0": {
              "field": "{{ $node['Get-Task-Result'].json.body.status }}",
              "operator": "in",
              "value": ["success", "failed"]
            }
          }
        }
      },
      {
        "type": "slack",
        "name": "Send-Slack-Notification",
        "parameters": {
          "message": "GX10 Task {{ $node['Submit-Task-to-GX10'].json.body.task_id }} completed with status: {{ $node['Get-Task-Result'].json.body.status }}"
        }
      }
    ]
  }
}
```

---

## 4. 구현 템플릿 및 예시

### 템플릿 1: Execution Plan (YAML)

위 섹션 참고 → "우선순위 1-1" 참조

### 템플릿 2: GX10 API 호출 (Python)

```python
import requests
import time
import json

class GX10Client:
    def __init__(self, api_url, token):
        self.api_url = api_url
        self.token = token
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
    
    def get_status(self):
        """Brain 상태 조회"""
        resp = requests.get(
            f"{self.api_url}/api/brain/status",
            headers=self.headers
        )
        return resp.json()
    
    def switch_brain(self, target_brain, force=False):
        """Brain 전환"""
        payload = {
            "target_brain": target_brain,
            "force": force
        }
        resp = requests.post(
            f"{self.api_url}/api/brain/switch",
            headers=self.headers,
            json=payload
        )
        return resp.json()
    
    def submit_task(self, task_type, execution_plan_path, priority="normal", timeout=3600):
        """작업 제출"""
        payload = {
            "task_type": task_type,
            "payload": {
                "execution_plan_path": execution_plan_path
            },
            "priority": priority,
            "timeout_seconds": timeout
        }
        resp = requests.post(
            f"{self.api_url}/api/task/execute",
            headers=self.headers,
            json=payload
        )
        return resp.json()
    
    def get_task_status(self, task_id):
        """작업 상태 조회"""
        resp = requests.get(
            f"{self.api_url}/api/task/{task_id}",
            headers=self.headers
        )
        return resp.json()
    
    def wait_for_task(self, task_id, max_wait_seconds=3600, poll_interval=10):
        """작업 완료 대기"""
        start_time = time.time()
        
        while time.time() - start_time < max_wait_seconds:
            result = self.get_task_status(task_id)
            status = result.get("status")
            
            if status in ["success", "failed", "cancelled"]:
                return result
            
            print(f"[{task_id}] Status: {status} ({result.get('progress', 0)}%)")
            time.sleep(poll_interval)
        
        raise TimeoutError(f"Task {task_id} did not complete within {max_wait_seconds}s")

# 사용 예시
if __name__ == "__main__":
    client = GX10Client(
        api_url="https://gx10",
        token="your-api-token"
    )
    
    # 1. Brain 상태 확인
    status = client.get_status()
    print(f"Current Brain: {status['active_brain']}")
    
    # 2. 작업 제출
    task_result = client.submit_task(
        task_type="code_implementation",
        execution_plan_path="/workspace/user-service/execution-plan-1.0.0.yaml"
    )
    task_id = task_result['task_id']
    print(f"Task submitted: {task_id}")
    
    # 3. 완료 대기
    final_result = client.wait_for_task(task_id)
    print(f"Task completed: {final_result['status']}")
```

---

## 5. 체크리스트

### Phase 1: 우선순위 1 (필수) - 2주일

- [ ] **1-1: Execution Plan 스키마**
  - [ ] JSON Schema 정의 완료
  - [ ] YAML 예시 3개 이상 작성
  - [ ] 버전 관리 규칙 정의
  - [ ] 개발팀 검증 완료

- [ ] **1-2: GX10 API 명세서**
  - [ ] OpenAPI 3.0 파일 작성
  - [ ] 5개 주요 엔드포인트 정의
  - [ ] 요청/응답 예시 작성
  - [ ] Swagger UI 배포

- [ ] **1-3: Brain 전환 & 동시성**
  - [ ] 상태 머신 다이어그램 작성
  - [ ] 전환 절차 의사코드 작성
  - [ ] 큐잉 전략 정의
  - [ ] 락 메커니즘 구현

- [ ] **1-4: 에러 코드 규격화**
  - [ ] 에러 코드 목록 (100+개) 정의
  - [ ] 표준 응답 포맷 확정
  - [ ] 개발팀 교육

### Phase 2: 우선순위 2 (높음) - 1주일

- [ ] **2-1: 로그/모니터링/백업**
  - [ ] 로그 정책 최종화
  - [ ] 모니터링 대시보드 배포
  - [ ] 백업 스크립트 작성 및 테스트
  - [ ] 복구 절차 검증

- [ ] **2-2: Idle Improvement 안전장치**
  - [ ] 데이터 필터링 정책 적용
  - [ ] Staging Brain 구성
  - [ ] Regression detection 로직 구현
  - [ ] 자동 롤백 테스트

- [ ] **2-3: 장애 대응 플레이북**
  - [ ] 4가지 시나리오 완성
  - [ ] 팀별 온콜(on-call) 체계 구축
  - [ ] Runbook 문서 배포
  - [ ] 드릴(演習) 실시

### Phase 3: 우선순위 3 (권장) - 2주일

- [ ] **3-1: 실제 사용 시나리오**
  - [ ] 3개 시나리오 End-to-End 작성
  - [ ] 팀 교육 자료 준비
  - [ ] 데모 비디오 촬영

- [ ] **3-2: 보안/권한**
  - [ ] RBAC 정책 정의
  - [ ] 네트워크 보안 설정
  - [ ] 감사 로그 시스템 구축
  - [ ] 보안 감사 실시

- [ ] **3-3: n8n 워크플로우**
  - [ ] 기본 워크플로우 배포
  - [ ] 고급 워크플로우 (조건부, 병렬) 작성
  - [ ] 팀 교육

---

## 📊 최종 평가 및 다음 단계

### 현재 상태 (v1.0)
- **구현 가능성: 80~85%**
- 강점: 명확한 철학, 건전한 아키텍처
- 약점: 세부 운영 정책 미흡

### 보완 후 예상 상태 (v1.1)
- **구현 가능성: 90~95%**
- 준비: 완전한 API 명세, 운영 정책, 장애 대응 플레이북
- 준비: 실제 팀이 바로 사용 가능한 수준

### 추천 다음 단계
1. 우선순위 1 항목부터 순차 처리 (2주)
2. 프로토타입 구축 및 테스트 (2~3주)
3. 파일럿 프로젝트 (용역사 또는 자사 프로젝트) 1개 수행
4. 피드백 반영 후 v1.2 확정
5. 전사 배포

---

**문서 작성:** 2026-02-01
**최종 수정:** 2026-02-01
**버전:** 1.0 (보완 지침서)

이 지침서는 GX10 Setup Plan v1.0을 v1.1 이상으로 상향하기 위한 구체적인 실행 계획입니다.
각 항목을 순차적으로 처리하면, 조직에서 실제로 운영 가능한 "GX10 Setup Playbook"으로 발전시킬 수 있습니다.

---

## 📜 수정 이력

| 일자 | 버전 | 설명 | 리뷰어 |
|------|------|------|--------|
| 2026-02-01 | 1.0 | v1.0 보완 지침서 초안 작성 | drake |

---

## 📝 문서 정보

**작성자**:

- (작성자 정보 없음)

**리뷰어**:

- drake
