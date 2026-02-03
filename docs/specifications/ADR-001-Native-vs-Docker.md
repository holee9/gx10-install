# ADR-001: Native vs Docker 실행

**상태**: 승인됨 (Approved)
**작성일**: 2026-02-01
**결정자**: drake
**수정자**: omc-planner (2026-02-01 - 문서 분리 및 표준화)

---

## 결정 (Decision)

**Code Brain은 Native 실행, Vision Brain은 Docker 실행**

---

## 이유 (Reasons)

### Code Brain: Native 실행
- 빠른 전환 속도
- 낮은 오버헤드 (Docker cgroups가 20-30GB 추가 메모리 소비)
- GPU 직접 접근 필요 (대형 모델 >10B에서 1.6-2.7x 효율적)
- UMA 아키텍처에서의 메모리 최적화

### Vision Brain: Docker 실행
- 복잡한 의존성 관리 (PyTorch, CUDA, torchvision)
- 재현성 보장 (컨테이너 이미지로 환경 고정)
- 실험 환경 독립성
- 롤백 및 버전 관리 용이

---

## 대안 (Alternatives)

### 대안 1: 모두 Docker 실행
**장점**:
- 환경 일관성
- 배포 용이

**단점**:
- 오버헤드 큼 (Docker cgroups 20-30GB)
- 전환 속도 느림
- 대형 모델에서 성능 저하

**반영 사유**: 채택하지 않음 (메모리 효율 저하)

### 대안 2: 모두 Native 실행
**장점**:
- 최대 성능
- 오버헤드 없음

**단점**:
- 의존성 충돌 위험
- 환경 재현 어려움
- Vision Brain 실험 환경 격리 불가

**반영 사유**: 채택하지 않음 (의존성 관리 문제)

---

## 영향 (Consequences)

### 긍정적 영향
- 메모리 사용 최적화 (Native Code Brain)
- 환경 격리 보장 (Docker Vision Brain)
- GPU 리소스 효율적 활용
- 빠른 Brain 전환

### 부정적 영향
- 두 가지 실행 모드 관리 복잡성
- 통합 테스트 어려움

### 완화 방안
- 표준화된 디렉토리 구조: `/gx10/brains/code/` (Native), `/gx10/brains/vision/` (Docker)
- 통합 상태 관리: `/gx10/runtime/state.json`
- 명확한 실행 가이드: GX10-03-Final-Implementation-Guide.md

---

## 참고 문서 (References)

- [GX10-03-Final-Implementation-Guide.md](../GX10-03-Final-Implementation-Guide.md) - 섹션 5.3 "왜 Code Brain은 Native, Vision Brain은 Docker인가?"
- [GX10-09-Two-Brain-Optimization.md](../GX10-09-Two-Brain-Optimization.md) - 메모리 제약 분석
- [PRD.md](PRD.md) - 원본 ADR-001 섹션

---

## 검토 기록

| 일자 | 버전 | 검토자 | 변경 사항 |
|------|------|--------|-----------|
| 2026-02-01 | 1.0 | drake | 초기 승인 |
| 2026-02-01 | 1.1 | omc-planner | PRD.md에서 독립 문서로 분리, 세부 내용 보강 |

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
- 수정 내용: PRD.md에서 ADR-001을 독립 문서로 분리 및 표준화 (omc-planner)
