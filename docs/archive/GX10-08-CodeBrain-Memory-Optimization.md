# Code Brain 메모리 최적화 제안서

## 문서 개요

본 문서는 GX10 Code Brain의 메모리 할당을 최적화하여 더 많은 모델과 더 큰 컨텍스트를 지원하는 방안을 제안합니다.

**작성일**: 2026-02-01
**버전**: 1.0
**상태**: 제안

---

## 문서 계층 구조

### 상위 문서
- [GX10_Project_Documents/PRS.md](GX10_Project_Documents/PRS.md) (DOC-PRS-001) - Product Requirements Specification
- [GX10_Project_Documents/SRS.md](GX10_Project_Documents/SRS.md) (DOC-SRS-001) - System Requirements Specification

### 동급 문서
없음 (기술 문서)

### 하위 문서
없음

### 관련 문서
- [GX10_Project_Documents/PRD.md](GX10_Project_Documents/PRD.md) (DOC-PRD-001) - Product Requirements Document
- [GX10-06-Comprehensive-Guide.md](GX10-06-Comprehensive-Guide.md) - 종합 가이드
- [GX10-07-Auto-Installation-Plan.md](GX10-07-Auto-Installation-Plan.md) - 자동 설치 계획

---

## 1. 현재 상황 분석

### 1.1 하드웨어 사양

```
CPU: ARM v9.2-A (20-core)
GPU: NVIDIA Blackwell GB10 (48GB VRAM, 최대 76GB with TensorRT)
Memory: 128GB LPDDR5x Unified Memory (UMA)
Bandwidth: 273 GB/s (CPU+GPU 공유)
```

### 1.2 현재 메모리 사용 현황

**Code Brain (Native 실행)**:
```
┌─ Ollama 서버: ~2GB
├─ 32B 모델 로드: ~20GB
├─ KV Cache (8K ctx): ~4GB
├─ 운영 오버헤드: ~4GB
└─ 총 사용: 30-40GB
└─ 여유: 88-98GB
```

**모델별 메모리 사용량**:
| 모델 | 크기 | 용도 |
|------|------|------|
| qwen2.5-coder:32b | ~20GB | 메인 코딩 |
| qwen2.5-coder:7b | ~5GB | 빠른 응답 |
| deepseek-coder-v2:16b | ~10GB | 수학/논리 |
| nomic-embed-text | ~275MB | 임베딩 |

### 1.3 제약 사항

**UMA 특성**:
- CPU와 GPU가 동일 메모리 풀 공유
- PCIe 전송 병목 없음 (NVLink-C2C)
- Buffer Cache가 GPU 메모리를 점유할 수 있음
- 대역폭(273 GB/s)이 주요 병목

**Docker 오버헤드** (Vision Brain):
- cgroups로 인한 20-30GB 오버헤드
- 대형 모델은 Native 실행이 1.6-2.7x 효율적

---

## 2. 문제 정의

### 2.1 현재 한계

**P1: 컨텍스트 윈통 부족**
- 현재 KV Cache: 8K 토큰 (~4GB)
- 대규모 프로젝트에서 컨텍스트 부족
- 파일 간 참조가 많을수 품질 저하

**P2: 다중 모델 동시 로드 불가**
- 현재: 단일 모델만 로드
- 7B + 32B 동시 로드 불가 (메모리 부족 우려)
- 작업 전환 시 모델 교체 필요

**P3: 향후 확장성 제한**
- 70B+ 모델 지원 불가
- 더 큰 배치 처리 불가
- Vision 작업과 병행 불가 (이미 제약됨)

---

## 3. 최적화 방안

### 3.1 Option A: 공격적 확장 (권장)

**목표**: 메모리 할당 30-40GB → 50-60GB

**구현 방안**:

```markdown
### Code Brain 메모리 재분배

1. 주 모델 (32B): 20GB → 24GB
   - KV Cache 확장: 8K → 16K 토큰 (~8GB)
   - 이유: 컨텍스트 2배 확장, 품질 유지

2. 서브 모델 (7B): 5GB → 상시 로드
   - 이유: 빠른 응답, 자동완성 작업

3. DeepSeek (16B): 10GB → 상시 로드
   - 이유: 수학/논리 강점, 코딩 보조

4. Ollama 오버헤드: 2GB → 4GB
   - 이유: 다중 모델 관리 오버헤드

총 사용: 24 + 5 + 10 + 4 = 43GB
여유: 85GB (안전 마진)
```

