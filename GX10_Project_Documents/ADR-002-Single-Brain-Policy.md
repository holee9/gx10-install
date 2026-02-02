# ADR-002: 단일 Brain 실행 정책

**상태**: 승인됨 (Approved)
**작성일**: 2026-02-01
**결정자**: drake
**수정자**: omc-planner (2026-02-01 - 문서 분리 및 표준화)

---

## 결정 (Decision)

**Code Brain과 Vision Brain은 동시에 실행 불가**

---

## 이유 (Reasons)

### 메모리 제한 (128GB UMA)
- ASUS GX10: 128GB Unified Memory Architecture (UMA)
- Code Brain: 최대 80-100GB (대형 모델 32B+ 상주)
- Vision Brain: 최대 60-80GB (PyTorch, CUDA 오버헤드)
- 동시 실행 시 메모리 부족 위험 (합계 140-180GB 필요)

### GPU 리소스 경합 방지
- NVIDIA Grace Hopper Superchip
- 단일 Brain 실행 시 GPU 100% 활용 가능
- 동시 실행 시 리소스 경합으로 성능 저하

### 명확한 책임 분리
- Code Brain: IDE 통합, 코드 생성, 리팩토링
- Vision Brain: 이미지 처리, 시각적 분석, 실험 환경
- 동시 실행 필요성 없음 (사용 패턴이 명확히 분리됨)

---

## 대안 (Alternatives)

### 대안 1: 두 Brain 동시 실행
**장점**:
- 빠른 전환 없이 즉시 사용 가능

**단점**:
- 메모리 초과 위험 (128GB 한계)
- GPU 리소스 경합
- 전환 메커니즘이 필요 없으므로 불필요한 복잡성

**반영 사유**: 채택하지 않음 (하드웨어 제약)

### 대안 2: 동시 실행 + 리소스 제한
**장점**:
- 유연성

**단점**:
- 리소스 제어 복잡성
- 성능 예측 어려움
- 메모리 스와핑으로 성급 저하

**반영 사유**: 채택하지 않음 (복잡성 증가)

---

## 영향 (Consequences)

### 긍정적 영향
- 메모리 사용 예측 가능
- 안정적인 성능 보장
- 단순한 아키텍처
- 명확한 Brain 전환 정책

### 부정적 영향
- Brain 전환 시 지연 (~10-30초)
- 동시 작업 불가

### 완화 방안
- 빠른 전환 메커니즘 (`/gx10/api/switch-brain`)
- 상태 보존 (전환 전 작업 상태 저장)
- 자동 전환 (Execution Plan에 따라 자동)

---

## 구현 세부사항

### Brain 전환 절차

1. **상태 저장**: 현재 Brain 상태 `/gx10/runtime/state.json`에 저장
2. **현재 Brain 중지**: Code 또는 Vision Brain 종료
3. **메모리 해제**: GPU 메모리 완전 해제 확인
4. **대상 Brain 시작**: Code 또는 Vision Brain 시작
5. **상태 확인**: 헬스체크 API로 정상 작동 확인

### 전환 시간

| 작업 | 예상 시간 |
|------|-----------|
| 상태 저장 | 1-2초 |
| Brain 중지 | 3-5초 |
| 메모리 해제 | 2-3초 |
| Brain 시작 | 4-15초 |
| 상태 확인 | 1-2초 |
| **합계** | **11-27초** (평균 ~20초) |

---

## 참고 문서 (References)

- [GX10-03-Final-Implementation-Guide.md](../GX10-03-Final-Implementation-Guide.md) - Brain 전환 시스템
- [PRD.md](PRD.md) - 원본 ADR-002 섹션
- [SRS.md](SRS.md) - IR-3: Brain 제어 API 명세

---

## 검토 기록

| 일자 | 버전 | 검토자 | 변경 사항 |
|------|------|--------|-----------|
| 2026-02-01 | 1.0 | drake | 초기 승인 |
| 2026-02-01 | 1.1 | omc-planner | PRD.md에서 독립 문서로 분리, 전환 절차 구체화 |

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
- 수정 내용: PRD.md에서 ADR-002를 독립 문서로 분리 및 표준화 (omc-planner)
