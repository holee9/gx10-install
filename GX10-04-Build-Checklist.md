
# 🧩 GX10 실제 구축 체크리스트
## (Agent Coding + Brain 시스템)

본 체크리스트는  
`GX10-Setup-Plan.md`를 기준으로 **실제 구축을 순서대로 실행·검증**하기 위한 문서이다.


각 항목은 다음 상태 중 하나로 관리한다.

- ⬜ 미실행
- 🔄 진행 중
- ✅ 완료
- ⚠️ 보류 / 재검토

## 1. 사전 조건 확인


⬜ GX10 하드웨어 준비 완료  
⬜ RAM 128GB / SSD 1TB 인식 확인  
⬜ GPU 정상 인식 (`nvidia-smi`)  
⬜ 인터넷 연결 확인  
⬜ 외부 개발자 PC 접근 가능  


---

## 2. 기본 시스템 구성


⬜ OS 설치 (Ubuntu LTS 권장)  
⬜ NVIDIA Driver 설치  
⬜ CUDA Toolkit 설치  
⬜ Docker 설치  
⬜ Docker GPU runtime 설정  



검증:

- ⬜ Docker에서 GPU 접근 가능


---

## 3. 디렉토리 구조 생성


⬜ `/gx10/brains/code` (Native 실행)
⬜ `/gx10/brains/vision` (Docker 실행)
⬜ `/gx10/runtime`
⬜ `/gx10/api`
⬜ `/gx10/automation`
⬜ `/gx10/system`

**참고**: ADR-001에 따라 Code Brain은 Native 실행, Vision Brain은 Docker 실행 (2026-02-01 표준화)



검증:

- ⬜ 구조가 계획서와 일치


---

## 4. Code Brain 구축


⬜ Code Brain Dockerfile 작성  
⬜ 로컬 LLM 모델 배치  
⬜ Prompt / Rule 세트 구성  
⬜ Execution Plan 입력 인터페이스 구현  
⬜ 테스트 실행 루프 구현  



검증:

- ⬜ Execution Plan 없이 실행 불가
- ⬜ 다파일 구현 가능
- ⬜ 테스트 실패 시 재시도 동작


---

## 5. Vision Brain 구축


⬜ Vision Brain Dockerfile 작성  
⬜ CUDA / TensorRT 환경 구성  
⬜ 벤치마크 스크립트 구성  
⬜ 성능 리포트 출력 포맷 정의  



검증:

- ⬜ latency / throughput 측정 가능
- ⬜ 파라미터 변경 실험 가능


---

## 6. Brain 전환 제어 구현


⬜ active_brain.json 생성  
⬜ Brain 상태 조회 API 구현  
⬜ Brain 전환 API 구현  
⬜ 동시 실행 방지 lock 적용  



검증:

- ⬜ Code ↔ Vision 전환 정상
- ⬜ 동시 실행 불가 확인


---

## 7. 외부 제어 연동


⬜ 개발자 PC에서 Brain 상태 조회  
⬜ 개발자 PC에서 Brain 전환  
⬜ n8n / MCP에서 Brain 호출  



검증:

- ⬜ GX10 무인 상태에서도 제어 가능


---

## 8. Idle Improvement 설정


⬜ Idle 상태 감지 조건 정의  
⬜ Code Brain 개선 루프 연결  
⬜ Vision Brain 개선 루프 연결  
⬜ 외부 작업 발생 시 즉시 중단 확인  



검증:

- ⬜ 작업 우선순위 정상
- ⬜ 자동 학습 로그 생성


---

## 9. 안정성 및 롤백


⬜ Brain 이미지 버전 관리  
⬜ 이전 버전 롤백 가능 확인  
⬜ 로그 보존 정책 적용  


---

## 10. 최종 검증


⬜ 계획서(GX10-Setup-Plan.md)와 불일치 항목 없음  
⬜ 사람이 수동 개입하지 않아도 동작  
⬜ Agent Coding 품질 저하 없음  


---

## 최종 판정


- ⬜ 구축 완료
- ⬜ 부분 완료 (사유 기록)

---

## 📜 수정 이력

| 일자 | 버전 | 설명 | 리뷰어 |
|------|------|------|--------|
| 2026-02-01 | 1.0 | 실제 구축 체크리스트 작성 | drake |

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

<!-- alfrad review:
  ✅ 작성자 정보 표준화로 문서 일관성 확보
  ✅ 체크리스트 문서 특성 고려하여 작성자 정보 적절히 기재
  ✅ 수정자 섹션 추가로 변경 내역 추적 가능
  💡 제안: 체크리스트 항목별 검토자(Retriever) 정보 추가 권장
-->