**장점**:
- ✅ 컨텍스트 2배 확장 (8K → 16K)
- ✅ 3개 모델 동시 로드 가능
- ✅ 작업 전환 없이 모델 선택 가능
- ✅ 여유 메모리 충분 (85GB)

**단점**:
- ⚠️ KV Cache 확장 시 초기 로딩 시간 증가
- ⚠️ 모델 교체 시 KV Cache 초기화 필요
- ⚠️ 더 많은 VRAM 사용 (43GB → 20GB GPU + 23GB 시스템)

---

### 3.2 Option B:保守的 확장 (안정성 중시)

**목표**: 메모리 할당 30-40GB → 40-45GB

**구현 방안**:

```markdown
### Code Brain 메모리 최적화 (保守的)

1. 주 모델 (32B): 20GB → 24GB
   - KV Cache: 8K → 12K 토큰 (~6GB)
   - 이유: 컨텍스트 1.5배 확장

2. 서브 모델 (7B): 5GB (on-demand)
   - 필요시에만 로드
   - 사용 후 언로드

3. Ollama 오버헤드: 2GB → 3GB

총 사용: 24 + 3 + 5(on-demand) = 32GB (기본)
최대 사용: 32 + 3 + 5 = 40GB (서브 모델 포함)
여유: 88GB (충분)
```

**장점**:
- ✅ 안정적 (여유 메모리 충분)
- ✅ 기존 구조 최소 변경
- ✅ KV Cache 초기화 시간 최소화

**단점**:
- ⚠️ 컨텍스트 확장 제한적 (1.5배)
- ⚠️ 서브 모델 on-demand 로딩 지연

---

### 3.3 Option C: 동적 할당 (Advanced)

**목표**: 작업 유형에 따라 동적으로 메모리 할당

**구현 방안**:

```markdown
### Code Brain 동적 메모리 관리

1. 작업 유형 감지
   - Small 프로젝트 (< 10파일): 7B 모델, 8K KV Cache
   - Medium 프로젝트 (10-50파일): 32B 모델, 16K KV Cache
   - Large 프로젝트 (> 50파일): 32B 모델, 32K KV Cache

2. KV Cache 동적 조정
   - 현재 파일 수 스캔
   - 평균 파일 크기 계산
   - 필요한 컨텍스트 크기 추정
   - KV Cache 자동 조정 (4K-32K)

3. 메모리 모니터링
   - 사용 가능 메모리 실시간 확인
   - OOM 방지를 위한 안전 마진 확보
   - 사용량이 80% 이상 시 경고
```

**장점**:
- ✅ 효율적 메모리 사용
- ✅ 모든 작업 유형 지원
- ✅ 리스크 완화

**단점**:
- ❌ 복잡한 구현
- ❌ OOM 위험 (동적 할당 실패 가능)
- ❌ 추가 개발 비용

---

## 4. 권장 방안: Option A (공격적 확장)

### 4.1 선택 이유

1. **GX10의 목적**: "장기 유지보수가 가능한 고품질 코드 생산"
   - 컨텍스트 부족은 코드 품질 저하의 주요 원인
   - 충분한 컨텍스트는 정확한 참조 구현에 필수

2. **하드웨어 여유**:
   - 128GB UMA 중 현재 30-40GB만 사용 (약 25-31%)
   - 여유 85GB는 활용되지 않음
   - Conservative Approach는 낭비

3. **확장 가능성**:
   - 50-60GB 사용해도 여유 68-78GB 보장
   - UMA 특성상 동적 할당이 가능함
   - 필요시 Vision Brain 중단으로 메모리 확보

### 4.2 상세 구현

#### 4.2.1 메모리 배포 계획

```
Total: 128GB Unified Memory

┌─ Code Brain (Native) ─────────────────────────────┐
│                                                        │
│  [GPU VRAM 영역: 최대 76GB]                       │
│  • qwen2.5-coder:32B: 24GB                          │
│  • KV Cache: 8GB (16K tokens)                         │
│  • DeepSeek-Coder: 16B: 10GB (상시 로드)             │
│  • Ollama 서버: 4GB                                  │
│  • 시스템 예약: 5GB                                   │
│  └─ 소계: 51GB                                        │
│                                                        │
└────────────────────────────────────────────────────────┘
└─ 여유: 77GB (안전 마진 포함) ────────────────────────────┘
```

