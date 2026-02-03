# GX10 로컬 AI 개발 환경 구축 프로젝트

ASUS Ascent GX10을 활용한 로컬 AI 개발 환경 구축 가이드 모음입니다.

---

## 🔴 설치 진행 상황 (Live)

> **현재 브랜치**: `feature/gx10-setup-phase1`
> **마지막 업데이트**: 2026-02-03 10:30 KST

### 전체 진행률

```
[████████████░░░░░░░░] 55% - Phase 0 완료, 후속 조치 대기 중
```

### Phase 체크리스트

| Phase | 작업 | 상태 | 소요 시간 | 비고 |
|-------|------|------|---------|------|
| Phase 0 | sudo 사전 실행 | ✅ 완료 | 2분 | 패키지, SSH/UFW, 디렉토리, Docker, Ollama, systemd |
| Phase 0+ | 후속 조치 (수동) | ⏳ 대기 | - | Ollama 재시작, Docker 세션 반영 필요 |
| Phase 2 | AI 모델 다운로드 | ⬜ 미시작 | ~50분 예상 | qwen2.5-coder:32b + 7b |
| Phase 3 | Vision Brain Docker | ⬜ 미시작 | ~25분 예상 | Docker 빌드 + API |
| Phase 4 | 서비스/설정 | ⬜ 미시작 | ~10분 예상 | bashrc, WebUI, cron |
| Phase 5 | 최종 검증 | ⬜ 미시작 | ~10분 예상 | 전체 테스트 + Brain 전환 |

### 최근 작업 로그

| 일시 | 작업 | 결과 |
|------|------|------|
| 02-03 10:30 | main 커밋/푸시, `feature/gx10-setup-phase1` 브랜치 생성 | ✅ |
| 02-03 10:15 | `sudo ./00-sudo-prereqs.sh` 실행 (Phase 0) | ✅ 7개 섹션 모두 성공 |
| 02-03 10:13 | `00-sudo-prereqs.sh` 스크립트 생성 | ✅ sudo 작업 일괄 분리 |
| 02-03 09:50 | GX10 본체 사전 점검 (OS/GPU/메모리/디스크) | ✅ 기본 인프라 정상 |

### 발견된 이슈

| # | 이슈 | 상태 | 해결 방법 |
|---|------|------|---------|
| 1 | Ollama 서비스 미응답 | ⏳ 미해결 | `sudo systemctl restart ollama` 실행 필요 |
| 2 | Docker 소켓 권한 (현재 세션) | ⏳ 미해결 | `newgrp docker` 또는 Claude Code 재시작 |

### 다음 할 일

1. **수동 조치 2건 실행** (터미널에서):
   ```bash
   sudo systemctl restart ollama && ollama list
   newgrp docker && docker ps
   ```
2. AI 모델 다운로드 (Phase 2) - Claude Code 자동 진행
3. Vision Brain Docker 빌드 (Phase 3)
4. 서비스 설정 및 최종 검증 (Phase 4-5)

---

## 📋 문서 개요

이 프로젝트는 GX10 하드웨어(ARM 기반, 128GB Unified Memory, NVIDIA Blackwell GB10 GPU)에서 고품질 코드 생산을 위한 **Two Brain 아키텍처**를 구현하는 것을 목표로 합니다.

### 핵심 철학

> **"AI를 많이 쓰는 구조가 아니라, 코드 품질을 지키기 위해 AI를 통제하는 구조"**

- 장기 유지보수가 가능한 고품질 코드 생산이 최우선 목표
- 개발 속도, 자동화 범위, 비용 절감은 모두 부차 목표

## 📚 문서 구조

| 문서 | 버전 | 설명 | 상태 |
|------|------|------|------|
| [GX10-00-install-guide.md](GX10-00-install-guide.md) | 1.0 | DGX OS 기본 설치 가이드 | ✅ 완료 |
| [GX10-01-Setup-Plan.md](GX10-01-Setup-Plan.md) | 1.0 | 초기 개념 설계 및 계획서 | ✅ 완료 |
| [GX10-02-Setup-Supplement-v1.1.md](GX10-02-Setup-Supplement-v1.1.md) | 1.0 | v1.0 보완 지침서 | ✅ 완료 |
| [GX10-03-Final-Implementation-Guide.md](GX10-03-Final-Implementation-Guide.md) | 2.0 | **딥 리서치 기반 최종 구현 가이드** | ⭐ 추천 |
| [GX10-04-Build-Checklist.md](GX10-04-Build-Checklist.md) | 1.0 | 실제 구축 체크리스트 | ✅ 완료 |
| [GX10-05-Execution-Plan.md](GX10-05-Execution-Plan.md) | 0.1 | Execution Plan 템플릿 (초안) | ⚠️ 미완성 |
| [GX10-06-Comprehensive-Guide.md](GX10-06-Comprehensive-Guide.md) | 1.0 | 통합 가이드 및 실행 표준 | 🆕 신규 |

