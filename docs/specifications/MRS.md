# Market Requirements Specification (MRS)

## Status
- Overall: COMPLETE

## Table of Contents
1. [Introduction](#introduction)
2. [Market-Level Requirements](#market-level-requirements)
3. [Constraints](#constraints)
4. [Risks](#risks)
5. [Open Items](#open-items)

---

## Introduction

### 문서 목적

본 문서는 MRD(Market Requirements Document)에서 정의한 시장 요구사항을 구체적이고 정량적인 명세로 변환합니다.

---

## Market-Level Requirements

### MR-1: 구독 비용 최소화 (Subscription Cost Minimization)

**우선순위**: P0 (필수)

**정량적 요구사항**:
- 월간 recurring cost: $0
- 일회성 하드웨어 비용: $3,000-5,000
- 전력 소모: 100-200W
- ROI 시점: 12-18개월 (클라우드 구독 대비)

**검증 방법**:
- 월간 비용 청구서 확인 (=$0)
- 전력 소모 측정 (와트계)
- 클라우드 구독비와 비교 분석

---

### MR-2: 코드 품질 우선 (Code Quality First)

**우선순위**: P0 (필수)

**정량적 요구사항**:
- TRUST 5 준수율: 100%
- 코드 커버리지: 85%+
- 리팩토링 내성: 100% (기존 테스트 통과)
- Claude Code 2차 리뷰 통과율: 95%+

**정성적 요구사항**:
- 장기 유지보수 가능한 코드 구조
- 명확한 네이밍과 문서화
- 일관된 코딩 스타일

**검증 방법**:
- 코드 리뷰 체크리스트
- 자동화된 품질 게이트
- 정기적 리팩토링 세션

---

### MR-3: 제어 가능성 (Controllability)

**우선순위**: P0 (필수)

**정량적 요구사항**:
- 동일 Execution Plan → 동일 출력: 100% 재현성
- 임의 판단 발생 건수: 0
- Execution Plan 준수율: 100%

**정성적 요구사항**:
- 명시적 파일 구조 제어
- 의존성 순서 준수
- 제약 조건 (언어, 프레임워크) 준수

**검증 방법**:
- 재현성 테스트 (동일 Plan 3회 실행)
- 임의 판단 감지 로그 분석
- Execution Plan 유효성 검증

---

### MR-4: 자동화 파이프라인 지원 (Automation Pipeline Support)

**우선순위**: P1 (중요)

**정량적 요구사항**:
- API 응답 시간: < 1초
- API 가동률: 99.9%+
- Brain 전환 시간: < 30초
- Webhook 처리 시간: < 5초

**정성적 요구사항**:
- CI/CD 도구와 통합 용이성
- n8n 워크플로우 지원
- MCP 프로토콜 지원

**검증 방법**:
- API 성능 테스트 (부하 테스트)
- CI/CD 연동 테스트 (GitHub Actions)
- n8n 워크플로우 예제 실행

---

### MR-5: 진화 가능성 (Evolvability)

**우선순위**: P1 (중요)

**정량적 요구사항**:
- Idle Improvement 주기: 매일 (외부 작업 없을 때)
- LoRA 파인튜닝 시간: < 4시간
- 모델 교체 시간: < 1시간 (다운로드 제외)
- 성능 향상률: 측정 필요 (TBD)

**정성적 요구사항**:
- 실행 결과 학습
- 테스트 성공/실패 패턴 학습
- Claude 리뷰 피드백 반영
- 최신 오픈소스 모델 적용

**검증 방법**:
- Idle Improvement 활성화 확인
- 파인튜닝 전/후 성능 비교
- 학습 곡선 모니터링

---

## Constraints

### C-1: 단일 Brain 실행 제약 (Single Brain Constraint)

**설명**: Code Brain과 Vision Brain은 동시에 실행할 수 없습니다.

**영향**:
- 작업 큐잉 필요
- Brain 전환 오버헤드
- 작업 중단 가능성

**완화 전략**:
- 작업 스케줄링 최적화
- 빠른 Brain 전환 (< 30초)
- 작업 상태 저장 및 재개

---

### C-2: 메모리 한계 제약 (Memory Limitation Constraint)

**설명**: 128GB Unified Memory 공유로 인한 메모리 제한.

**영향**:
- Code Brain: 30-40GB 사용
- Vision Brain: 70-90GB 사용
- Buffer Cache 관리 필요

**완화 전략**:
- Brain 전환 전 Buffer Cache 플러시
- 불필요한 프로세스 종료
- 메모리 사용 모니터링

---

### C-3: 오프라인 우선 제약 (Offline-First Constraint)

**설명**: 클라우드 API 호출 최소화.

**영향**:
- 모델 업데이트가 수동
- 초기 설정에 인터넷 필요

**완화 전략**:
- 로컬 모델 사전 다운로드
- 오프라인 작업 가능성 확인
- 인터넷 연결 상태 모니터링

---

### C-4: 하드웨어 의존성 제약 (Hardware Dependency Constraint)

**설명**: ASUS GX10 특정 하드웨어에 의존.

**영향**:
- 이식성 부족
- 하드웨어 업그레이드 비용

**완화 전략**:
- Ubuntu 기반으로 타 장비 이식 가능
- Docker 컨테이너화로 환경 독립성
- 최소 사양 명시 (128GB RAM, GPU)

---

## Risks

### Risk 1: 모델 정체 (Model Stagnation)

**확률**: 중간 (30%)

**영향**: 높음 (High)

**완화 전략**:
- Idle Improvement 기능으로 지속적 학습
- LoRA/QLoRA 파인튜닝 지원
- 최신 오픈소스 모델로 교체 용이성
- 정기적 모델 성능 벤치마크

**모니터링 지표**:
- 모델 성능 향상률
- Idle Improvement 실행 빈도
- 파인튜닝 횟수

---

### Risk 2: 사용자 채택 장벽 (User Adoption Barrier)

**확률**: 중간 (40%)

**영향**: 중간 (Medium)

**완화 전략**:
- 자동 구축 스크립트 (10단계)
- 상세 문서화 및 가이드
- Open WebUI, n8n 등 친숙한 도구 통합
- 단계별 튜토리얼 제공

**모니터링 지표**:
- 온보딩 완료율
- 첫 Execution Plan 성공률
- 사용자 만족도 설문

---

### Risk 3: 하드웨어 비용 부담 (Hardware Cost Burden)

**확률**: 낮음 (20%)

**영향**: 높음 (High)

**완화 전략**:
- 일회성 투자 강조
- 클라우드 구독비와 비교 분석
- ROI 분석 제공
- 할인 프로그램 (교육 기관, 오픈소스 기여자)

**모니터링 지표**:
- 판매량
- 고객 조사 (비용 부담 정도)
- 경쟁사 가격 비교

---

### Risk 4: 기술 부채 누적 (Technical Debt Accumulation)

**확률**: 낮음 (15%)

**영향**: 높음 (High)

**완화 전략**:
- TRUST 5 품질 기준 준수
- Claude Code 2차 리뷰
- 정기적 리팩토링
- 특성화 테스트 (Characterization Tests)

**모니터링 지표**:
- 코드 복잡도
- 기술 부채 비율
- 리팩토링 주기

---

## Open Items

### TBD (To Be Determined)

1. **시장 규모 정량적 분석**
   - 현재: 정성적 평가만 존재
   - 필요: TAM, SAM, SOM 정량적 수치
   - 우선순위: P2

2. **가격 정책**
   - 현재: 하드웨어 비용만 고려
   - 필요: 소프트웨어만 제공 여부, 구독 모델 추가 여부
   - 우선순위: P1

3. **UI/UX 필요성**
   - 현재: CLI와 웹 인터페이스만 제공
   - 필요: 전용 GUI 필요 여부 평가
   - 우선순위: P2

4. **지원 모델 목록**
   - 현재: Qwen, DeepSeek만 지원
   - 필요: 추가 모델 (Llama, CodeLlama) 우선순위
   - 우선순위: P2

5. **성능 벤치마크 기준**
   - 현재: 정성적 평가
   - 필요: 정량적 벤치마크 기준 (Aider, HumanEval)
   - 우선순위: P1

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