#### 4.2.2 Ollama 설정

```bash
# /etc/systemd/system/ollama.service.d/override.conf

[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_MODELS=/gx10/brains/code/models"
Environment="OLLAMA_KEEP_ALIVE=24h"
Environment="OLLAMA_NUM_PARALLEL=2"
Environment="OLLAMA_MAX_LOADED_MODELS=3"
Environment="OLLAMA_KV_CACHE_SIZE=16106127360"  # 16GB
```

#### 4.2.3 다중 모델 관리 전략

**모델 전략**:

1. **메인 모델 (Primary)**: qwen2.5-coder:32b
   - 항상 로드됨
   - 일반적인 코딩 작업
   - KV Cache: 16K tokens

2. **빠른 응답 모델 (Fast)**: qwen2.5-coder:7b
   - 항상 로드됨
   - 자동완성, 간단 질문
   - KV Cache: 4K tokens (기본값)

3. **특화 모델 (Specialist)**: deepseek-coder-v2:16b
   - on-demand 로드 (필요시에만)
   - 수학/논리 중심 작업
   - 사용 후 언로드

4. **임베딩 모델 (Embedding)**: nomic-embed-text
   - on-demand 로드
   - 코드 검색, 유사도 계산

#### 4.2.4 컨텍스트 전략

**KV Cache 분배**:
```
16GB KV Cache = 16,384 MB
├─ 32B 모델 주 컨텍스트: 12GB (12K tokens × 4 bytes/token)
└─ 예약: 4GB
```

**컨텐스트 윈도**:
```
Small 프로젝트 (< 10파일):
  - 32B 모델 사용, 16K KV Cache
  - 전체 파일을 한 번에 처리 가능

Medium 프로젝트 (10-50파일):
  - 32B 모델 사용, 16K KV Cache
  - 파일별 처리 + 전체 리뷰

Large 프로젝트 (> 50파일):
  - 32B 모델 사용, 32K KV Cache (확장 가능)
  - 2-pass 접근 (분할 처리 후 통합)
```

---

## 5. Deep Research 기반 최적화

### 5.1 ARM UMA 최적화 연구 (2025)