## 🎯 주요 문서 안내

### 1. 최종 구현 가이드 (GX10-03) - **시작하기**

가장 최신이며 완성도가 높은 문서입니다. 2025년 실측 벤치마크를 기반으로 작성되었습니다.

**주요 내용:**
- Part A: 운영 규칙 및 아키텍처 (Two Brain 구조)
- Part B: 기술 구현 가이드 (단계별 설정)
- Part C: 빠른 참조 (명령어, 서비스 URL)
- Part D: 개발자 PC 연동 (Aider, Continue.dev, OpenHands)
- Part E: 최종 아키텍처 다이어그램

**시작 순서:**
1. GX10-03의 "Phase 1: 초기 설정"부터 차례대로 실행
2. 각 Phase 완료 후 체크리스트(GX10-04)로 검증
3. 문제 발생 시 "문제 해결" 섹션 참조

### 2. 구축 체크리스트 (GX10-04)

실제 구축 시 각 단계를 체크하고 검증하기 위한 문서입니다.

**활용 방법:**
- 각 항목을 실행하며 ⬜ → ✅ 로 변경
- "검증" 섹션을 통해 올바른 구축 확인
- 최종 판정으로 구축 완료 여부 결정

### 3. Execution Plan 템플릿 (GX10-05)

**⚠️ 현재 미완성 상태입니다.**

GX10 Code Brain에 작업을 지시할 때 사용하는 표준 포맷입니다.

**보완 필요:**
- JSON Schema 정의 (GX10-02의 1-1 섹션 참조)
- YAML 예시 추가
- 버전 관리 규칙

## 🏗️ Two Brain 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                         GX10 System                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────┐      ┌─────────────────────┐          │
│  │    CODE BRAIN       │  OR  │   VISION BRAIN      │          │
│  │    (Native Mode)    │      │   (Docker Mode)     │          │
│  ├─────────────────────┤      ├─────────────────────┤          │
│  │ Ollama (systemd)    │      │ PyTorch Container   │          │
│  │ • Qwen2.5-Coder-32B │      │ • Qwen2.5-VL-72B    │          │
│  │ • DeepSeek-Coder    │      │ • YOLO/SAM2         │          │
│  │ • Qwen2.5-Coder-7B  │      │ • TensorRT          │          │
│  ├─────────────────────┤      ├─────────────────────┤          │
│  │ 메모리: 30-40GB     │      │ 메모리: 70-90GB     │          │
│  │ 토큰/초: 9-46       │      │ GPU: 최대 활용      │          │
│  └─────────────────────┘      └─────────────────────┘          │
│                                                                 │
│  ⚠️ 동시 실행 금지 - 단일 Brain만 활성화                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Code Brain (Native Mode)

**책임:** Execution Plan을 입력받아 코드 구현을 끝까지 책임지는 로컬 실행 엔진

**주요 작업:**
- 디렉토리 생성, 파일 생성 및 수정
- 다파일 동시 구현
- 테스트 실패 시 재수정
- 리팩토링, 컨텍스트 유지

**모델 구성:**
| 용도 | 모델 | 메모리 | 속도 |
|------|------|--------|------|
| 메인 코딩 | qwen2.5-coder:32b | ~20GB | ~9.5 tok/s |
| 빠른 응답 | qwen2.5-coder:7b | ~5GB | ~46 tok/s |
| 수학/논리 | deepseek-coder-v2:16b | ~10GB | ~18 tok/s |

### Vision Brain (Docker Mode)

**책임:** 성능 재현성, 수치 안정성, 파라미터 영향, 하드웨어 효율 기반 판단

**주요 작업:**
- CUDA / TensorRT 실험
- latency / throughput 측정
- 성능 리포트 생성

**모델 구성:**
| 용도 | 모델 | 메모리 |
|------|------|--------|
| Vision LLM | qwen2.5-vl:72b | ~45GB |
| Object Detection | YOLOv8x | ~100MB |
| Segmentation | SAM2-Large | ~2.5GB |

