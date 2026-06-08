
# GX10 로컬 AI 개발 환경 구축 가이드

## Revision History
| Date | Version | Description |
|------|---------|-------------|
| 2026-02-01 | v1.0 | 초안 작성 |
| 2026-02-01 | v2.0 | 딥 리서치 기반 전면 재구성 |

---

## Part A: 운영 규칙 및 아키텍처

## 0. 문서 성격 및 사용 규칙

본 문서는 다음 용도로 사용한다.

- 사람 개발자가 따라야 할 **개발·운영 지침**
- AI Agent가 따라야 할 **행동 규칙**
- 자동화 시스템(n8n/MCP)이 호출할 **절차 기준**

❗ 본 문서는 "설명용"이 아니라 **"행동 기준(Operating Playbook)"**이다.
❗ 이 문서에 없는 행동은 **허용되지 않는다**.

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

## 2. 하드웨어 사양 및 성능 특성

### 2.1 ASUS Ascent GX10 확정 사양

| 항목 | 사양 |
|------|------|
| CPU | ARM v9.2-A (20-core: 10x Cortex-X925 @ 3.9GHz + 10x Cortex-A725 @ 2.8GHz) |
| GPU | NVIDIA Blackwell GB10 (1 petaFLOP FP4 sparse) |
| 메모리 | 128GB LPDDR5x Unified Memory (실측 가용: 119 GiB) |
| 메모리 대역폭 | 273 GB/s (CPU+GPU 공유) |
| 스토리지 | 1TB NVMe SSD (실측 가용: ~983 GB) |
| 네트워크 | 10GbE + ConnectX-7 (200Gbps QSFP) |
| OS | DGX OS 7.2.3 (Ubuntu 24.04.4 LTS) |
| 커널 | 6.17.0-1018-nvidia |
| GPU 드라이버 | NVIDIA 580.159.03 |
| CUDA | 13.0 |
| Ollama | v0.30.6 |

### 2.2 UMA(Unified Memory Architecture) 특성

**⚠️ 중요: 이 사양은 일반 PC와 다르게 동작한다.**

```
┌─────────────────────────────────────────────────────────────┐
│                    128GB Unified Memory Pool                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  CPU 영역  │  공유 영역  │  GPU 영역  │  Buffer Cache  │   │
│  │  (동적)    │   (동적)    │   (동적)   │    (동적)      │   │
│  └─────────────────────────────────────────────────────┘   │
│                    273 GB/s 대역폭 공유                      │
└─────────────────────────────────────────────────────────────┘
```

**핵심 특성:**
- CPU와 GPU가 동일한 메모리 풀을 공유
- PCIe 전송 병목 없음 (NVLink-C2C)
- Buffer Cache가 GPU 메모리를 점유할 수 있음
- 대역폭(273 GB/s)이 주요 병목 → 대형 모델의 TTFT가 김

### 2.3 실측 벤치마크 (2026-06-08 기준)

| 모델 | 토큰/초 | 메모리 사용량 | 컨텍스트 | 비고 |
|------|---------|--------------|---------|------|
| `gpt-oss:120b` (MoE, MXFP4) | **38.5** | ~76 GiB | 131K | ✅ **현재 단일 운영 모델** |
| `qwen3-embedding:latest` (Q4_K_M) | — | ~5 GiB | — | 임베딩 전용 (4096차원) |

**참고 — 이전 Dense 모델 실측 (2026-06 조사):**
| 모델 | 토큰/초 | 비고 |
|------|---------|------|
| Dense 70B Q4_K_M | 2.7 | ❌ 대화 불가 |
| Dense 32B Q4_K_M | ~9.5 | ⚠️ 느림 |
| Dense 27B Q4_K_M | ~12 | ⚠️ 가능하나 느림 |
| MoE 122B/10B (Qwen3.5) | 28–51 | ✅ 실용적 |

**핵심 원칙 (GB10 하드웨어):**
- 메모리 병목 = 273 GB/s 대역폭 → Dense 대형 모델은 구조적 불리
- MoE 아키텍처만이 active param 수를 줄여 속도 이점 확보
- gpt-oss:120b: 116.8B 파라미터 중 추론 시 ~5B만 활성 → 38.5 tok/s 달성

---

## 3. 기본 Agent Coding 파이프라인 (고정)

아래 파이프라인은 **모든 프로젝트의 기본 절차**이며 GX10 도입 여부와 관계없이 **항상 유지**한다.

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

### 파이프라인 목적
- 설계 사고는 **고성능 모델** (Claude)
- 구현 반복은 **로컬 엔진** (GX10)
- 통합 판단은 다시 **고성능 모델** (Claude)
- 실행은 **자동화** (Warp)

---

## 4. 개발 환경 분리 원칙

환경은 다음 3개로 **명확히 분리**한다.

| 환경 | 역할 | 상세 |
|------|------|------|
| 개발자 PC | 설계 및 통제 | IDE, Claude Code, Git 관리 |
| GX10 | 실행·검증 두뇌 | LLM 추론, 테스트 실행, 성능 검증 |
| n8n / MCP | 무인 자동화 | 워크플로우 트리거, 알림, 스케줄링 |

### GX10이 하지 않는 작업

- IDE 제공 ❌
- 상시 대화 ❌
- 수동 개발 ❌
- 요구사항 해석 ❌
- 아키텍처 설계 ❌

---

## 5. GX10 Brain 구성