**주요 연구**:
- [Enhancing LLM Inference Performance on ARM CPUs](https://ieeexplore.ieee.org/iel8/10410247/11095298/10994252.pdf) (IEEE, 2025)
  - 혼합 정박도 양자화 기법
  - 중요한 가중치 양자화, 기타 양자화
  - 메모리 사용량 감소와 처리량 향상

**시사점**:
- ARM 아키텍처에서 정밀도/성능 트레이드오프 분석
- UMA 환경에서의 메모리 관리 전략

### 5.2 CUDA Unified Memory 최적화

**주요 연구**:
- [Efficient Use of GPU Memory for Large-Scale Deep Learning](https://www.mdpi.com/2076-3417/11/21/10377) (MDPI, 2021)
  - CUDA Unified Memory 기반 최적화 기법
  - 데이터 타입별 다른 메모리 조언 (cudaMallocManaged, cudaMemPrefetchAsync)
  - 32회 인용, 실증된 기법

**시사점**:
- 대규모 딥러닝에서의 메모리 최적화
- Unified Memory 환경에서의 효율적 데이터 전략

### 5.3 HeteroLLM 아키텍처 (2025)

**주요 연구**:
- [HeteroLLM: Accelerating LLM Inference](https://arxiv.org/html/2501.14794v1) (arXiv, 2025)
  - 이종 프로세서(Latent, GPU, NPU) 통합
  - Unified Memory 활용
  - 동기화 전략

**시사점**:
- 여러 프로세서 협력 형태에서의 메모리 관리
- 작업 분산에 따른 메모리 할당

---

## 6. 구체적 구현 가이드

### 6.1 Ollama 설정 업데이트

```bash
# 1. Ollama 중지
sudo systemctl stop ollama

# 2. 환경 변수 설정
sudo tee /etc/systemd/system/ollama.service.d/override.conf << 'EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_MODELS=/gx10/brains/code/models"
Environment="OLLAMA_KEEP_ALIVE=24h"
Environment="OLLAMA_NUM_PARALLEL=2"
Environment="OLLAMA_MAX_LOADED_MODELS=3"
Environment="OLLAMA_KV_CACHE_SIZE=16106127360"
EOF

# 3. 서비스 재시작
sudo systemctl daemon-reload
sudo systemctl start ollama

# 4. 상태 확인
systemctl status ollama
curl http://localhost:11434/api/tags
```

### 6.2 다중 모델 로드 스크립트

```bash
#!/bin/bash
# /gx10/brains/code/load-models.sh

echo "=== Loading Code Brain Models ==="

# 1. 메인 모델 (32B)
echo "Loading primary model (32B)..."
ollama pull qwen2.5-coder:32b
ollama run qwen2.5-coder:32b "print('Ready')" &
sleep 5

# 2. 빠른 응답 모델 (7B)
echo "Loading fast model (7B)..."
ollama pull qwen2.5-coder:7b
ollama run qwen2.5-coder:7b "print('Ready')" &
sleep 5

# 3. 특화 모델 (16B)
echo "Loading specialist model (16B)..."
ollama pull deepseek-coder-v2:16b
ollama run deepseek-coder-v2:16b "print('Ready')" &

echo "=== All models loaded ==="
echo ""
echo "Memory usage:"
nvidia-smi
```

### 6.3 컨텍스트 최적화

**프로젝트별 컨텍스트 설정**:

```yaml
# Small Project (<10 files, <5000 lines)
execution_plan:
  models:
    primary: qwen2.5-coder:32b
    kv_cache: 16384  # 16K tokens

# Medium Project (10-50 files, 5000-50000 lines)
execution_plan:
  models:
    primary: qwen2.5-coder:32b
    kv_cache: 32768  # 32K tokens (확장)

# Large Project (>50 files, >50000 lines)
execution_plan:
  models:
    primary: qwen2.5-coder:32b
    kv_cache: 65536  # 64K tokens (더 확장)
  strategy: two_pass  # 2-pass 접근
```

### 6.4 메모리 모니터링

```bash
# /gx10/system/monitoring/memory-health.sh

#!/bin/bash

# GPU 메모리 확인
GPU_MEM=$(nvidia-smi --query-gpu=memory.used --format=gb,noheader,nounits | head -1)
echo "GPU Memory Used: ${GPU_MEM}GB / 76GB"

# KV Cache 사용량 확인
OLLAMA_MEM=$(ps aux | grep '[o]llama' | awk '{sum $6}')
echo "Ollama Memory: ${OLLAMA_MEM}KB"

# 시스템 메모리 확인
SYS_MEM=$(free -g | awk '/Mem:/ {print $3}')
echo "System Memory Used: ${SYS_MEM}GB / 128GB"

# 경고 로직
if [ $GPU_MEM -gt 60 ]; then
  echo "⚠️  GPU Memory high! Consider unloading unused models."
elif [ $GPU_MEM -gt 70 ]; then
  echo "❌ GPU Memory critical! Unload models immediately."
fi
```

---

## 7. 성능 비교

### 7.1 시나리오별 성능

| 시나리오 | 컨텍스트 | 메모리 사용 | 장점 | 단점 |
|---------|----------|------------|------|------|
| **Small Project** | 8K | 32GB | 빠른 처리 | 오버헤드 |
| **Medium Project** | 16K | 43GB | 최적 균형 | VRAM 66% 사용 |
| **Large Project** | 32K | 59GB | 큰 프로젝트 지원 | VRAM 77% 사용 |
| **Multi-model** | - | 43GB | 작업 전환 없이 | 전환 필요 없음 |

### 7.2 예상 성능 향상

**Before (현재)**:
- 32B 모델, 8K KV Cache
- Medium 프로젝트: 파일 10개당 2회 전체 리뷰 필요
- 컨텍스트 부족으로 참조 오류

**After (최적화)**:
- 32B 모델, 16K KV Cache
- Medium 프로젝트: 파일 20개까지 1회 전체 리뷰 가능
- 컨텍스트 충분으로 참조 정확도 향상

---

## 8. 위험도 평가

### 8.1 기술 위험

| 위험 | 확률 | 영향 | 완화 전략 |
|------|--------|------|----------|
| KV Cache 확장 시 OOM | 중 | 높 | 여유 메모리 충분 (77GB) |
| 모델 호환성 문제 | 낮 | 중간 | Ollama 자체 호환 지원 |
| UMA 병목 발생 | 낮 | 중간 | 안전 마진 보유 |

### 8.2 운영 위험

| 위험 | 확률 | 영향 | 완화 전략 |
|------|--------|------|----------|
| 전력 소모 증가 | 중 | 낮 | GPU 활용도 증가로 정당 |
| 장애 발생 시 복구 | 낮 | 중간 | 이전 상태로 복구 스크립트 |
| 사용자 학습 곡선 | 중 | 낮 | 상세 문서 및 가이드 제공 |

---

## 9. 롤백 계획

### 9.1 단계별 롤백

**Phase 1 (1주)**:
- Ollama 설정 업데이트
- 7B, 32B, 16B 모델 로드
- KV Cache 16K로 설정
- 테스트 실행

**Phase 2 (2주)**:
- 다양한 프로젝트 유형 테스트
- 성능 벤치마크
- 메모리 사용량 모니터링
- 문제 발생 시 조정

**Phase 3 (1주)**:
- 최종 설정 확정
- 문서화 완료
- 사용자 가이드 작성

### 9.2 롤백 기준

**성공 기준**:
- 32B 모델 + 16K KV Cache 정상 작동
- 3개 모델 동시 로드 성공
- Medium 프로젝트(20-30파일) 1회 전체 리뷰
- GPU 메모리 사용률: 60-70% (안정)

**싌� 시 조치**:
- Option B (保守的)로 롤백
- KV Cache 줄이기
- 일부 모델 언로드

---

## 10. 결론

### 10.1 추천 방안

**Option A (공격적 확장)**를 권장합니다:

**이유**:
1. **목적 부합**: 고품질 코드 생산을 위해 충분한 컨텍스트 필수
2. **안전성**: 77GB 여유 메모리로 충분한 안전 마진
3. **확장성**: 향후 70B+ 모델 지원 가능
4. **효율성**: 낭비 자원 없음

### 10.2 기대 효과

**개선 전 (현재)**:
- 컨텍스트: 8K tokens
- 메모리 사용: 30-40GB
- 효율: 25% (32GB/128GB)

**개선 후 (Option A)**:
- 컨텍스트: 16K tokens (2배)
- 메모리 사용: 51GB
- 효율: 40% (51GB/128GB)
- 다중 모델 동시 로드
- 작업 전환 없음

---

## 11. TBD (미정 사항)

다음 사항은 추가 검증이 필요합니다:

1. **정량적 성능 벤치마크**
   - 16K vs 8K KV Cache 실제 성능 차이
   - 다중 모델 동시 로드 시 처리량 영향
   - 우선순위: P1

2. **OOM 방지 메커니즘**
   - 메모리 사용량 80% 도달 시 자동 언로드
   -Critical 서비스 우선순위 정의
   - 우선순위: P1

3. **자동 컨텍스트 조정**
   - 프로젝트 크기 자동 감지
   - 동적 KV Cache 크기 조정
   - 우선순위: P2 (선택사항)

---

## 📝 문서 정보

**작성자**:
- AI: Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)
- 환경: MoAI-ADK v11.0.0 (Claude Code + Korean Language Support)
- 작성일: 2026-02-01

**리뷰어**:
- drake

---

## 📜 수정 이력

| 일자 | 버전 | 설명 | 리뷰어 |
|------|------|------|--------|
| 2026-02-01 | 1.0 | Code Brain 메모리 최적화 제안서 작성 | drake |

---

## 🔗 참고 문서

- [GX10-03-Final-Implementation-Guide.md](GX10-03-Final-Implementation-Guide.md) - UMA 특성 및 벤치마크
- [GX10-06-Comprehensive-Guide.md](GX10-06-Comprehensive-Guide.md) - Execution Plan 스키마
- [Enhancing LLM Inference on ARM CPUs](https://ieeexplore.ieee.org/iel8/10410247/11095298/10994252.pdf) - ARM 최적화 연구
- [Efficient Use of GPU Memory](https://www.mdpi.com/2076-3417/11/21/10377) - CUDA 메모리 최적화

---

## Appendix: Deep Search Sources

1. [Enhancing LLM Inference Performance on ARM CPUs](https://ieeexplore.ieee.org/iel8/10410247/11095298/10994252.pdf) - IEEE 2025
2. [HeteroLLM: Accelerating LLM Inference](https://arxiv.org/html/2501.14794v1) - arXiv 2025
3. [CUDA Unified Memory Programming Guide](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/unified-memory.html) - NVIDIA 공식 문서
4. [Efficient Use of GPU Memory](https://www.mdpi.com/2076-3417/11/21/10377) - MDPI 2021
