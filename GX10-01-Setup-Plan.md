# GX10 로컬 AI 개발 환경 구축 가이드


## Revision Histroy

### - Initiate 2026-02-01

---



## 📕 Agent Coding + GX10 Brain 시스템  
### 최종 구현 계획서 (Verified Final v1.0)

---

## 0. 문서 성격 및 사용 규칙

본 문서는 다음 용도로 사용한다.

- 사람 개발자가 따라야 할 **개발·운영 지침**
- AI Agent가 따라야 할 **행동 규칙**
- 자동화 시스템(n8n/MCP)이 호출할 **절차 기준**

❗ 본 문서는 “설명용”이 아니라  
❗ **“행동 기준(Operating Playbook)”**이다.

이 문서에 없는 행동은 **허용되지 않는다**.

---

## 1. 최상위 목표 (절대 기준)

> **장기 유지보수가 가능한 고품질 코드 생산**

다음 항목은 모두 부차 목표이다.

- 개발 속도
- 자동화 범위
- 비용 절감
- 편의성

의사결정 시 항상 **코드 품질이 우선**이다.

---

## 2. 기본 Agent Coding 파이프라인 (고정)

아래 파이프라인은 **모든 프로젝트의 기본 절차**이며  
GX10 도입 여부와 관계없이 **항상 유지**한다.



1️⃣ Claude Code

요구사항 분석

시스템/모듈 설계

파일 구조 정의

인터페이스 및 책임 명세

2️⃣ 로컬 LLM (DeepSeek / Qwen)

파일별 코드 구현

반복 수정

테스트 통과

3️⃣ Claude Code

전체 코드 리뷰

corner case 검토

구조적 리팩토링 제안

4️⃣ Warp

빌드

테스트

스크립트 실행


### 이 파이프라인의 목적
- 설계 사고는 고성능 모델
- 구현 반복은 로컬 엔진
- 통합 판단은 다시 고성능 모델
- 실행은 자동화

---

## 3. 개발 환경 분리 원칙

환경은 다음 3개로 **명확히 분리**한다.

| 환경 | 역할 |
|----|----|
| 개발자 PC | 설계 및 통제 |
| GX10 | 실행·검증 두뇌 |
| n8n / MCP | 무인 자동화 |

GX10은 다음을 수행하지 않는다.

- IDE 제공 ❌  
- 상시 대화 ❌  
- 수동 개발 ❌  

---

## 4. 개발자 PC의 책임 (항상 주체)

### 개발자 PC에서 반드시 수행해야 하는 작업

- 요구사항 해석
- 아키텍처 설계
- 파일 구조 정의
- 인터페이스 정의
- **Execution Plan 작성**

### Execution Plan 정의

Execution Plan은 다음을 반드시 포함한다.

- 디렉토리 구조
- 파일 목록
- 각 파일의 책임
- 구현 순서
- 테스트 기준

👉 GX10은 **Execution Plan 없이 작업하지 않는다**.

---

## 5. GX10의 역할 정의 (확장 두뇌)

GX10은 **개발자 PC의 대체물이 아니다**.  
다음 한계를 넘기 위해서만 사용한다.

- 코드베이스 대형화
- 자동화 환경에서의 대량 구현/수정
- 영상처리 성능 검증

---

## 6. GX10 Brain 구성 (확정)

GX10에는 두 개의 Brain만 존재한다.

| Brain | 역할 |
|----|----|
| Code Brain | Agent Coding 실행 엔진 |
| Vision Brain | 영상처리 성능 검증 엔진 |

### 실행 정책
- 단일 Brain만 실행 가능
- Code + Vision 동시 실행 금지

---

## 7. GX10 Code Brain의 책임 (핵심)

> **GX10 Code Brain은  
> Execution Plan을 입력받아  
> 코드 구현을 끝까지 책임지는 로컬 실행 엔진이다.**

### Code Brain이 수행해야 할 작업

- 디렉토리 생성
- 파일 생성 및 수정
- 다파일 동시 구현
- 테스트 실패 시 재수정
- 리팩토링
- 컨텍스트 유지

### Code Brain이 하지 않는 작업

- 요구사항 해석 ❌  
- 아키텍처 설계 ❌  
- 임의 판단 ❌  

---

## 8. GX10 Vision Brain의 책임

Vision Brain은 다음 기준으로만 판단한다.