### 5.1 현재 운영 아키텍처 (2026-06-08)

```
┌─────────────────────────────────────────────────────────────────┐
│                         GX10 System                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────┐                  │
│  │           CODE BRAIN (현재 운영)           │                  │
│  │           (Native Mode, systemd)          │                  │
│  ├──────────────────────────────────────────┤                  │
│  │ Ollama v0.30.6 (systemd)                 │                  │
│  │ • gpt-oss:120b (116.8B MoE, MXFP4)      │                  │
│  │   → 코딩·서치·RAG 범용 추론 38.5 tok/s   │                  │
│  │ • qwen3-embedding:latest (7.6B Q4_K_M)   │                  │
│  │   → RAG 임베딩 4096차원                   │                  │
│  ├──────────────────────────────────────────┤                  │
│  │ 메모리: ~81 GiB / 119 GiB               │                  │
│  │ 컨텍스트: gpt-oss 131K, embedding 4096   │                  │
│  └──────────────────────────────────────────┘                  │
│                                                                 │
│  [Vision Brain - 미배포, 향후 검토 예정]                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 실행 정책

**아키텍처 결정 참조**: [ADR-002: 단일 Brain 실행 정책](GX10_Project_Documents/ADR-002-Single-Brain-Policy.md)

1. **단일 엔드포인트 원칙**: 모든 추론 요청은 `gpt-oss:120b` 하나로 처리
2. **클라이언트 모델 선택 불필요**: 호출 시스템에서 모델 구분 없이 사용
3. **Vision Brain**: 현재 미배포, 비전 입력 필요 시 추후 검토

### 5.3 왜 Code Brain은 Native 실행인가?

**아키텍처 결정 참조**: [ADR-001: Native vs Docker 실행](GX10_Project_Documents/ADR-001-Native-vs-Docker.md)

**리서치 결과:**
- UMA 아키텍처에서 Docker cgroups가 **20-30GB 메모리 오버헤드** 발생
- 대형 모델(>10B)은 **native 실행이 1.6-2.7x 효율적**
- gpt-oss:120b (~76 GiB)는 native 실행 필수 (Docker 오버헤드 시 메모리 초과)
- Ollama v0.30.6: cuda_v13 라이브러리로 SM 12.1 (GB10) 완전 지원

---

## 6. Code Brain 상세

### 6.1 책임 정의

> **Code Brain은 Execution Plan을 입력받아 코드 구현을 끝까지 책임지는 로컬 실행 엔진이다.**

### 6.2 Code Brain이 수행하는 작업

- 디렉토리 생성
- 파일 생성 및 수정
- 다파일 동시 구현
- 테스트 실패 시 재수정
- 리팩토링
- 컨텍스트 유지 (128K 토큰)

### 6.3 Code Brain이 하지 않는 작업

- 요구사항 해석 ❌
- 아키텍처 설계 ❌
- 임의 판단 ❌

### 6.4 모델 구성

| 용도 | 모델 | 크기 (디스크) | 메모리 | 토큰/초 |
|------|------|-------------|--------|---------|
| **범용 추론 (코딩·서치·RAG)** | `gpt-oss:120b` | 65 GB | ~76 GiB | **38.5** |
| **텍스트 임베딩** | `qwen3-embedding:latest` | 4.7 GB | ~5 GiB | — |

> **단일 엔드포인트 원칙**: 모든 추론 요청은 `gpt-oss:120b` 하나로 처리.
> - 116.8B MoE (MXFP4), 컨텍스트 131K, SWE-bench 72.3%, GPQA 82.9%
> - Tool Calling ✅ (web_search 함수 호출 확인)
> - 한국어 포함 다국어 코드 생성 ✅

### 6.5 리소스 사용량

```
Code Brain 실행 시 (2026-06-08 실측):
├─ Ollama 서버: ~2 GiB
├─ gpt-oss:120b 로드: ~76 GiB
├─ qwen3-embedding 로드: ~5 GiB
├─ KV Cache (131K ctx): 포함
└─ 총 실측: ~81 GiB / 119 GiB 가용

남은 메모리: ~38 GiB (OS/KV cache 여유)
```

---

## 7. Vision Brain 상세

### 7.1 책임 정의

Vision Brain은 다음 기준으로만 판단한다.

- 성능 재현성
- 수치 안정성
- 파라미터 영향
- 하드웨어 효율

### 7.2 주요 작업

- CUDA / TensorRT 실험
- latency / throughput 측정
- 성능 리포트 생성
- 모델 비교 검증

### 7.3 모델 구성

| 용도 | 모델 | 크기 | 비고 |
|------|------|------|------|
| Vision LLM | qwen2.5-vl:72b | ~45GB | 고품질 분석 |
| Vision LLM (빠름) | qwen2.5-vl:7b | ~5GB | 빠른 확인 |
| Object Detection | YOLOv8x | ~100MB | Ultralytics |
| Segmentation | SAM2-Large | ~2.5GB | Meta |
| Depth | Depth-Anything-V2 | ~1GB | HuggingFace |

### 7.4 리소스 사용량

```
Vision Brain 실행 시:
├─ Docker 오버헤드: ~10GB
├─ PyTorch + CUDA: ~5GB
├─ 72B Vision 모델: ~45GB
├─ 추가 모델들: ~10GB
├─ 데이터/버퍼: ~10GB
└─ 총 예상: 70-90GB

