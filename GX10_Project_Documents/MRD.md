# Market Requirements Document (MRD)

## Status
- Overall: COMPLETE

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Market Background](#market-background)
3. [Market Problem](#market-problem)
4. [Target Users](#target-users)
5. [Market Requirements](#market-requirements)
6. [Competitive Analysis](#competitive-analysis)
7. [Market Opportunities](#market-opportunities)
8. [Risks and Mitigation](#risks-and-mitigation)
9. [Open Items](#open-items)

---

## 문서 계층 구조

### 상위 문서
없음 (최상위 문서)

### 동급 문서
없음

### 하위 문서
- [PRD.md](PRD.md) (DOC-PRD-001) - Product Requirements Document
- [PRS.md](PRS.md) (DOC-PRS-001) - Product Requirements Specification
- [SRS.md](SRS.md) (DOC-SRS-001) - System Requirements Specification

### 관련 문서
- [FRS.md](FRS.md) (DOC-FRS-001) - Functional Requirements Specification
- [Test_Plan.md](Test_Plan.md) (DOC-TEST-001) - Test Plan
- [../GX10-03-Final-Implementation-Guide.md](../GX10-03-Final-Implementation-Guide.md) - 최종 구현 가이드
- [../GX10-06-Comprehensive-Guide.md](../GX10-06-Comprehensive-Guide.md) - 종합 가이드
- [../GX10-08-CodeBrain-Memory-Optimization.md](../GX10-08-CodeBrain-Memory-Optimization.md) - Code Brain 메모리 최적화

---

## Executive Summary

GX10 프로젝트는 **장기 유지보수가 가능한 고품질 코드 생산**을 최우선 목표로 하는 로컬 AI 개발 환경 시스템입니다. 클라우드 구독형 AI 코딩 도구의 높은 비용과 제어 불가능성을 해결하기 위해, ASUS GX10 하드웨어와 로컬 LLM을 활용한 완전히 제어 가능한 에이전트 코딩 시스템을 구축합니다.

### 핵심 가치 제안
- **코드 품질 최우선**: 개발 속도, 비용 절감보다 코드 품질 우선
- **구독 비용 최소화**: 일회성 하드웨어 투자 후 로컬 실행
- **제어 가능성**: 실행 계획(Execution Plan)에 따른 결정론적 동작
- **진화 가능성**: Idle Improvement를 통한 지속적 모델 개선

---

## Market Background

### 시장 현황
2025-2026년 기준 AI 코딩 도구 시장은 급속도로 성장하고 있으나 다음과 같은 문제점이 존재합니다:

**1. 클라우드 구독 모델의 한계**
- GitHub Copilot, Claude Code, Cursor 등 월 $10-20 구독료
- 대규모 팀 사용 시 연간 수천만 원 비용 발생
- 데이터 프라이버시 우려 (코드가 클라우드로 전송)
- 인터넷 연결 의존성

**2. 코드 품질 저하 문제**
- AI가 생성한 코드의 즉각적 동작은 가능하나 유지보수성 부족
- 기술 부채 누적으로 장기 프로젝트에서 실패 위험
- 인간 개발자의 리뷰 부담 증가

**3. 제어 불가능성**
- 클라우드 AI 모델의 불투명한 업데이트
- 동일 입력에 대해 일관되지 않은 출력
- 특정 도메인/프로젝트에 맞는 커스터마이징 불가

### 로컬 AI 하드웨어의 부상
- NVIDIA Jetson, Apple Silicon (M-series), ASUS GX10 등 에지 AI 하드웨어 보급
- 로컬 LLM (Llama, Qwen, DeepSeek)의 성능 향상
- 오픈소스 AI 에코시스템 성숙 (Ollama, vLLM, SGLang)

---

## Market Problem

### 문제 정의

**Primary Problem**: 클라우드 구독형 AI 코딩 도구는 장기적인 소프트웨어 프로젝트에서 **코드 품질 저하**와 **높은 구독 비용**이라는 두 가지 핵심 문제를 야기합니다.

**Secondary Problems**:
1. **제어 불가능성**: 비즈니스 임계 프로젝트에서 클라우드 AI 의존은 리스크
2. **오프라인 개발 불가**: 인터넷 연결이 없는 환경에서 개발 불가
3. **커스터마이징 부족**: 프로젝트 특정 요구사항에 맞는 AI 동작 조정 불가
4. **데이터 프라이버시**: 코드가 외부 서버로 전송되는 것에 대한 우려

### 문제 영향
- **소기업/개인 개발자**: 구독비 부담으로 AI 도구 도입 어려움
- **대기업**: 데이터 보안 정책으로 클라우드 AI 사용 제한
- **장기 프로젝트**: AI 생성 코드의 기술 부채 누적으로 프로젝트 실패 위험

---

## Target Users

### 1차 타겟: 시니어 개발자 및 테크리드
**프로필**:
- 5년+ 경력 개발자
- 코드 품질과 장기 유지보수성 중시
- 클라우드 구독비 부담 감수

**니즈**:
- AI 자동화 이점은 유지하면서 코드 품질 보장
- 프로젝트 특정 요구사항에 맞는 AI 동작 제어
- 프라이빗 코드 보호

### 2차 타겟: 연구 엔지니어
**프로필**:
- ML/AI 연구 수행
- 실험적 코드 작성 및 리팩토링 반복
- GPU 자원 필요

**니즈**:
- 로컬 GPU 활용한 빠른 실험
- Vision Brain을 통한 영상처리 알고리즘 검증
- 반복 작업 자동화

### 3차 타겟: DevOps/자동화 엔지니어
**프로필**:
- CI/CD 파이프라인 구축
- MCP (Model Context Protocol), n8n 워크플로우 활용

**니즈**:
- 무인 자동화 파이프라인 통합
- API 기반 GX10 제어
- 안정적인 실행 환경

### 비타겟 (Out of Scope)
- 초보 개발자: AI가 모든 것을 자동으로 해주는 기대
- 실시간 채팅 UX 중시 사용자: ChatGPT 같은 대화형 인터페이스 기대
- IDE 기능 중심 사용자: VS Code 확장 기능 위주의 사용자

---

## Market Requirements

### MR-1: 구독 비용 최소화 (Subscription Cost Minimization)

**우선순위**: P0 (필수)

**설명**: 시스템은 일회성 하드웨어 비용만으로 운영되어야 하며, 월간 구독료가 없어야 합니다.

**측정 기준**:
- 월간 recurring cost: $0
- 일회성 하드웨어 비용: ASUS GX10 ($3,000-5,000 예상)
- 전력 소모: 100-200W (운영 비용 포함)

**관련 기능**:
- 로컬 LLM 실행 (Ollama)
- 클라우드 API 호출 없는 코드 생성
- 오프라인 작업 가능

### MR-2: 코드 품질 우선 (Code Quality First)

**우선순위**: P0 (필수)

**설명**: 개발 속도나 편의성보다 코드 품질이 우선시되어야 합니다.

**측정 기준**:
- TRUST 5 품질 기준 준수 (Tested, Readable, Unified, Secured, Trackable)
- 코드 커버리지 85%+ 목표
- 리팩토링 내성 테스트 통과

**관련 기능**:
- Execution Plan 기반 결정론적 코드 생성
- Claude Code 2차 리뷰 단계
- 특성화 테스트(Characterization Tests) 자동 생성

### MR-3: 제어 가능성 (Controllability)

**우선순위**: P0 (필수)

**설명**: 사용자는 AI의 동작을 Execution Plan을 통해 완전히 제어할 수 있어야 합니다.

**측정 기준**:
- 동일 Execution Plan → 동일 출력 (재현성)
- 임의 판단 금지 (No arbitrary decisions)
- 명시적 파일 구조, 의존성, 테스트 기준

**관련 기능**:
- JSON/YAML Execution Plan 스키마
- 파일별 책임 명세
- 구현 순서 제어

### MR-4: 자동화 파이프라인 지원 (Automation Pipeline Support)

**우선순위**: P1 (중요)

**설명**: CI/CD, MCP, n8n과 같은 자동화 시스템과 통합 가능해야 합니다.

**측정 기준**:
- REST API 기 Brain 제어
- Webhook 기반 작업 제출
- 상태 폴링 및 알림

**관련 기능**:
- Brain 상태 조회 API
- Brain 전환 API
- 작업 실행 및 상태 조회 API

### MR-5: 진화 가능성 (Evolvability)

**우선순위**: P1 (중요)

**설명**: 시스템은 사용 패턴과 피드백을 통해 지속적으로 개선될 수 있어야 합니다.

**측정 기준**:
- Idle Improvement 기능
- LoRA/QLoRA 기반 파인튜닝 지원
- 모델 교체 용이성

**관련 기능**:
- 외부 작업 없을 때 자동 모델 개선
- 실행 결과, 테스트 성공/실패, 리뷰 피드백 학습
- Vision Brain 성능 실험 결과 학습

---

## Competitive Analysis

### 클라우드 AI 코딩 도구와의 비교

| 특성 | GX10 System | GitHub Copilot | Claude Code | Cursor |
|------|-------------|----------------|-------------|--------|
| **구독 비용** | ❌ 없음 | ✅ $10/월 | ✅ $20/월 | ✅ $20/월 |
| **코드 품질** | ✅ Execution Plan 기반 통제 | ⚠️ 일관성 부족 | ⚠️ 일관성 부족 | ⚠️ 일관성 부족 |
| **제어 가능성** | ✅ 완전 제어 | ❌ 불가 | ❌ 불가 | ❌ 불가 |
| **오프라인** | ✅ 가능 | ❌ 불가 | ❌ 불가 | ❌ 불가 |
| **프라이버시** | ✅ 로컬 전용 | ❌ 클라우드 전송 | ❌ 클라우드 전송 | ❌ 클라우드 전송 |
| **커스터마이징** | ✅ Execution Plan | ❌ 불가 | ❌ 불가 | ⚠️ 제한적 |
| **진화 가능성** | ✅ Idle Improvement | ❌ 불가 | ❌ 불가 | ❌ 불가 |

### GX10의 차별화 포인트

1. **Quality-First Architecture**: 속도나 편의성이 아닌 코드 품질 최우선
2. **Two Brain System**: Code Brain (코딩) + Vision Brain (검증) 분리
3. **Execution Plan**: AI가 임의 판단하지 않고 계획에 따라만 실행
4. **Idle Improvement**: 사용하지 않을 때 자동으로 모델 개선

---

## Market Opportunities

### 시장 규모 (TBD)
- **전 세계 개발자**: 27M+ (2024년 기준)
- **시니어 개발자**: 약 30% (8M+)
- **AI 코딩 도구 사용률**: 40-50% (성장 중)
- **로컬 AI 하드웨어 보급**: 가정용/소형 사무용 GPU 장비 보급 확대

### Target Addressable Market (TAM)
**Primary**: 전 세계 시니어 개발자 (8M명)
- 10% 도달 가정: 800K 사용자
- 일회성 하드웨어 비용 $3,000 기준
- 총 시장 기회: $2.4B

### Growth Drivers
1. **구독 피로감**: 클라우드 구독비 부담으로 로컬 솔루션 선호
2. **데이터 프라이버시**: 기업의 코드 보안 정책 강화
3. **로컬 AI 성장**: Llama, Qwen 등 오픈소스 모델 성능 향상
4. **에지 AI 보급**: 가정용 AI 서버 보급 확대

---

## Risks and Mitigation

### Risk 1: 로컬 하드웨어 성능 한계
**설명**: 로컬 LLM이 클라우드 최신 모델(GPT-4, Claude 3.5)보다 성능이 낮을 수 있음

**완화 전략**:
- Qwen2.5-Coder-32B (73.7점 Aider 벤치마크) 사용으로 GPT-4o 수준 달성
- Claude Code를 설계/리뷰 단계에 활용하여 고성능 모델 장점 유지
- 점진적 모델 개선 (Idle Improvement)

### Risk 2: 사용자 채택 장벽
**설명**: Execution Plan 작성, Brain 전환 등 새로운 워크플로우 학습 필요

**완화 전략**:
- 자동 구축 스크립트 (10단계 설치 자동화)
- 상세 문서화 및 가이드 제공
- Open WebUI, n8n 등 친숙한 도구 통합

### Risk 3: 모델 정체 (Model Stagnation)
**설명**: 적절한 피드백 루프 없이 모델이 개선되지 않을 위험

**완화 전략**:
- Idle Improvement 기능으로 지속적 학습
- LoRA/QLoRA 파인튜닝 지원
- 최신 오픈소스 모델로 교체 용이성

### Risk 4: 하드웨어 의존성
**설명**: ASUS GX10 특정 하드웨어에 의존하여 이식성 부족

**완화 전략**:
- Ubuntu 기반으로 타 ARM + GPU 장비로 이식 가능
- Docker 컨테이너화로 환경 독립성 확보
- 요구 사양 최소화 (128GB RAM, GPU)

---

## Open Items

### TBD (To Be Determined)
1. **정량적 시장 규모 분석**: 로컬 AI 개발 환경 시장 규모 조사 필요
2. **가격 정책**: 하드웨어 번들 또는 소프트웨어만 제공 여부
3. **UI/UX 필요성**: 명령행 기반 충분 여부 또는 웹 대시보드 필요
4. **지원 모델 목록**: Qwen 외 지원할 모델 우선순위
5. **성능 벤치마크**: 타 솔루션과의 정량적 비교

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
