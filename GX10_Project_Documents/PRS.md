# Product Requirements Specification (PRS)

## Status
- Overall: COMPLETE
- Functional Requirements: COMPLETE
- Non-Functional Requirements: COMPLETE

## Table of Contents
1. [Introduction](#introduction)
2. [Functional Requirements](#functional-requirements)
3. [Non-Functional Requirements](#non-functional-requirements)
4. [Interface Requirements](#interface-requirements)
5. [Data Requirements](#data-requirements)
6. [Open Items](#open-items)

---

## Introduction

### 문서 목적

본 문서는 GX10 시스템의 제품 요구사항 명세(Product Requirements Specification)를 정의합니다. MRD(Market Requirements Document)와 PRD(Product Requirements Document)에서 정의한 요구사항을 기반으로, 기능적 및 비기능적 요구사항을 상세히 명세합니다.

### 적용 범위

- **포함**: GX10 시스템의 Two Brain 아키텍처, Execution Plan 시스템, REST API, 자동화 파이프라인
- **제외**: 개발자 PC의 Claude Code, VS Code, Warp 터미널

---

## Functional Requirements

### FR-PRS-1: Execution Plan 기반 코드 생성 (Execution Plan-Based Code Generation)

**우선순위**: P0 (필수)

**설명**: GX10 Code Brain은 사용자가 제공한 Execution Plan을 기반으로 코드를 생성해야 합니다.

**요구사항**:

**FR-PRS-1.1**: Execution Plan 입력 수신
- 시스템은 JSON 또는 YAML 형식의 Execution Plan을 수신해야 함
- Execution Plan 스키마 유효성 검증 수행
- 필수 필드 누락 시 명확한 에러 메시지 반환

**FR-PRS-1.2**: 파일별 구현
- 각 파일의 책임(responsibility)에 따라 코드 생성
- 의존성 순서 준수 (dependencies 필드 기반)
- 구현 순서 준수 (implementation_order 필드 기반)

**FR-PRS-1.3**: 테스트 자동 생성
- 각 파일에 대응하는 테스트 파일 자동 생성
- test_target 필드가 명시된 경우에만 테스트 생성
- 테스트 프레임워크 자동 감지 (pytest, jest, etc.)

**FR-PRS-1.4**: 재시도 메커니즘
- 테스트 실패 시 자동 재수정 (최대 3회)
- 재시도 간격: 5초
- 재시도 실패 시 상세 에러 로그 기록

**수락 기준**:
- Execution Plan → 코드 생성 성공률: 95%+
- 테스트 통과율: 85%+ (초 시도)

---

### FR-PRS-2: 설계와 실행 분리 (Design-Execution Separation)

**우선순위**: P0 (필수)

**설명**: Code Brain은 Execution Plan에 명시된 작업만 수행하며, 임의 판단을 해서는 안 됩니다.

**요구사항**:

**FR-PRS-2.1**: 임의 판단 금지
- Execution Plan에 없는 파일 생성 금지
- 요구사항 해석 금지
- 아키텍처 설계 금지

**FR-PRS-2.2**: 제한적 사고 범위
- 파일 구조: Execution Plan에 명시된 범위 내
- 구현 내용: 책임 필드에 명시된 범위 내
- 테스트 범위: test_criteria에 명시된 범위 내

**FR-PRS-2.3**: 명시적 제약 조건 준수
- 언어: constraints.language (Python, JavaScript, etc.)
- 프레임워크: constraints.framework (FastAPI, Django, etc.)
- 스타일 가이드: constraints.style_guide (PEP8, Google, etc.)

**수락 기준**:
- 임의 판단 발생 건수: 0
- 제약 조건 위반 건수: 0

---

### FR-PRS-3: 외부 제어 지원 (External Control Support)

**우선순위**: P0 (필수)

**설명**: 개발자 PC, CI/CD, MCP, n8n과 같은 외부 시스템에서 GX10을 제어할 수 있어야 합니다.

**요구사항**:

**FR-PRS-3.1**: Brain 상태 조회
- HTTP GET `/api/brain/status` 엔드포인트 제공
- 응답 포맷: JSON
- 포함 정보: active_brain, health, container_status

**FR-PRS-3.2**: Brain 전환
- HTTP POST `/api/brain/switch` 엔드포인트 제공
- 요청 파라미터: target_brain (code/vision)
- 전환 시간: < 30초

**FR-PRS-3.3**: 작업 실행
- HTTP POST `/api/task/execute` 엔드포인트 제공
- 요청 파라미터: task_type, payload (execution_plan_path)
- 비동기 처리: 즉시 task_id 반환

**FR-PRS-3.4**: 작업 상태 조회
- HTTP GET `/api/task/{task_id}` 엔드포인트 제공
- 응답 상태: queued, processing, success, failed
- 진행률 백분율 제공 (0-100%)

**수락 기준**:
- API 응답 시간: < 1초
- API 가동률: 99.9%+

---

### FR-PRS-4: Two Brain 전환 (Two Brain Switching)

**우선순위**: P0 (필수)

**설명**: Code Brain과 Vision Brain을 상황에 따라 전환할 수 있어야 합니다.

**요구사항**:

**FR-PRS-4.1**: 단일 Brain 실행 강제
- Code Brain과 Vision Brain 동시 실행 방지
- Brain 전환 시 현재 Brain 강제 종료
- 활성 Brain 상태 관리 (active_brain.json)

**FR-PRS-4.2**: Buffer Cache 플러시
- Brain 전환 전 Buffer Cache 플러시 실행
- 명령어: `sync; echo 3 > /proc/sys/vm/drop_caches`
- 플러시 후 안정화 대기: 5초

**FR-PRS-4.3**: 전환 원자성 보장
- 전환 실패 시 이전 상태로 자동 롤백
- 전환 로그 기록 (timestamp, from_brain, to_brain, status)

**수락 기준**:
- Brain 전환 성공률: 99%+
- 전환 중 메모리 오류 발생률: < 1%

---

### FR-PRS-5: Idle Improvement (Idle Improvement)

**우선순위**: P1 (중요)

**설명**: 외부 작업 지시가 없을 때 GX10이 자동으로 모델을 개선해야 합니다.

**요구사항**:

**FR-PRS-5.1**: Code Brain 개선
- 실행 결과 수집 (성공/실패 패턴)
- Claude 리뷰 피드백 학습
- LoRA/QLoRA 기반 파인튜닝
- 개선 주기: 매일 (외부 작업 없을 때)

**FR-PRS-5.2**: Vision Brain 개선
- 성능 실험 데이터 재분석
- 파라미터-성능 관계 학습
- CUDA/TRT 최신 기법 자동 적용

**FR-PRS-5.3**: 개선 작업 중단 가능성
- 외부 작업 수신 시 즉시 Idle Improvement 중단
- 중단된 작업 상태 저장
- 외부 작업 완료 후 재개 가능

**수락 기준**:
- Idle Improvement 활성화 상태: 외부 작업 없을 때 100%
- 중단 응답 시간: < 5초

---

### FR-PRS-6: 보고서 생성 (Report Generation)

**우선순위**: P1 (중요)

**설명**: 작업 완료 후 실행 결과 보고서를 생성해야 합니다.

**요구사항**:

**FR-PRS-6.1**: 코드 생성 보고서
- 생성된 파일 목록
- 각 파일의 라인 수
- 테스트 결과 (pass/fail, coverage)
- 실행 시간

**FR-PRS-6.2**: Vision Brain 성능 보고서
- 실험 설정 (모델, 파라미터)
- 성능 메트릭 (latency, throughput)
- 수치 안정성 분석
- 하드웨어 효율

**FR-PRS-6.3**: 보고서 형식
- Markdown 형식
- JSON 형식 (CI/CD 연동용)
- 로그 파일: `/gx10/runtime/logs/reports/`

**수락 기준**:
- 보고서 생성률: 100%
- 보고서 생성 시간: < 10초

---

### FR-PRS-7: 웹 인터페이스 (Web Interface)

**우선순위**: P2 (낮음)

**설명**: Open WebUI를 통해 Code Brain과 상호작용할 수 있어야 합니다.

**요구사항**:

**FR-PRS-7.1**: Open WebUI 제공
- URL: `http://<gx10-ip>:8080`
- Ollama API와 통합
- 채팅 인터페이스
- 코드 하이라이팅

**FR-PRS-7.2**: 기본 기능
- 모델 선택 (qwen2.5-coder:32b, :7b)
- 대화 기록 저장
- 코드 조각 테스트

**수락 기준**:
- 웹 인터페이스 응답 시간: < 2초
- 가동률: 95%+ (선택사항)

---

## Non-Functional Requirements

### NFR-PRS-1: 신뢰성 (Reliability)

**우선순위**: P0 (필수)

**요구사항**:

**NFR-PRS-1.1**: 시스템 가동률
- Code Brain 가동률: 99%+ (월간)
- Vision Brain 가동률: 95%+ (월간)
- API 가동률: 99.9%+ (월간)

**NFR-PRS-1.2**: 장애 복구 시간
- Brain 전환 실패 후 복구: < 1분
- 메모리 부족 후 복구: < 5분
- API 실패 후 재시도: 자동 (최대 3회)

**NFR-PRS-1.3**: 데이터 보존
- Execution Plan 영구 저장
- 작업 로그 영구 저장
- 보고서 영구 저장
- 백업 주기: 매일

---

### NFR-PRS-2: 성능 (Performance)

**우선순위**: P0 (필수)

**요구사항**:

**NFR-PRS-2.1**: 응답 시간
- API 응답 시간: < 1초
- Brain 전환 시간: < 30초
- Execution Plan 처리 시작 시간: < 5초

**NFR-PRS-2.2**: 처리량
- Code Brain: 동시 처리 가능한 작업 없음 (단일 작업)
- Vision Brain: 동시 처리 가능한 작업 없음 (단일 작업)
- API: 최소 10 req/s

**NFR-PRS-2.3**: 리소스 사용
- Code Brain 메모리: 30-40GB
- Vision Brain 메모리: 70-90GB
- CPU 사용률: < 80% (Idle 시)

---

### NFR-PRS-3: 확장성 (Scalability)

**우선순위**: P1 (중요)

**요구사항**:

**NFR-PRS-3.1**: 모델 교체 용이성
- 새로운 모델 추가: < 1시간 (다운로드 시간 제외)
- 모델 버전 관리 지원
- 롤백 기능: < 5분

**NFR-PRS-3.2**: 프로젝트 크기 지원
- 최대 파일 수: 1,000개
- 최대 코드 라인 수: 100,000줄
- 최대 Execution Plan 크기: 10MB

---

### NFR-PRS-4: 보안 (Security)

**우선순위**: P0 (필수)

**요구사항**:

**NFR-PRS-4.1**: 인증 및 인가
- JWT 기반 인증
- 역할 기반 접근 제어 (RBAC)
- API 토큰 만료: 24시간

**NFR-PRS-4.2**: 네트워크 보안
- HTTPS 지원 (선택사항)
- API Rate Limiting: 100 req/min/IP
- 방화벽: 필요 포트만 개방 (SSH, 11434, 8080, 5678)

**NFR-PRS-4.3**: 데이터 프라이버시
- 코드가 외부 서버로 전송되지 않음
- 로그에서 민감 정보 마스킹
- 사용자 데이터 암호화 (저장 시)

---

### NFR-PRS-5: 유지보수성 (Maintainability)

**우선순위**: P0 (필수)

**요구사항**:

**NFR-PRS-5.1**: 코드 품질
- TRUST 5 기준 준수
- 코드 커버리지: 85%+
- 복잡도: 순환 복잡도 < 15

**NFR-PRS-5.2**: 문서화
- API 문서: OpenAPI 3.0/Swagger
- 사용자 매뉴얼: Markdown
- 개발자 가이드: Markdown

**NFR-PRS-5.3**: 모니터링
- 시스템 상태 모니터링 (CPU, Memory, GPU)
- 로그 수집: JSON 형식
- 성능 메트릭: Prometheus 호환 (선택사항)

---

### NFR-PRS-6: 결정론적 동작 (Deterministic Behavior)

**우선순위**: P0 (필수)

**요구사항**:

**NFR-PRS-6.1**: 재현성 보장
- 동일 Execution Plan → 동일 출력 (100%)
- 난수 생성자 시드 고정
- 모델 temperature 설정: 0 (결정론적)

**NFR-PRS-6.2**: 버전 관리
- 사용된 모델 버전 기록
- Execution Plan 버전 관리
- 생성된 코드 버전 관리 (Git)

---

## Interface Requirements

### IR-PRS-1: 사용자 인터페이스 (User Interface)

**명령행 인터페이스 (CLI)**:
- `/gx10/api/status.sh`: Brain 상태 조회
- `/gx10/api/switch.sh [code|vision]`: Brain 전환
- `ollama run <model>`: 직접 모델 실행

**웹 인터페이스**:
- Open WebUI: `http://<gx10-ip>:8080`
- n8n: `http://<gx10-ip>:5678`

---

### IR-PRS-2: API 인터페이스 (API Interface)

**REST API**:
- Base URL: `http://<gx10-ip>:8080/api`
- 인증: JWT Bearer Token
- 포맷: JSON

**주요 엔드포인트**:
- `GET /api/brain/status`: Brain 상태 조회
- `POST /api/brain/switch`: Brain 전환
- `POST /api/task/execute`: 작업 제출
- `GET /api/task/{task_id}`: 작업 상태 조회
- `GET /api/task/{task_id}/logs`: 작업 로그 조회

---

### IR-PRS-3: 하드웨어 인터페이스 (Hardware Interface)

**GPU**:
- NVIDIA GB10 GPU
- CUDA 12.x / 13.x
- VRAM: 48GB (최대 76GB with TensorRT)

**메모리**:
- 128GB LPDDR5x Unified Memory
- 대역폭: 273 GB/s

**스토리지**:
- 1TB NVMe SSD
- 최소 여유 공간: 100GB

---

## Data Requirements

### DR-PRS-1: Execution Plan 데이터

**형식**: JSON 또는 YAML

**필수 필드**:
- project_name (string)
- version (string, semantic versioning)
- root_dir (string, absolute path)
- files (array, minItems: 1)
- tests (array, minItems: 1)

**스키마**: GX10-06-Comprehensive-Guide.md 참조

---

### DR-PRS-2: 로그 데이터

**형식**: JSON Lines (JSONL)

**필드**:
- timestamp (ISO 8601)
- level (INFO, WARNING, ERROR)
- message (string)
- context (object, optional)

**저장 위치**:
- `/gx10/runtime/logs/{brain}/{date}.jsonl`

---

### DR-PRS-3: 보고서 데이터

**형식**: Markdown 또는 JSON

**필드**:
- task_id (string)
- status (success, failed)
- result (object)
- duration_seconds (number)
- timestamp (ISO 8601)

**저장 위치**:
- `/gx10/runtime/logs/reports/{task_id}.md`

---

## Open Items

### TBD (To Be Determined)

1. **GUI 명세**
   - 현재: CLI와 웹 인터페이스만 제공
   - 검토: 전용 GUI 필요 여부 (우선순위: P2)

2. **멀티 GX10 지원**
   - 현재: 단일 GX10 시스템
   - 검토: 분산 처리 가능성 (우선순위: P3)

3. **모델 성능 벤치마크**
   - 현재: 정성적 평가
   - 검토: 정량적 벤치마크 기준 (우선순위: P1)

---

## 📝 문서 정보

**작성자**:
- AI: Claude Sonnet 4.5
- 환경: MoAI-ADK v11.0.0
- 작성일: 2026-02-01

**리뷰어**:
- drake

---

## 📜 수정 이력

| 일자 | 버전 | 설명 | 리뷰어 |
|------|------|------|--------|
| 2026-02-01 | 1.0 | 기존 문서 기반 전면 보완 | drake |
