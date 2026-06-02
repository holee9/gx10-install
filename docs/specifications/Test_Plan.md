# Test Plan

## Status
- Overall: COMPLETE
- Unit Tests: COMPLETE
- Integration Tests: COMPLETE
- Performance Tests: COMPLETE
- Entry/Exit Criteria: COMPLETE

## Table of Contents
1. [Introduction](#introduction)
2. [Test Types](#test-types)
3. [Test Environment Setup](#test-environment-setup)
4. [Unit Testing](#unit-testing)
5. [Integration Testing](#integration-testing)
6. [Performance Testing](#performance-testing)
7. [Stress Testing](#stress-testing)
8. [Entry Criteria](#entry-criteria)
9. [Exit Criteria](#exit-criteria)
10. [Test Schedule](#test-schedule)
11. [Open Items](#open-items)

---

## Introduction

### 문서 목적

본 문서는 GX10 시스템의 테스트 전략, 절차, 기준을 정의합니다.

---

## 문서 계층 구조

### 상위 문서
- [MRD.md](MRD.md) (DOC-MRD-001) - Market Requirements Document
- [PRD.md](PRD.md) (DOC-PRD-001) - Product Requirements Document
- [PRS.md](PRS.md) (DOC-PRS-001) - Product Requirements Specification
- [SRS.md](SRS.md) (DOC-SRS-001) - System Requirements Specification

### 동급 문서
- [FRS.md](FRS.md) (DOC-FRS-001) - Functional Requirements Specification

### 하위 문서
없음

### 관련 문서
- [../GX10-04-Build-Checklist.md](../GX10-04-Build-Checklist.md) - 빌드 체크리스트

---

## Test Types

### TT-1: 단위 테스트 (Unit Tests)

**범위**: 개별 모듈/컴포넌트

**목적**: 개별 기능의 정확성 검증

---

### TT-2: 통합 테스트 (Integration Tests)

**범위**: 모듈 간 상호작용

**목적**: 시스템 전체 동작 검증

---

### TT-3: 성능 테스트 (Performance Tests)

**범위**: 시스템 응답 시간, 처리량

**목적**: 성능 요구사항 충족 확인

---

### TT-4: 스트레스 테스트 (Stress Tests)

**범위**: 고부하 상황에서의 시스템 동작

**목적**: 한계치 식별 및 안정성 확인

---

## Test Environment Setup

### TE-1: 하드웨어 환경

**ASUS GX10**:
- ARM v9.2-A CPU (20-core)
- NVIDIA GB10 GPU
- 128GB UMA
- 1TB NVMe SSD

**주변 장치**:
- 키보드, 마우스 (초기 설정용)
- 이더넷 케이블 (고정 IP 권장)

---

### TE-2: 소프트웨어 환경

**운영체제**: DGX OS (Ubuntu 24.04 기반)

**필수 패키지**:
- Docker 24.x+
- Ollama 0.5+
- Python 3.11+
- pytest (Python 테스트)
- Jest (JavaScript 테스트, 선택사항)

**테스트 도구**:
- 코드 커버리지: pytest-cov, coverage
- API 테스트: Postman, curl
- 모니터링: htop, nvidia-smi

---

### TE-3: 테스트 데이터

**Execution Plan 예제**:
- 간단한 프로젝트 (3-5파일)
- 중간 규모 프로젝트 (10-20파일)
- 대규모 프로젝트 (50+파일)

**테스트 케이스**:
- 정상 케이스
- 경계 케이스 (빈 파일, 순환 의존성)
- 에러 케이스 (잘못된 타입, 누락 필드)

---

## Unit Testing

### UT-1: Execution Plan 검증 (Execution Plan Validation)

**테스트 케이스**:

| ID | 케이스 | 입력 | 기대 결과 |
|----|----|------|------|
| UT-EP-01 | 유효한 JSON 형식 | 검증 성공 |
| UT-EP-02 | 유효한 YAML 형식 | 검증 성공 |
| UT-EP-03 | 필수 필드 누락 | 에러 반환 |
| UT-EP-04 | 잘못된 데이터 타입 | 에러 반환 |
| UT-EP-05 | 순환 의존성 | 에러 반환 |

**검증 방법**:
- 자동화된 스크립트로 실행
- pytest 프레임워크 사용
- 커버리지: 100%

---

### UT-2: Brain 전환 테스트 (Brain Switching Tests)

**테스트 케이스**:

| ID | 케이스 | 입력 | 기대 결과 |
|----|----|------|------|
| UT-BS-01 | Code → Vision 전환 | 전환 성공, < 30초 |
| UT-BS-02 | Vision → Code 전환 | 전환 성공, < 30초 |
| UT-BS-03 | 동일 Brain 재전환 시도 | 에러 반환 (409) |
| UT-BS-04 | 잘못된 Brain 이름 | 에러 반환 (400) |
| UT-BS-05 | Buffer Cache 플러시 확인 | 메모리 확보 |

**검증 방법**:
- 자동화된 스크립트로 실행
- 전환 시간 측정
- 메모리 사용량 모니터링�

---

### UT-3: API 테스트 (API Tests)

**테스트 케이스**:

| ID | 케이스 | 엔드포인트 | 기대 결과 |
|----|----|------|------|
| UT-API-01 | Brain 상태 조회 | GET /api/brain/status | 200 OK |
| UT-API-02 | Brain 전환 | POST /api/brain/switch | 200 OK |
| UT-API-03 | 작업 제출 | POST /api/task/execute | 202 Accepted |
| UT-API-04 | 작업 상태 조회 | GET /api/task/{task_id} | 200 OK |
| UT-API-05 | 인증 없는 요청 | 401 Unauthorized | 401 Unauthorized |
| UT-API-06 | Rate Limit 초과 | >100 req/min | 429 Too Many Requests |

**검증 방법**:
- Postman Collection 또는 curl 스크립트
- API 응답 시간 측정
- 응답 데이터 스키마 검증

---

## Integration Testing

### IT-1: End-to-End 코드 생성 테스트 (End-to-End Code Generation Tests)

**테스트 시나리오**: 사용자가 Execution Plan을 작성하여 GX10에 코드 구현을 의뢰

**테스트 단계**:

1. **준비**
   - Execution Plan 작성 (YAML)
   - GX10 Code Brain 활성화 확인

2. **실행**
   - 작업 제출 API 호출
   - task_id 수신

3. **모니터링**
   - 작업 상태 주기적 폴링
   - 진행률 확인 (0-100%)

4. **검증**
   - 생성된 파일 확인
   - 테스트 결과 확인
   - 보고서 확인

**성공 기준**:
- 모든 파일이 올바른 위치에 생성
- 테스트 커버리지 85%+ 달성
- 보고서가 정확히 생성됨

---

### IT-2: Brain 전환 통합 테스트 (Brain Switching Integration Tests)

**테스트 시나리오**: Code Brain → Vision Brain → Code Brain 전환

**테스트 단계**:

1. **초기 상태**: Code Brain 활성화
2. **전환 1**: Vision Brain로 전환
3. **검증 1**: Vision Brain 실행 중
4. **전환 2**: Code Brain로 재전환
5. **검증 2**: Code Brain 실행 중
6. **최종 검증**: 모든 전환 성공, Buffer Cache 플러시 확인

**성공 기준**:
- 모든 전환 < 30초
- 메모리 오류 발생 없음
- 각 Brain 정상 작동

---

### IT-3: 자동화 파이프라인 통합 테스트 (Automation Pipeline Integration Tests)

**테스트 시나리오**: GitHub Webhook → n8n → GX10 → Slack 알림

**테스트 단계**:

1. **GitHub Webhook 설정**
2. **n8n 워크플로우 구성**
   - Webhook 수신
   - Execution Plan 생성
   - GX10 Code Brain 호출
   - 결과 알림

**성공 기준**:
- Webhook 정상 수신
- Execution Plan 자동 생성
- Code Brain 작업 성공
- Slack 알림 전송

---

## Performance Testing

### PE-1: API 응답 시간 테스트 (API Response Time Tests)

**목표**:
- Brain 상태 조회: < 1초 (P99)
- Brain 전환: < 30초 (P95)
- 작업 제출: < 5초 (P95)

**테스트 방법**:
- Apache Bench (ab)
- Locust
- 부하 테스트: 10, 100, 1000 concurrent users

**성공 기준**:
- P95 응답 시간 목표 충족
- P99 응답 시간 < 2배 목표

---

### PE-2: 코드 생성 성능 테스트 (Code Generation Performance Tests)

**목표**:
- 소규모 프로젝트 (< 10파일): < 30분
- 중규모 프로젝트 (10-50파일): < 2시간

**테스트 데이터**:
- 간단한 REST API (5파일)
- 중간 규모 CRUD 서비스 (20파일)

**성공 기준**:
- 목표 시간 내 코드 생성 완료
- 테스트 커버리지 85%+ 달성

---

### PE-3: Vision Brain 성능 테스트 (Vision Brain Performance Tests)

**목표**:
- YOLOv8 추론: TBD
- Qwen2.5-VL 추론: TBD

**테스트 시나리오**:
- 이미지 배치 처리 (YOLOv8)
- 비디오 프레임 분석 (Qwen2.5-VL)

**성공 기준**:
- 실시간 처리 가능 (30 FPS 이상)
- 메모리 사용량 < 90GB

---

## Stress Testing

### ST-1: 메모리 부하 테스트 (Memory Load Test)

**목적**: 메모리 한계 식별

**테스트 방법**:
- 대형 모델 동시 로드 시도
- 반복 작업 제출

**예상 시나리오**:
- kqwen-coder:latest 로드
- qwen2.5-vl:72B 로드 (Code Brain 정지 후)

**기대 결과**:
- OOM (Out of Memory) 발생 지점 식별
- Graceful degradation 확인
- 자동 복구 메커니즘 확인

---

### ST-2: API 부하 테스트 (API Load Test)

**목적**: API 한계 식별

**테스트 방법**:
- Locust 또는 Apache Bench
- 점진적 부하 증가: 10 → 100 → 1000 req/min

**기대 결과**:
- 최대 처리량 식별
- 병목 지점 식별
- Rate Limiting 동작 확인

---

### ST-3: 장기 실행 안정성 테스트 (Long-Running Stability Test)

**목적**: 메모리 누수, 안정성 확인

**테스트 방법**:
- 24시간 연속 실행
- 매시간 간단 작업 제출
- 메모리 사용량 모니터링

**기대 결과**:
- 메모리 누수 없음
- 자동 복구 동작
- 서비스 중단 없음

---

## Entry Criteria

### EC-1: Execution Plan 유효성

- Execution Plan 파일 존재
- 스키마 유효성 검증 통과
- 필수 필드 모두 포함

---

### EC-2: 환경 구축 완료

- GX10 하드웨어 설정 완료
- Docker, Ollama 설치 완료
- 필요한 모델 다운로드 완료

---

### EC-3: 테스트 데이터 준비

- 테스트 Execution Plan 작성
- 예상 결과 정의
- 테스트 데이터 준비

---

### EC-4: 테스트 도구 설치

- pytest, coverage 설치
- API 테스트 도구 설치 (Postman, curl)
- 모니터링 도구 준비 (htop, nvidia-smi)

---

## Exit Criteria

### EX-1: 모든 테스트 통과

- 단위 테스트 통과률: 100%
- 통합 테스트 통과률: 100%
- 성능 테스트 목표 달성
- 스트레스 테스트 기준 충족

---

### EX-2: 코드 품질 기준 충족

- TRUST 5 기준 100% 준수
- 코드 커버리지 85%+ 달성
- 리팩토링 내성 100% (기존 테스트 통과)

---

### EX-3: 보안 기준 충족

- 인증/인가 정상 작동
- 민감 정보 마스킹 확인
- API Rate Limiting 동작 확인

---

### EX-4: 문서 완료

- 테스트 보고서 작성
- 결함 사항 식별
- 개선 권장 사항 포함

---

## Test Schedule

### 일정 (TBD)

| 단계 | 테스트 유형 | 예상 소요 시간 | 담당자 |
|------|-----------|-----------------|--------|
| 1 | 환경 구축 | 1일 | TBD |
| 2 | 단위 테스트 | 2일 | TBD |
| 3 | 통합 테스트 | 3일 | TBD |
| 4 | 성능 테스트 | 2일 | TBD |
| 5 | 스트레스 테스트 | 2일 | TBD |
| 6 | 보고서 작성 | 1일 | TBD |

**총 예상 시간**: 11일

---

## Open Items

### TBD (To Be Determined)

1. **스트레스 테스트 시나리오**
   - 현재: 기본 시나리오만 정의
   - 필요: 실제 사용 패턴 기반 시나리오
   - 우선순위: P1

2. **성능 벤치마크 기준**
   - 현재: 목표 시간만 정의
   - 필요: 정량적 벤치마크 기준 (Aider, HumanEval)
   - 우선순위: P1

3. **회귀 테스트 자동화**
   - 현재: 수동 테스트만 정의
   - 필요: CI/CD 파이프라인 연동
   - 우선순위: P2

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