## 🔄 기본 파이프라인

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Agent Coding Pipeline                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐          │
│  │ 1️⃣ Claude    │───▶│ 2️⃣ GX10      │───▶│ 3️⃣ Claude    │          │
│  │    Code      │    │ Code Brain   │    │    Code      │          │
│  ├──────────────┤    ├──────────────┤    ├──────────────┤          │
│  │ • 요구사항    │    │ • 파일별 구현 │    │ • 전체 리뷰   │          │
│  │ • 설계       │    │ • 반복 수정   │    │ • corner case│          │
│  │ • 파일 구조   │    │ • 테스트 통과 │    │ • 리팩토링   │          │
│  │ • 인터페이스  │    │              │    │              │          │
│  └──────────────┘    └──────────────┘    └──────────────┘          │
│         │                   │                   │                  │
│         ▼                   ▼                   ▼                  │
│  ┌─────────────────────────────────────────────────────────┐       │
│  │                    4️⃣ Warp Terminal                     │       │
│  │         빌드 → 테스트 → 스크립트 실행 → Git 커밋          │       │
│  └─────────────────────────────────────────────────────────┘       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## 🚀 빠른 시작

### 1. 필수 조건

- GX10 하드웨어 (128GB RAM, NVIDIA Blackwell GB10)
- DGX OS 7.2.3 설치 완료 (Ubuntu 24.04 기반)
- 개발자 PC와 SSH 연결 가능

### 2. 2-Step 구축 (권장)

#### Step 1: sudo 사전 실행 (15-20분, 한 번만 sudo)

```bash
# 모든 sudo 필요 작업을 일괄 실행
cd ~/workspace/gx10-install/scripts/install
sudo ./00-sudo-prereqs.sh

# 재로그인 (docker 그룹 반영)
logout  # 후 다시 로그인
```

Phase 0이 수행하는 작업:
- 시스템 패키지 업데이트, SSH/방화벽 설정
- /gx10 디렉토리 생성 및 소유권 이전
- Docker 그룹 추가, Ollama 설치 및 서비스 설정

#### Step 2: 나머지 설치 (1시간 25분, sudo 불필요)

```bash
# AI 모델 다운로드 (~40분)
ollama pull qwen2.5-coder:32b
ollama pull qwen2.5-coder:7b

# Vision Brain Docker 빌드 (~20분)
cd ~/workspace/gx10-install/scripts/install
./06-vision-brain-build.sh

# Brain 전환 API + WebUI + 검증
./07-brain-switch-api.sh
./08-webui-install.sh
./10-final-validation.sh

# 테스트
ollama run qwen2.5-coder:32b "Hello, GX10!"
```

> Claude Code 등 자동화 도구 사용 시: Step 1만 터미널에서 실행하면 Step 2는 자동화 가능

#### Phase 3: Brain 전환 시스템 (Step 2에 포함)

```bash
# 상태 조회 스크립트 생성
cat > /gx10/api/status.sh << 'EOF'
#!/bin/bash
echo "=== GX10 Brain Status ==="
echo "📊 Memory:"
free -h | grep -E "Mem|Swap"
echo ""
echo "🎮 GPU:"
nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader
EOF
chmod +x /gx10/api/status.sh

# 실행
/gx10/api/status.sh
```

### 3. 개발자 PC 연동

```bash
# SSH 터널 생성
ssh -N -L 11434:localhost:11434 user@gx10-brain.local

# Aider 연결
export OLLAMA_API_BASE=http://localhost:11434
aider --model ollama_chat/qwen2.5-coder:32b
```

## 📖 상세 가이드

각 단계의 상세 내용은 다음 문서를 참조하세요:

1. **초기 설정**: [GX10-03-Final-Implementation-Guide.md](GX10-03-Final-Implementation-Guide.md) - Part B, Phase 1
2. **Code Brain**: [GX10-03-Final-Implementation-Guide.md](GX10-03-Final-Implementation-Guide.md) - Part B, Phase 2
3. **Vision Brain**: [GX10-03-Final-Implementation-Guide.md](GX10-03-Final-Implementation-Guide.md) - Part B, Phase 3
4. **Brain 전환**: [GX10-03-Final-Implementation-Guide.md](GX10-03-Final-Implementation-Guide.md) - Part B, Phase 4
5. **자동화**: [GX10-03-Final-Implementation-Guide.md](GX10-03-Final-Implementation-Guide.md) - Part B, Phase 5-7

## 🔧 문제 해결

### Ollama 연결 실패

```bash
sudo systemctl restart ollama
journalctl -u ollama -f
```

### 메모리 부족

```bash
# Buffer cache 정리
sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'

# 실행 중인 모델 확인
ollama ps
ollama stop <model-name>
```