남은 메모리: 38-58GB
```

---

## 8. Execution Plan 규격

### 8.1 정의

> GX10은 **Execution Plan 없이 작업하지 않는다**.

### 8.2 필수 포함 항목

```yaml
# Execution Plan 예시
plan:
  name: "feature-user-auth"
  version: "1.0"
  
structure:
  directories:
    - src/auth/
    - src/auth/handlers/
    - tests/auth/
    
  files:
    - path: src/auth/service.py
      responsibility: "인증 비즈니스 로직"
      dependencies: [src/auth/repository.py]
      
    - path: src/auth/handlers/login.py
      responsibility: "로그인 핸들러"
      dependencies: [src/auth/service.py]
      
    - path: tests/auth/test_service.py
      responsibility: "서비스 유닛 테스트"
      test_framework: pytest
      
sequence:
  1: src/auth/repository.py
  2: src/auth/service.py
  3: src/auth/handlers/login.py
  4: tests/auth/test_service.py
  
test_criteria:
  - "pytest tests/auth/ 통과"
  - "coverage >= 80%"
  
constraints:
  - "기존 API 인터페이스 유지"
  - "Python 3.11+ 호환"
```

---

## 9. Brain 전환 절차

### 9.1 전환 흐름

```
┌─────────────────────────────────────────────────────────────┐
│                    Brain Switch Procedure                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 현재 Brain 상태 조회                                     │
│     └─▶ GET /api/status                                     │
│                                                             │
│  2. 요청 작업과 Brain 적합성 검사                            │
│     └─▶ code 작업 → Code Brain 필요                         │
│     └─▶ vision 작업 → Vision Brain 필요                     │
│                                                             │
│  3. 불일치 시:                                               │
│     ├─▶ 경고 로그 기록                                      │
│     ├─▶ 현재 Brain 정지                                     │
│     ├─▶ ⚠️ Buffer Cache 플러시 (필수!)                       │
│     ├─▶ 목표 Brain 시작                                     │
│     └─▶ 헬스체크 통과 후 실행                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 9.2 Buffer Cache 플러시 (필수)

```bash
# Brain 전환 전 반드시 실행
sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'
sleep 5  # 안정화 대기
```

**⚠️ 이 단계를 건너뛰면 새 Brain이 메모리 부족으로 실패할 수 있음**

---

## 10. 워크플로우

### 10.1 기본 개발

```
개발자 PC
  └─▶ Claude Code (설계)
      └─▶ PC 로컬 LLM 또는 GX10
          └─▶ Warp (테스트)
              └─▶ Git 커밋
```

### 10.2 대규모 구현/수정

```
개발자 PC
  └─▶ Execution Plan 작성
      └─▶ GX10 Code Brain 호출
          └─▶ 구현 결과 수신
              └─▶ Claude Code 리뷰
                  └─▶ Git 커밋
```

### 10.3 영상처리 검증

```
개발자 PC / n8n 트리거
  └─▶ Brain 전환 (Vision)
      └─▶ Vision Brain 실행
          └─▶ 성능 리포트 생성
              └─▶ 결과 알림
```

---

## 11. 우선순위 및 정책

### 11.1 우선순위 규칙

1. 외부 작업 지시 **최우선**
2. 진행 중인 작업 완료
3. Idle Improvement (선택적)

### 11.2 변경 정책

- Brain 단위 업데이트 **가능**
- 모델 교체 **가능**
- 롤백 **가능**
- 기본 파이프라인 변경 **불가**

---

## 12. 최종 정의

> **이 시스템은 "AI를 많이 쓰는 구조"가 아니라**
> **"코드 품질을 지키기 위해 AI를 통제하는 구조"이다.**

---

---

## Part B: 기술 구현 가이드

## Phase 1: 초기 설정 및 시스템 확인

### 1.1 첫 부팅 및 초기 설정

GX10은 **DGX OS 7.2.3** (Ubuntu 24.04 LTS 기반)이 설치되어 있습니다.

```bash
# DGX OS 첫 부팅 시 자동으로 Wi-Fi 핫스팟 생성
# Quick Start Guide의 SSID/Password로 접속
# 브라우저에서 http://spark-xxxx.local 접속하여 초기 설정:
#   - hostname 설정 (예: gx10-brain)
#   - username/password 설정
#   - 네트워크 설정 (고정 IP 권장)
#   - 시스템 업데이트 자동 진행 후 재부팅

# 설정 후 SSH로 접속하여 시스템 확인
uname -a  # Linux 6.8.x-dgx kernel 확인
cat /etc/os-release  # DGX OS / Ubuntu 24.04 확인
```

### 1.2 시스템 확인

```bash
# 시스템 정보
uname -a
cat /etc/os-release

# CPU 확인
lscpu | grep -E "Architecture|Model name|CPU\(s\)"

# GPU 확인
nvidia-smi

# 메모리 확인 (119GiB ≈ 128GB)
free -h

# 아키텍처 확인 (aarch64)
uname -m
```

### 1.3 시스템 업데이트 및 필수 패키지

```bash
# DGX OS 업데이트 (DGX Dashboard 또는 CLI)
sudo apt update && sudo apt upgrade -y

# 필수 도구 설치 (DGX OS에는 대부분 사전 설치되어 있음)
sudo apt install -y \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    htop \
    btop \
    tmux \
    vim \
    neovim \
    tree \
    jq \
    unzip \
    net-tools \
    openssh-server \
    python3-pip \
    python3-venv

# Python 3.12 확인 (DGX OS 기본)
python3 --version  # Python 3.12.x

# 중요: DGX OS도 PEP 668 적용 (externally managed environments)
# pip install --user는 사용하지 말 것
# 대신 python3-venv로 가상환경 사용 권장

# 사전 설치된 컴포넌트 확인
nvidia-smi          # NVIDIA 드라이버
nvcc --version      # CUDA Toolkit
docker --version    # Docker
nvidia-ctk --version # NVIDIA Container Toolkit
```