- 성능 재현성
- 수치 안정성
- 파라미터 영향
- 하드웨어 효율

주요 작업:

- CUDA / TensorRT 실험
- latency / throughput 측정
- 성능 리포트 생성

---

## 9. GX10 Docker 기반 디렉토리 구조 (운영 기준)



/gx10/
├─ docker/
│ ├─ code-brain/
│ │ ├─ Dockerfile
│ │ ├─ models/
│ │ ├─ prompts/
│ │ ├─ execution/
│ │ └─ config.yaml
│ │
│ ├─ vision-brain/
│ │ ├─ Dockerfile
│ │ ├─ models/
│ │ ├─ cuda/
│ │ ├─ benchmarks/
│ │ └─ config.yaml
│
├─ runtime/
│ ├─ active_brain.json
│ ├─ locks/
│ └─ logs/
│
├─ api/
│ ├─ status_service.py
│ ├─ switch_brain.py
│ └─ execute_task.py
│
├─ automation/
│ ├─ n8n/
│ └─ mcp/
│
└─ system/
├─ monitoring/
├─ update/
└─ backup/


---

## 10. Brain 선택 및 전환 규칙

외부 환경은 다음 절차를 따른다.

1. 현재 Brain 상태 조회
2. 요청 작업과 Brain 적합성 검사
3. 불일치 시:
   - 경고
   - Brain 전환
   - 전환 완료 후 실행

Docker 컨테이너 stop/start 방식 사용.

---

## 11. End-to-End 표준 워크플로우

### 기본 개발



개발자 PC
→ Claude 설계
→ 로컬 LLM 구현
→ Warp 테스트


### 대규모 구현 / 수정



개발자 PC
→ Execution Plan 작성
→ GX10 Code Brain 실행
→ 결과 수신
→ Claude 리뷰


### 영상처리 검증



외부 PC / n8n
→ GX10 Vision Brain 실행
→ 성능 리포트 수신


---

## 12. GX10 리소스 사용 기준 (현실 수치)

### Code Brain
- RAM: 40~70GB
- VRAM: 24~48GB
- GPU: 중간
- CPU: 중간

### Vision Brain
- RAM: 60~100GB
- VRAM: 48GB 이상
- GPU: 최대

---

## 13. Idle Improvement (상시 모델 개선)

### 정의

> 외부 작업 지시가 없을 경우  
> GX10은 모델 성능 향상을 수행한다.

### Code Brain 개선
- 실행 결과
- 테스트 실패/성공
- Claude 리뷰
- 리팩토링 전/후 비교

→ LoRA / QLoRA 기반 업데이트

### Vision Brain 개선
- 성능 실험 재분석
- 파라미터-성능 관계 학습
- CUDA / TRT 최신 기법 리서치

---

## 14. 우선순위 규칙

1. 외부 작업 지시 최우선
2. Idle Improvement는 즉시 중단 가능
3. 작업 종료 후 결과는 학습 데이터로 저장

---

## 15. 변경 및 업데이트 정책

- Brain 단위 업데이트 가능
- 모델 교체 가능
- 롤백 가능
- 기본 파이프라인 변경 불가

---

## 16. 최종 정의

> **이 시스템은
> "AI를 많이 쓰는 구조"가 아니라
> "코드 품질을 지키기 위해 AI를 통제하는 구조"이다.**

---

## 📝 문서 정보

**작성자**:

- AI: Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)
- 환경: MoAI-ADK v11.0.0 (Claude Code + Korean Language Support)
- 작성일: 2026-02-01

**리뷰어**:

- drake

**수정자**:
- 수정일: 2026-02-01
- 수정 내용: 문서 형식 표준화 및 작성자 정보 보완 (omc-planner)

---

<!-- alfrad review:
  ✅ AI 모델 정보와 버전 상세 명시로 투명성 확보
  ✅ MoAI-ADK 환경 정보 기재로 재현 가능성 보장
  ✅ 작성일 일관성 유지
  ✅ 수정자 섹션 추가로 변경 내역 추적 개선
  💡 참고: 향후 버전 업데이트 시 AI 모델 ID 동기화 필요
-->

## 📜 수정 이력

| 일자 | 버전 | 설명 | 리뷰어 |
|------|------|------|--------|
| 2026-02-01 | 1.0 | 초기 개념 설계 및 계획서 작성 | drake |

---

## Appendix
