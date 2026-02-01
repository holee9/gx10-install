# Product Requirements Document (PRD)

## Status
- Overall: COMPLETE
- Core concept: COMPLETE
- Feature details: COMPLETE

## Table of Contents
1. [Product Vision](#product-vision)
2. [Product Goals](#product-goals)
3. [Key Features](#key-features)
4. [User Stories](#user-stories)
5. [Non-Goals](#non-goals)
6. [Assumptions and Constraints](#assumptions-and-constraints)
7. [Open Features](#open-features)
8. [Success Metrics](#success-metrics)

---

## Product Vision

**Vision Statement**: 제어 가능한 AI 자동화와 장기 유지보수가 가능한 고품질 코드 생산을 통해, 개발자는 창의적인 설계에 집중하고 반복적 구현은 GX10 시스템에 위임하는 개발 패러다임을 구현합니다.

### 핵심 가치 제안

1. **Quality-First Architecture**
   - 코드 품질이 개발 속도보다 우선
   - TRUST 5 품질 기준 준수 (Tested, Readable, Unified, Secured, Trackable)
   - 장기 유지보수성 보장

2. **Controlled Autonomy**
   - Execution Plan을 통한 완전한 제어
   - 임의 판단(Arbitrary Decision) 금지
   - 결정론적 출력 보장

3. **Cost-Effective Operation**
   - 일회성 하드웨어 투자
   - 월간 구독비 $0
   - 오프라인 작업 가능

4. **Continuous Evolution**
   - Idle Improvement로 지속적 모델 개선
   - 프로젝트 특정 요구사항에 맞는 커스터마이징

---

## Product Goals

### PG-1: 코드 품질 최우선 (Code Quality First)

**우선순위**: P0 (필수)

**설명**: 모든 기능과 결정은 코드 품질을 기준으로 합니다. 개발 속도나 편의성은 부차 목표입니다.

**성공 기준**:
- TRUST 5 품질 기준 100% 준수
- 코드 커버리지 85%+ 달성
- 리팩토링 내성 테스트 통과
- Claude Code 2차 리뷰 통과

### PG-2: Two Brain 아키텍처 구현 (Two Brain Architecture)

**우선순위**: P0 (필수)

**설명**: Code Brain(코딩 실행)과 Vision Brain(검증)을 분리하여 전문화된 역할 수행.

**성공 기준**:
- 단일 Brain만 실행 가능 (동시 실행 금지)
- Brain 전환 시간 < 30초
- Code Brain: 30-40GB 메모리 사용
- Vision Brain: 70-90GB 메모리 사용

### PG-3: Agent Coding 파이프라인 구현 (Agent Coding Pipeline)

**우선순위**: P0 (필수)

**설명**: Claude Code(설계) → GX10(구현) → Claude Code(리뷰) → Warp(실행) 파이프라인 구현.

**성공 기준**:
- 각 단계 명확히 분리
- Execution Plan 기반 GX10 작업
- 2차 리뷰로 품질 보장

### PG-4: Execution Plan 시스템 (Execution Plan System)

**우선순위**: P0 (필수)

**설명**: GX10은 Execution Plan 없이 작업하지 않으며, 계획에 따라만 실행합니다.

**성공 기준**:
- JSON/YAML Execution Plan 스키마 정의
- 파일별 책임, 의존성, 구현 순서 명시
- 동일 Plan → 동일 출력 (재현성)

### PG-5: 자동화 파이프라인 지원 (Automation Pipeline Support)

**우선순위**: P1 (중요)

**설명**: CI/CD, MCP, n8n과 통합 가능한 REST API 제공.

**성공 기준**:
- Brain 상태 조회 API
- Brain 전환 API
- 작업 실행 및 상태 조회 API
- Webhook 기반 알림

### PG-6: Idle Improvement (지속적 개선)

**우선순위**: P1 (중요)

**설명**: 외부 작업 없을 때 자동으로 모델을 개선합니다.

**성공 기준**:
- 실행 결과 학습
- 테스트 성공/실패 피드백
- Claude 리뷰 반영
- LoRA/QLoRA 파인튜닝 지원

---

## Key Features

### 1. Code Brain (코드 생성 엔진)

**설명**: Execution Plan을 입력받아 코드 구현을 끝까지 책임지는 로컬 실행 엔진.

**주요 기능**:
- 디렉토리 생성
- 파일 생성 및 수정
- 다파일 동시 구현
- 테스트 실패 시 재수정
- 리팩토링
- 컨텍스트 유지 (128K 토큰)

**기술 사양**:
- Native 실행 (Docker 오버헤드 회피)
- Ollama + Qwen2.5-Coder-32B (메인)
- Ollama + Qwen2.5-Coder-7B (빠른 응답)
- DeepSeek-Coder-V2-16B (수학/논리)
- 메모리: 30-40GB

**하지 않는 작업**:
- 요구사항 해석 ❌
- 아키텍처 설계 ❌
- 임의 판단 ❌

### 2. Vision Brain (검증 엔진)

**설명**: 영상처리 알고리즘의 성능을 검증하고 실험하는 엔진.

**주요 기능**:
- CUDA / TensorRT 실험
- latency / throughput 측정
- 성능 리포트 생성
- 모델 비교 검증

**기술 사양**:
- Docker 실행 (의존성 관리)
- Qwen2.5-VL-72B (고품질 분석)
- Qwen2.5-VL-7B (빠른 확인)
- YOLOv8x (Object Detection)
- SAM2-Large (Segmentation)
- Depth-Anything-V2 (Depth Estimation)
- 메모리: 70-90GB

**판단 기준**:
- 성능 재현성
- 수치 안정성
- 파라미터 영향
- 하드웨어 효율

### 3. Brain 전환 시스템 (Brain Switching System)

**설명**: Code Brain과 Vision Brain을 상황에 따라 전환하는 시스템.

**전환 절차**:
1. 현재 Brain 상태 조회
2. 요청 작업과 Brain 적합성 검사
3. 불일치 시 경고 및 Brain 전환
4. Buffer Cache 플러시 (필수!)
5. 목표 Brain 시작
6. 헬스체크 통과 후 실행

**기술 제약**:
- 단일 Brain만 실행 가능
- Code + Vision 동시 실행 금지
- 전환 시 Buffer Cache 플러시 필수

### 4. Execution Plan 인터페이스 (Execution Plan Interface)

**설명**: 개발자 PC 또는 상위 AI(Claude Code)가 작성하는 계획서.

**필수 포함 항목**:
- 프로젝트 이름, 버전
- 루트 디렉토리
- 제약 조건 (언어, 프레임워크, 스타일 가이드)
- 파일 목록 (경로, 책임, 의존성, 테스트 타겟)
- 구현 순서
- 테스트 기준 (명령, 성공 조건, 재시도 정책)
- 품질 게이트 (커버리지, 금지 패턴)

**스키마**: JSON Schema v1.0 (GX10-06-Comprehensive-Guide.md 참조)

### 5. REST API (REST API)

**설명**: 외부 시스템(CI/CD, MCP, n8n)에서 GX10을 제어하는 API.

**주요 엔드포인트**:
- `GET /api/brain/status`: Brain 상태 조회
- `POST /api/brain/switch`: Brain 전환
- `POST /api/task/execute`: 작업 제출
- `GET /api/task/{task_id}`: 작업 상태 조회

**인증**: JWT Bearer Token

**역할 기반 접근 제어 (RBAC)**:
- developer: 작업 제출, 상태 조회
- data_scientist: Vision Brain 전환, 벤치마크 실행
- admin: 모든 API 접근
- ci_cd: 작업 제출 (긴 timeout)

### 6. Idle Improvement (Idle Improvement)

**설명**: 외부 작업 지시가 없을 때 GX10이 자동으로 모델 성능을 향상.

**Code Brain 개선**:
- 실행 결과 수집
- 테스트 실패/성공 패턴 학습
- Claude 리뷰 피드백 반영
- 리팩토링 전/후 비교
- LoRA / QLoRA 기반 업데이트

**Vision Brain 개선**:
- 성능 실험 재분석
- 파라미터-성능 관계 학습
- CUDA / TRT 최신 기법 리서치

**우선순위**:
1. 외부 작업 지시 최우선
2. Idle Improvement는 즉시 중단 가능
3. 작업 종료 후 결과는 학습 데이터로 저장

### 7. Open WebUI (Open WebUI)

**설명**: Ollama와 통합된 웹 기반 채팅 인터페이스.

**기능**:
- Code Brain과 대화형 상호작용
- 코드 조각 테스트
- 빠른 프로토타이핑

**접속**: `http://<gx10-ip>:8080`

### 8. n8n 연동 (n8n Integration)

**설명**: 무인 자동화 워크플로우 도구와 통합.

**사용 시나리오**:
- GitHub Push → Code Brain 실행
- 주기적 성능 벤치마크
- 알림 및 보고

**접속**: `http://<gx10-ip>:5678`

---

## User Stories

### US-1: 시니어 개발자 - 신규 서비스 개발

**As a** 시니어 개발자
**I want to** Execution Plan을 작성하여 GX10에 코드 구현을 위임
**So that** 나는 아키텍처 설계와 코드 리뷰에 집중할 수 있다

**Acceptance Criteria**:
- Execution Plan YAML 파일 작성
- GX10 API에 작업 제출
- 구현된 코드 수신
- Claude Code로 2차 리뷰
- 테스트 통과 확인

### US-2: 연구 엔지니어 - 모델 성능 검증

**As a** 연구 엔지니어
**I want to** Vision Brain을 활성화하여 YOLO 모델 성능을 비교
**So that** 최적의 모델을 선택할 수 있다

**Acceptance Criteria**:
- Vision Brain 전환 (`/gx10/api/switch.sh vision`)
- 벤치마크 Execution Plan 작성
- 작업 제출 및 결과 수신
- Jupyter Notebook에서 결과 시각화

### US-3: DevOps 엔지니어 - CI/CD 통합

**As a** DevOps 엔지니어
**I want to** GitHub Webhook을 통해 GX10 Code Brain을 자동 실행
**So that** 코드 푸시 시 자동으로 리팩토링된 코드를 받을 수 있다

**Acceptance Criteria**:
- GitHub Webhook 설정
- n8n 워크플로우 구성
- GX10 API 연동
- Slack에 결과 알림

### US-4: 테크리드 - 코드 품질 검증

**As a** 테크리드
**I want to** 팀이 작성한 Execution Plan을 검토하고 GX10 결과를 확인
**So that** 코드 품질 기준을 준수하는지 확인할 수 있다

**Acceptance Criteria**:
- Execution Plan 리뷰
- 생성된 코드 검토
- 테스트 커버리지 확인
- Claude Code 리뷰 의견 확인

---

## Non-Goals

명확한 비목표 (하지 않을 것):

### NG-1: 인간 개발자의 역할 대체
- ❌ 아키텍처 설계 자동화
- ❌ 요구사항 해석 자동화
- ❌ 비즈니스 로직 판단
- ✅ 반복적 구현 작업 자동화

### NG-2: 실시간 채팅 UX
- ❌ ChatGPT 같은 대화형 인터페이스
- ❌ IDE 내장 자동완성 (VS Code 확장)
- ✅ Open WebUI (선택사항)

### NG-3: 소비자용 IDE 기능
- ❌ 구문 강조 (Syntax Highlighting)
- ❌ 코드 네비게이션
- ❌ 디버깅 도구
- ✅ 코드 생성 및 수정

### NG-4: 완전 무인 자동화
- ❌ 요구사항 자동 발견
- ❌ 아키텍처 자동 설계
- ✅ Execution Plan 기반 실행

---

## Assumptions and Constraints

### Assumptions (가정)

1. **하드웨어**: ASUS GX10 (ARM v9.2, 128GB UMA, NVIDIA GB10 GPU) 사용 가능
2. **운영체제**: DGX OS (Ubuntu 24.04 기반) 프리인스톨
3. **네트워크**: 인터넷 연결 가능 (초기 설정 및 모델 다운로드)
4. **개발자 PC**: Claude Code, VS Code, Warp 터미널 사용 가능
5. **사용자**: 시니어 개발자 수준의 기술적 이해도

### Constraints (제약)

1. **단일 Brain 실행**: Code Brain과 Vision Brain은 동시에 실행 불가
2. **메모리 한계**: 128GB Unified Memory 공유
3. **결정론적 동작**: Execution Plan 없이 임의 판단 금지
4. **오프라인 우선**: 클라우드 API 호출 최소화
5. **코드 품질 최우선**: 속도나 편의성보다 품질 우선

---

## Open Features

### TBD (To Be Determined)

1. **웹 대시보드 (Web Dashboard)**
   - 현재: 명령행 기반 제어
   - 검토: 시각적 상태 모니터링, 작업 큐 관리 필요 여부
   - 우선순위: P2 (낮음)

2. **모델 마켓플레이스 (Model Marketplace)**
   - 현재: Qwen, DeepSeek만 지원
   - 검토: 추가 모델 (Llama, CodeLlama) 지원 우선순위
   - 우선순위: P2 (낮음)

3. **멀티 GX10 지원 (Multi-GX10 Support)**
   - 현재: 단일 GX10 시스템
   - 검토: 분산 처리 가능성
   - 우선순위: P3 (매우 낮음)

4. **GUI Execution Plan 에디터**
   - 현재: YAML/JSON 텍스트 편집
   - 검토: 시각적 계획 도구 필요 여부
   - 우선순위: P2 (낮음)

---

## Success Metrics

### 제품 성공 지표

#### Primary Metrics (P0)

1. **코드 품질 (Code Quality)**
   - TRUST 5 준수율: 100%
   - 코드 커버리지: 85%+
   - 리팩토링 내성: 100% (기존 테스트 통과)

2. **제어 가능성 (Controllability)**
   - 동일 Plan → 동일 출력: 100% 재현성
   - 임의 판단 없음: 0건

3. **비용 효율성 (Cost Efficiency)**
   - 월간 구독비: $0
   - 일회성 하드웨어 비용: $3,000-5,000

#### Secondary Metrics (P1)

4. **자동화 효율성 (Automation Efficiency)**
   - Execution Plan → 구현 완료: < 30분 (소규모 프로젝트)
   - Brain 전환 시간: < 30초
   - API 응답 시간: < 1초

5. **모델 개선 (Model Improvement)**
   - Idle Improvement 주기: 매일 (외부 작업 없을 때)
   - LoRA 파인튜닝 성능 향상: 측정 필요

6. **사용자 만족도 (User Satisfaction)**
   - 시니어 개발자 채택률: TBD
   - 코드 리뷰 시간 단축: TBD
   - 장기 프로젝트 유지보수성 향상: TBD

### 릴리스 기준

**MVP (Minimum Viable Product)**:
- ✅ Code Brain 실행 가능
- ✅ Vision Brain 실행 가능
- ✅ Brain 전환 기능
- ✅ Execution Plan 스키마
- ✅ REST API (기본 4개)
- ✅ Open WebUI (선택)

**v1.0 정식 릴리스**:
- MVP 완료
- ✅ 자동 구축 스크립트 (10단계)
- ✅ n8n 연동
- ✅ Idle Improvement (기본)
- ✅ 문서 완료 (MRD, PRD, SRS, FRS, Test Plan)

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