### 1.4 디렉토리 구조 생성

```bash
# 기본 구조
sudo mkdir -p /gx10/{brains,runtime,api,automation,system}

# Code Brain 디렉토리
sudo mkdir -p /gx10/brains/code/{models,prompts,execution,logs}

# Vision Brain 디렉토리
sudo mkdir -p /gx10/brains/vision/{models,cuda,benchmarks,logs}

# 런타임
sudo mkdir -p /gx10/runtime/{locks,logs}

# API
sudo mkdir -p /gx10/api

# 자동화
sudo mkdir -p /gx10/automation/{n8n,mcp}

# 시스템
sudo mkdir -p /gx10/system/{monitoring,update,backup}

# 소유권 설정
sudo chown -R $USER:$USER /gx10
```

### 1.5 환경변수 설정

```bash
cat >> ~/.bashrc << 'EOF'

# === GX10 AI System Configuration ===
export GX10_HOME="/gx10"
export OLLAMA_MODELS="/gx10/brains/code/models"
export HF_HOME="/gx10/brains/vision/models/huggingface"
export TORCH_HOME="/gx10/brains/vision/models/torch"

# CUDA (DGX OS에 사전 설치되어 있음)
export PATH="/usr/local/cuda/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"

# DGX OS CUDA 경로는 이미 설정되어 있을 가능성 높음
# 확인: echo $CUDA_HOME
```

# Aliases
alias gx="cd /gx10"
alias brain-status="/gx10/api/status.sh"
alias brain-switch="/gx10/api/switch.sh"
EOF

source ~/.bashrc
```

### 1.6 Docker 설정

```bash
# Docker 상태 확인 (DGX OS에 사전 설치됨)
docker --version
docker info

# NVIDIA Container Toolkit 확인 (사전 설치됨)
nvidia-ctk --version

# 사용자를 docker 그룹에 추가
sudo usermod -aG docker $USER
newgrp docker

# GPU 접근 테스트 (DGX OS에서는 바로 작동해야 함)
docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu24.04 nvidia-smi
```

### 1.7 SSH 설정

```bash
# SSH 서버 활성화
sudo systemctl enable ssh
sudo systemctl start ssh

# 방화벽 설정
sudo ufw allow ssh
sudo ufw allow 11434/tcp  # Ollama
sudo ufw allow 8080/tcp   # Open WebUI
sudo ufw allow 5678/tcp   # n8n
sudo ufw enable
```

---

## Phase 2: Code Brain 구축 (Native Mode)

### 2.1 Ollama 설치

```bash
# Ollama 설치
curl -fsSL https://ollama.com/install.sh | sh

# 버전 확인
ollama --version
```

### 2.2 Ollama 서비스 설정

```bash
# systemd 오버라이드 생성 (현재 운영 설정)
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf << EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_MODELS=/gx10/brains/code/models"
Environment="OLLAMA_KEEP_ALIVE=2h"
Environment="OLLAMA_NUM_PARALLEL=2"
Environment="OLLAMA_MAX_LOADED_MODELS=3"
Environment="OLLAMA_FLASH_ATTENTION=1"
EOF

sudo systemctl daemon-reload
sudo systemctl restart ollama
sudo systemctl enable ollama

# 상태 확인
sudo systemctl status ollama
curl http://localhost:11434/api/version
```

### 2.3 모델 다운로드

```bash
# 범용 추론 모델 (116.8B MoE, MXFP4)
# 소요 시간: ~15분 (LAN), 용량: 65GB
ollama pull gpt-oss:120b

# 텍스트 임베딩 모델 (RAG용)
# 소요 시간: ~2분, 용량: 4.7GB
ollama pull qwen3-embedding:latest

# 설치 확인
ollama list
```

> ⚠️ **설치 금지 (KB-020):** `qwen3-coder-next` (80B) — GB10 aarch64에서 전체 `?` 토큰 출력 버그  
> (llama.cpp #23010 OPEN). 대안: `qwen3-coder:30b` (MoE 19GB)

### 2.4 모델 테스트

```bash
# gpt-oss:120b 기본 테스트 (/api/chat 사용 — KB-019 참조)
curl http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-oss:120b",
    "messages": [{"role": "user", "content": "Write a Python fibonacci function with memoization"}],
    "stream": false
  }' | jq -r '.message.content'

# 예상 결과:
# - 응답 시작: ~5-10초
# - 토큰/초: ~38.5 (Ollama v0.30.6)
# - 메모리 사용: ~76 GiB

# ⚠️ /api/generate + num_predict < 1000 조합 금지 (KB-019: 빈 응답)
```

### 2.5 Open WebUI 설치 (선택사항)

```bash
# Open WebUI 컨테이너 실행
docker run -d \
    --name open-webui \
    --restart unless-stopped \
    -p 8080:8080 \
    -v /gx10/brains/code/webui:/app/backend/data \
    -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
    --add-host=host.docker.internal:host-gateway \
    ghcr.io/open-webui/open-webui:main