### Brain 전환 실패

```bash
# 강제 정리
docker stop vision-brain 2>/dev/null
sudo systemctl stop ollama
sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'
sleep 10
/gx10/api/switch.sh code
```

## 📊 하드웨어 사양

| 항목 | 사양 |
|------|------|
| CPU | ARM v9.2-A (20-core: 10x Cortex-X925 + 10x Cortex-A725) |
| GPU | NVIDIA Blackwell GB10 (1 petaFLOP FP4 sparse) |
| 메모리 | 128GB LPDDR5x Unified Memory |
| 메모리 대역폭 | 273 GB/s (CPU+GPU 공유) |
| 스토리지 | 1TB NVMe SSD |
| 네트워크 | 10GbE + ConnectX-7 (200Gbps QSFP) |
| OS | DGX OS 7.2.3 (Ubuntu 24.04 LTS 기반) |

### UMA(Unified Memory Architecture) 특성

**⚠️ 중요: 이 사양은 일반 PC와 다르게 동작합니다.**

- CPU와 GPU가 동일한 메모리 풀을 공유
- PCIe 전송 병목 없음 (NVLink-C2C)
- Buffer Cache가 GPU 메모리를 점유할 수 있음
- 대역폭(273 GB/s)이 주요 병목

## 🔗 참조

### 벤치마크 출처

- [LMSYS Org](https://lmsys.org/blog/2025-10-13-nvidia-dgx-spark/) - SGLang 배치, DeepSeek-R1 83.5 tok/s
- [ProX PC](https://www.proxpc.com/blogs/nvidia-dgx-spark-gb10-performance-test-vs-5090-llm-image-and-video-generation) - Qwen2.5-72B: 4.6 tok/s
- [NVIDIA Blog](https://developer.nvidia.com/blog/how-nvidia-dgx-sparks-performance-enables-intensive-ai-tasks/) - Qwen3-235B 듀얼: 23,477 tok/s
- [Brandon RC](https://brandonrc.github.io/benchmark-spark/phase1/index.html) - Docker 20-30GB 오버헤드

### 라이선스

| 구성요소 | 라이선스 | 상업적 사용 |
|----------|----------|-------------|
| Qwen2.5-Coder | Apache 2.0 | ✅ |
| Qwen2.5-VL | Apache 2.0 | ✅ |
| DeepSeek-Coder-V2 | DeepSeek License | ✅ |
| Ollama | MIT | ✅ |
| n8n | Sustainable Use | ⚠️ 조건부 |

## 📝 문서 버전

- **최종 수정**: 2026-02-02
- **주요 변경사항**:
  - DGX OS 7.2.3 (Ubuntu 24.04 기반) 기반으로 정정
  - DGX OS 사전 설치된 컴포넌트 활용 가이드
  - Python 3.12 및 PEP 668 관련 내용 유지
  - DGX OS 특정 설정 추가

## 👥 기여

이 프로젝트는 실제 GX10 하드웨어를 활용한 로컬 AI 개발 환경 구축 경험을 문서화한 것입니다.

개선 제안이나 버그 리포트는 GitHub Issues를 통해 제출해 주세요.

---

## 📜 수정 이력

문서의 주요 수정 사항을 기록합니다.

| 일자 | 버전 | 설명 | 리뷰어 |
|------|------|------|--------|
| 2026-02-03 | 1.4 | 설치 진행 상황(Live) 섹션 추가, Phase 0 실행 결과 반영 | holee |
| 2026-02-03 | 1.3 | 빠른 시작을 2-Step(sudo/non-sudo) 플로우로 재구성 | holee |
| 2026-02-02 | 1.2 | DGX OS 기반으로 정정 (DGX OS는 Ubuntu 24.04 기반 NVIDIA 커스텀 OS) | drake |
| 2026-02-02 | 1.1 | Ubuntu 24.04 LTS 변경 사항 반영 | drake |
| 2026-02-01 | 1.0 | README 통합 작성, 작성자/리뷰어 정보 추가 | drake |

---

## 📝 문서 정보

**작성자**:

- AI: Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)
- 환경: MoAI-ADK v11.0.0 (Claude Code + Korean Language Support)
- 작성일: 2026-02-01

**리뷰어**:

- drake

**문서 버전**: 1.0

**최종 수정**: 2026-02-01

**주요 변경사항**:

- README 통합 작성
- 문서 간 중복 내용 정리
- 빠른 시작 가이드 추가
- 작성자 및 리뷰어 정보 추가

**프로젝트 상태**: 활성 개발 중