# 접속: http://gx10-ip:8080
```

---

## Phase 3: Vision Brain 구축 (Docker Mode)

### 3.1 Vision Brain Docker 이미지 빌드

```bash
# Dockerfile 생성
cat > /gx10/brains/vision/Dockerfile << 'EOF'
FROM nvcr.io/nvidia/pytorch:24.01-py3

# 작업 디렉토리
WORKDIR /workspace

# 시스템 패키지
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Python 패키지
RUN pip install --no-cache-dir \
    opencv-python \
    opencv-contrib-python \
    ultralytics \
    transformers \
    accelerate \
    timm \
    einops \
    matplotlib \
    seaborn \
    jupyter

# SAM2 설치
RUN pip install --no-cache-dir git+https://github.com/facebookresearch/segment-anything-2.git

# 포트
EXPOSE 8888

# 기본 명령
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
EOF
```

```bash
# 이미지 빌드
cd /gx10/brains/vision
docker build -t gx10-vision-brain:latest .
```

### 3.2 Vision 모델 다운로드

```bash
# Qwen2.5-VL 모델 (Ollama로)
ollama pull qwen2.5-vl:7b
ollama pull qwen2.5-vl:72b  # 고품질 분석용

# HuggingFace 모델 (직접 다운로드)
pip install huggingface_hub[cli]

# SAM2 체크포인트
mkdir -p /gx10/brains/vision/models/sam2
wget -P /gx10/brains/vision/models/sam2 \
    https://dl.fbaipublicfiles.com/segment_anything_2/072824/sam2_hiera_large.pt
```

### 3.3 Vision Brain 실행 스크립트

```bash
cat > /gx10/brains/vision/run.sh << 'EOF'
#!/bin/bash
docker run -d \
    --name vision-brain \
    --gpus all \
    --shm-size=16g \
    -p 8888:8888 \
    -v /gx10/brains/vision/models:/workspace/models \
    -v /gx10/brains/vision/benchmarks:/workspace/benchmarks \
    -v ~/.cache/huggingface:/root/.cache/huggingface \
    gx10-vision-brain:latest
EOF
chmod +x /gx10/brains/vision/run.sh
```

---

## Phase 4: Brain 전환 API 구축

### 4.1 상태 관리

```bash
# 초기 상태 파일 생성
cat > /gx10/runtime/active_brain.json << 'EOF'
{
  "active_brain": "none",
  "started_at": null,
  "last_task": null
}
EOF
```

### 4.2 상태 조회 스크립트

```bash
cat > /gx10/api/status.sh << 'EOF'
#!/bin/bash

echo "=== GX10 Brain Status ==="
echo ""

# 메모리 상태
echo "📊 Memory:"
free -h | grep -E "Mem|Swap"
echo ""

# GPU 상태
echo "🎮 GPU:"
nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader
echo ""

# Ollama 상태 (Code Brain)
echo "🧠 Code Brain (Ollama):"
if systemctl is-active --quiet ollama; then
    echo "  Status: ✅ Running"
    ollama ps 2>/dev/null || echo "  Models: None loaded"
else
    echo "  Status: ❌ Stopped"
fi
echo ""

# Vision Brain 상태
echo "👁️ Vision Brain (Docker):"
if docker ps -q -f name=vision-brain > /dev/null 2>&1; then
    echo "  Status: ✅ Running"
    docker stats vision-brain --no-stream --format "  Memory: {{.MemUsage}}"
else
    echo "  Status: ❌ Stopped"
fi
echo ""

# 현재 활성 Brain
echo "🎯 Active Brain:"
cat /gx10/runtime/active_brain.json | jq -r '.active_brain'
EOF
chmod +x /gx10/api/status.sh
```

### 4.3 Brain 전환 스크립트

```bash
cat > /gx10/api/switch.sh << 'EOF'
#!/bin/bash

TARGET=$1

if [ -z "$TARGET" ]; then
    echo "Usage: switch.sh [code|vision|none]"
    exit 1
fi

echo "=== Switching to $TARGET Brain ==="

# 1. 현재 Brain 정지
echo "[1/4] Stopping current brains..."

# Ollama 모델 언로드
ollama ps 2>/dev/null | tail -n +2 | awk '{print $1}' | while read model; do
    ollama stop $model 2>/dev/null
done

# Vision Brain 컨테이너 정지
docker stop vision-brain 2>/dev/null
docker rm vision-brain 2>/dev/null

# 2. Buffer Cache 플러시 (중요!)
echo "[2/4] Flushing buffer cache..."
sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'
sleep 3

# 3. 목표 Brain 시작
echo "[3/4] Starting $TARGET brain..."

case $TARGET in
    code)
        sudo systemctl start ollama
        sleep 5
        # 기본 모델 로드
        curl -s http://localhost:11434/api/generate -d '{"model":"qwen2.5-coder:32b","prompt":"hello","stream":false}' > /dev/null
        ;;
    vision)
        /gx10/brains/vision/run.sh
        sleep 10
        ;;
    none)
        sudo systemctl stop ollama
        ;;
esac

# 4. 상태 업데이트
echo "[4/4] Updating state..."
cat > /gx10/runtime/active_brain.json << INNER_EOF
{
  "active_brain": "$TARGET",
  "started_at": "$(date -Iseconds)",
  "last_task": null
}
INNER_EOF

echo "=== Switch Complete ==="
/gx10/api/status.sh
EOF
chmod +x /gx10/api/switch.sh
```

---

## Phase 5: n8n 자동화 연동

### 5.1 n8n 설치

```bash
# n8n Docker 컨테이너
docker run -d \
    --name n8n \
    --restart unless-stopped \
    -p 5678:5678 \
    -v /gx10/automation/n8n:/home/node/.n8n \
    -e GENERIC_TIMEZONE="Asia/Seoul" \
    --add-host=host.docker.internal:host-gateway \
    docker.n8n.io/n8nio/n8n

# 접속: http://gx10-ip:5678
```

### 5.2 n8n Ollama 연동 설정

n8n UI에서:
1. **Credentials** → **Add Credential** → **Ollama API**
2. Base URL: `http://host.docker.internal:11434`
3. 테스트 연결

### 5.3 예제 워크플로우: Webhook → Code Brain

```json
{
  "name": "Code Brain Execution",
  "nodes": [
    {
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "httpMethod": "POST",
        "path": "execute-code"
      }
    },
    {
      "name": "Ollama Chat",
      "type": "@n8n/n8n-nodes-langchain.lmChatOllama",
      "parameters": {
        "model": "qwen2.5-coder:32b",
        "baseUrl": "http://host.docker.internal:11434"
      }
    }
  ]
}
```

---

## Phase 6: MCP 서버 구축 (선택사항)

### 6.1 MCP 서버 설치

```bash
# MCP Python SDK 설치
pip install mcp

# MCP 서버 디렉토리
mkdir -p /gx10/automation/mcp/servers
```

### 6.2 Code Brain MCP 서버

```python
# /gx10/automation/mcp/servers/code_brain_server.py
from mcp.server import Server
from mcp.types import Tool, TextContent
import httpx
import json

server = Server("code-brain")

@server.tool("execute_code_task")
async def execute_code_task(
    prompt: str,
    model: str = "qwen2.5-coder:32b"
) -> list[TextContent]:
    """Execute a coding task on the local Code Brain"""
    
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://localhost:11434/api/generate",
            json={
                "model": model,
                "prompt": prompt,
                "stream": False
            },
            timeout=300.0
        )
        
    result = response.json()
    return [TextContent(type="text", text=result.get("response", ""))]

@server.tool("list_models")
async def list_models() -> list[TextContent]:
    """List available models on Code Brain"""
    
    async with httpx.AsyncClient() as client:
        response = await client.get("http://localhost:11434/api/tags")
        
    models = response.json().get("models", [])
    model_list = "\n".join([m["name"] for m in models])
    return [TextContent(type="text", text=model_list)]

if __name__ == "__main__":
    import asyncio
    asyncio.run(server.run())
```

---

## Phase 7: 서비스 자동화

### 7.1 시작 스크립트

```bash
cat > /gx10/system/start-all.sh << 'EOF'
#!/bin/bash
echo "=== GX10 System Starting ==="

# 1. Ollama (Code Brain 기본)
echo "[1/3] Starting Ollama..."
sudo systemctl start ollama
sleep 5

# 2. n8n
echo "[2/3] Starting n8n..."
docker start n8n 2>/dev/null || docker run -d \
    --name n8n \
    --restart unless-stopped \
    -p 5678:5678 \
    -v /gx10/automation/n8n:/home/node/.n8n \
    --add-host=host.docker.internal:host-gateway \
    docker.n8n.io/n8nio/n8n

# 3. 상태 초기화
echo "[3/3] Initializing state..."
cat > /gx10/runtime/active_brain.json << INNER_EOF
{
  "active_brain": "code",
  "started_at": "$(date -Iseconds)",
  "last_task": null
}
INNER_EOF

echo "=== System Ready ==="
/gx10/api/status.sh
EOF
chmod +x /gx10/system/start-all.sh
```

### 7.2 부팅 시 자동 시작

```bash
# crontab 등록
(crontab -l 2>/dev/null; echo "@reboot sleep 60 && /gx10/system/start-all.sh >> /gx10/runtime/logs/startup.log 2>&1") | crontab -

# 로그 디렉토리 확인
mkdir -p /gx10/runtime/logs
```

### 7.3 상태 모니터링

```bash
cat > /gx10/system/monitoring/health-check.sh << 'EOF'
#!/bin/bash
# 매 5분마다 실행 (crontab: */5 * * * *)

TIMESTAMP=$(date -Iseconds)
LOG_FILE="/gx10/runtime/logs/health.log"

# Ollama 체크
if curl -s http://localhost:11434/api/version > /dev/null; then
    OLLAMA_STATUS="OK"
else
    OLLAMA_STATUS="FAIL"
fi

# 메모리 체크
MEM_USED=$(free -g | awk '/Mem:/{print $3}')
MEM_TOTAL=$(free -g | awk '/Mem:/{print $2}')

# 로그 기록
echo "$TIMESTAMP | Ollama: $OLLAMA_STATUS | Memory: ${MEM_USED}/${MEM_TOTAL}GB" >> $LOG_FILE
EOF
chmod +x /gx10/system/monitoring/health-check.sh
```

---

## Phase 8: 테스트 및 검증

### 8.1 Code Brain 테스트

```bash
# Brain 전환
/gx10/api/switch.sh code

# 간단한 코드 생성 테스트
curl http://localhost:11434/api/generate -d '{
  "model": "qwen2.5-coder:32b",
  "prompt": "Write a Python class for a binary search tree with insert, search, and delete methods. Include docstrings and type hints.",
  "stream": false
}' | jq -r '.response'

# 성능 측정
time curl http://localhost:11434/api/generate -d '{
  "model": "qwen2.5-coder:32b",
  "prompt": "Explain the difference between async and sync programming in Python",
  "stream": false
}' > /dev/null
```

### 8.2 Vision Brain 테스트

```bash
# Brain 전환
/gx10/api/switch.sh vision

# Jupyter 접속 확인
curl -s http://localhost:8888 | head -1

# 컨테이너 내부 테스트
docker exec vision-brain python3 -c "
import torch
print(f'PyTorch: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'GPU: {torch.cuda.get_device_name(0)}')
"
```

### 8.3 통합 테스트

```bash
# 전체 시스템 상태
/gx10/api/status.sh

# Brain 전환 테스트
/gx10/api/switch.sh code
sleep 10
/gx10/api/status.sh

/gx10/api/switch.sh vision
sleep 15
/gx10/api/status.sh

/gx10/api/switch.sh code
```

---

## Part C: 빠른 참조

## 서비스 URL

| 서비스 | URL | 용도 |
|--------|-----|------|
| **Ollama API** | http://localhost:11434 | LLM 추론 (OpenAI 호환) |
| **Open WebUI** | http://localhost:8080 | 웹 채팅 UI |
| **SearXNG** | http://localhost:8888 | 프라이빗 검색엔진 |
| Dashboard | http://localhost:9000 | 시스템 모니터링 |

## 명령어 요약

```bash
# 상태 확인
/gx10/api/status.sh

# Ollama 직접 접근
ollama list                   # 모델 목록
ollama ps                     # 현재 로드된 모델
ollama run gpt-oss:120b       # 대화형 실행

# 서비스 관리
sudo systemctl status ollama  # Ollama 상태
docker ps                     # Docker 서비스 상태
```

## 운영 모델 현황 (2026-06-08)

| 모델 | 디스크 | 메모리 | 속도 | 용도 |
|------|--------|--------|------|------|
| `gpt-oss:120b` | 65 GB | ~76 GiB | **38.5 tok/s** | 범용 추론 (단일 엔드포인트) |
| `qwen3-embedding:latest` | 4.7 GB | ~5 GiB | — | RAG 임베딩 (4096차원) |

## 문제 해결

### Ollama 연결 실패
```bash
sudo systemctl restart ollama
journalctl -u ollama -f
```

### 메모리 부족
```bash
# Buffer cache 정리
sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'

# 실행 중인 모델 확인 및 정리
ollama ps
ollama stop <model-name>
```

### Brain 전환 실패
```bash
# 강제 정리
docker stop vision-brain 2>/dev/null
docker rm vision-brain 2>/dev/null
sudo systemctl stop ollama
sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'
sleep 10
/gx10/api/switch.sh code
```

---

## Part D: 개발자 PC 연동

## Aider 설정 (CLI 페어 프로그래밍)

### 설치

```bash
# pipx로 설치 (권장)
pip install pipx
pipx install aider-chat

# 환경변수 설정 (개발자 PC의 .bashrc)
export OLLAMA_API_BASE=http://gx10-brain.local:11434
```

### 사용법

```bash
# 프로젝트 디렉토리에서 Aider 실행
cd /path/to/project
aider --model ollama_chat/qwen2.5-coder:32b

# ⚠️ 중요: Ollama 컨텍스트 길이 설정 필수 (GX10에서)
# /etc/systemd/system/ollama.service.d/override.conf에 추가:
# Environment="OLLAMA_CONTEXT_LENGTH=32768"
```

**Aider 벤치마크 결과:**
- Qwen2.5-Coder-32B: **73.7점** (GPT-4o: 71점, Claude 3.5 Sonnet: 84점)

---

## Continue.dev 설정 (VS Code)

```json
// ~/.continue/config.json
{
  "models": [
    {
      "title": "GX10 Code Brain",
      "provider": "ollama",
      "model": "qwen2.5-coder:32b",
      "apiBase": "http://gx10-brain.local:11434"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Fast Complete",
    "provider": "ollama",
    "model": "qwen2.5-coder:7b",
    "apiBase": "http://gx10-brain.local:11434"
  },
  "embeddingsProvider": {
    "provider": "ollama",
    "model": "nomic-embed-text",
    "apiBase": "http://gx10-brain.local:11434"
  }
}
```

---

## OpenHands 설정 (자율 에이전트)

```bash
# GX10에서 OpenHands 실행
docker run -d \
    --name openhands \
    -p 3001:3000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v ~/.openhands-state:/.openhands-state \
    -e LLM_OLLAMA_BASE_URL="http://host.docker.internal:11434" \
    --add-host=host.docker.internal:host-gateway \
    docker.all-hands.dev/all-hands-ai/openhands:latest
```

**UI 설정 (http://gx10-ip:3001):**
- Model: `ollama/qwen2.5-coder:32b`
- Base URL: `http://host.docker.internal:11434`
- API Key: `dummy`

⚠️ **필수:** Ollama 컨텍스트 길이 최소 22,000 토큰

---

## SSH 터널 (개발자 PC에서)

```bash
# Ollama API 포워딩
ssh -N -L 11434:localhost:11434 user@gx10-brain.local &

# n8n 포워딩
ssh -N -L 5678:localhost:5678 user@gx10-brain.local &
```

---

## Part E: 최종 아키텍처

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              개발자 PC                                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ Claude Code │  │   VS Code   │  │    Warp     │  │   Gitea     │        │
│  │  (설계)     │  │ +Continue   │  │ (터미널)    │  │ (Git 서버)  │        │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │
│         └────────────────┴────────────────┴────────────────┘               │
│                                   │ SSH / Tailscale                        │
└───────────────────────────────────┼─────────────────────────────────────────┘
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GX10 Brain Server                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         128GB Unified Memory                         │   │
│  │  ┌───────────────────────────┐  ┌───────────────────────────┐       │   │
│  │  │      CODE BRAIN           │OR│      VISION BRAIN         │       │   │
│  │  │      (Native)             │  │      (Docker)             │       │   │
│  │  │  • qwen2.5-coder:32b      │  │  • qwen2.5-vl:72b         │       │   │
│  │  │  • qwen2.5-coder:7b       │  │  • YOLO/SAM2              │       │   │
│  │  │  메모리: 30-40GB          │  │  메모리: 70-90GB          │       │   │
│  │  └───────────────────────────┘  └───────────────────────────┘       │   │
│  │                     ⚠️ 동시 실행 금지                                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  n8n (워크플로우)  │  MCP Server  │  Brain Switch API                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Appendix

## A. 검증된 벤치마크 출처

| 출처 | 날짜 | 주요 데이터 |
|------|------|-------------|
| [LMSYS Org](https://lmsys.org/blog/2025-10-13-nvidia-dgx-spark/) | 2025-10 | SGLang 배치, DeepSeek-R1 83.5 tok/s |
| [ProX PC](https://www.proxpc.com/blogs/nvidia-dgx-spark-gb10-performance-test-vs-5090-llm-image-and-video-generation) | 2025-12 | Qwen2.5-72B: 4.6 tok/s, TTFT 133초 |
| [NVIDIA Blog](https://developer.nvidia.com/blog/how-nvidia-dgx-sparks-performance-enables-intensive-ai-tasks/) | 2025-10 | Qwen3-235B 듀얼: 23,477 tok/s |
| [Brandon RC](https://brandonrc.github.io/benchmark-spark/phase1/index.html) | 2025-11 | Docker 20-30GB 오버헤드 |

## B. 운영 모델 성능 (2026-06-08 실측)

| 모델 | 메모리 | 속도 | 용도 |
|------|--------|------|------|
| `gpt-oss:120b` (MXFP4 MoE) | ~76 GiB | **38.5 tok/s** | 범용 추론 (단일 엔드포인트) |
| `qwen3-embedding:latest` (Q4_K_M) | ~5 GiB | — | RAG 임베딩 4096차원 |

**설치 금지 목록 (KB-020):**
| 모델 | 이유 |
|------|------|
| `qwen3-coder-next` (80B) | GB10 aarch64에서 전체 `?` 토큰 출력 (llama.cpp #23010 OPEN) |

## C. 라이선스

| 구성요소 | 라이선스 | 상업적 사용 |
|----------|----------|-------------|
| gpt-oss (Microsoft OSS) | MIT | ✅ |
| qwen3-embedding (Qwen) | Apache 2.0 | ✅ |
| Ollama | MIT | ✅ |
| Open WebUI | MIT | ✅ |
| SearXNG | AGPL-3.0 | ⚠️ 조건부 |

## D. 버전 정보 (현재 운영 기준)

| 구성요소 | 현재 버전 |
|----------|----------|
| OS | DGX OS 7.2.3 (Ubuntu 24.04.4 LTS) |
| 커널 | 6.17.0-1018-nvidia |
| GPU 드라이버 | NVIDIA 580.159.03 |
| CUDA | 13.0 |
| Ollama | **v0.30.6** (2026-06-08 업그레이드) |
| Docker | 24.x+ |
| Python | 3.12 |

## E. 체크리스트

### 설치 완료 확인
- [ ] DGX OS 초기 설정
- [ ] `nvidia-smi` 정상 출력
- [ ] Ollama 설치 및 모델 다운로드
- [ ] Docker GPU 패스스루 테스트
- [ ] Brain 전환 스크립트 동작
- [ ] n8n + Ollama 연동
- [ ] 개발자 PC SSH 접속

---

**문서 끝**

*성능 데이터는 실측 기준입니다. Ollama 버전 업그레이드에 따라 수치가 변동될 수 있습니다.*

---

## 📜 수정 이력

| 일자 | 버전 | 설명 | 리뷰어 |
|------|------|------|--------|
| 2026-06-08 | 2.3 | Ollama v0.30.6 업그레이드 반영, gpt-oss:120b 단일 모델 체계, 38.5 tok/s 실측, KB-019/020 추가, 전체 모델 참조 현행화 | holee |
| 2026-02-02 | 2.2 | DGX OS 7.2.3 기반으로 수정 (사전 설치된 컴포넌트 활용) | drake |
| 2026-02-02 | 2.1 | Ubuntu 24.04 LTS 변경 사항 반영 | drake |
| 2026-02-01 | 2.0 | 딥 리서치 기반 전면 재구성 | drake |

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
  ✅ 작성자 정보 표준화 유지
  ✅ v2.0 문서로서 버전 정보 정확히 반영
  ✅ 딥 리서치 기반 재구성 사항 명확함
  ✅ 수정자 섹션 추가로 변경 추적 개선
  💡 참고: 수정 이력 테이블의 v2.0 변경 사항과 작성자 정보 연계 확인 필요
-->
