# ASUS Ascent GX10 로컬 AI 개발 환경 구축 가이드

> **목표**: 구독 API 없이 완전 로컬에서 동작하는 통합 AI 개발 시스템  
> **용도**: Coding Agent + Vision AI를 1대의 GX10에서 운용

---

## 시스템 아키텍처 개요

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        ASUS Ascent GX10                                  │
│         GB10 Grace Blackwell Superchip / 128GB Unified Memory            │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                        LLM Inference Layer                         │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────────┐ │  │
│  │  │   Ollama    │  │    vLLM     │  │   Docker Model Runner       │ │  │
│  │  │  (Primary)  │  │ (Optional)  │  │   (Alternative)             │ │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────────────────┘ │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌─────────────────────────────┐  ┌─────────────────────────────────┐   │
│  │      Coding Agent          │  │        Vision AI                │   │
│  ├─────────────────────────────┤  ├─────────────────────────────────┤   │
│  │ Models:                    │  │ Models:                         │   │
│  │ • Qwen2.5-Coder-32B        │  │ • Qwen2.5-VL-7B/72B             │   │
│  │ • DeepSeek-Coder-V2        │  │ • LLaVA-NeXT                    │   │
│  │ • Codestral-22B            │  │ • MiniCPM-V                     │   │
│  │ • GPT-OSS (option)         │  │                                 │   │
│  ├─────────────────────────────┤  ├─────────────────────────────────┤   │
│  │ Agents:                    │  │ Frameworks:                     │   │
│  │ • Cline (VS Code)          │  │ • PyTorch + TorchVision         │   │
│  │ • Aider (CLI)              │  │ • OpenCV + CUDA                 │   │
│  │ • Continue.dev             │  │ • Ultralytics (YOLO)            │   │
│  │ • OpenHands                │  │ • SAM2, Depth-Anything          │   │
│  └─────────────────────────────┘  └─────────────────────────────────┘   │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                        Interface Layer                             │  │
│  │   Open WebUI │ Jupyter Lab │ VS Code Server │ ComfyUI (Optional)  │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: 초기 설정 및 시스템 확인

### 1.1 첫 부팅 및 초기 설정

GX10은 **DGX OS 7.2.3** (Ubuntu 24.04 LTS 기반)이 설치되어 있습니다.

```bash
# DGX OS 첫 부팅 시 Wi-Fi 핫스팟 자동 생성
# Quick Start Guide의 SSID/Password로 접속
# 브라우저에서 http://spark-xxxx.local 접속하여 초기 설정 진행
# - hostname, username, password, network 설정
# - 시스템 업데이트 자동 진행 후 재부팅

# 설정 완료 후 SSH로 접속
uname -a  # Linux 6.8.x-dgx kernel
cat /etc/os-release  # DGX OS / Ubuntu 24.04 LTS
```

### 1.2 시스템 사양 확인

```bash
# 시스템 정보
uname -a
cat /etc/os-release

# CPU 확인 (ARM v9.2-A: 10x Cortex-X925 + 10x Cortex-A725)
lscpu

# GPU 확인 (NVIDIA Blackwell GB10)
nvidia-smi

# 통합 메모리 확인 (128GB)
free -h

# 스토리지 확인
df -h
lsblk

# 아키텍처 확인 (aarch64)
uname -m
```

### 1.3 시스템 업데이트

```bash
# DGX OS 업데이트 (DGX Dashboard 또는 CLI)
sudo apt update && sudo apt upgrade -y

# 필수 도구 설치 (대부분 DGX OS에 사전 설치)
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
    p7zip-full \
    net-tools \
    openssh-server

# Python 3.12 확인 (DGX OS 기본 버전)
python3 --version  # Python 3.12.x

# 중요: DGX OS도 PEP 668 적용
# pip install --user 사용 시 경고 발생
# python3-venv로 가상환경 사용 권장

# DGX OS 사전 설치 컴포넌트 확인
nvidia-smi              # NVIDIA 드라이버 (사전 설치)
nvcc --version          # CUDA Toolkit (사전 설치)
docker --version        # Docker (사전 설치)
nvidia-ctk --version    # NVIDIA Container Toolkit (사전 설치)
```

### 1.4 작업 디렉토리 구성

```bash
# AI 워크스페이스 구조
mkdir -p ~/workspace/{agents,vision,models,data,projects,scripts}
mkdir -p ~/workspace/models/{ollama,huggingface,checkpoints}
mkdir -p ~/workspace/data/{datasets,outputs,cache}

# 환경변수 설정
cat >> ~/.bashrc << 'EOF'

# === AI Workspace Configuration ===
export WORKSPACE="$HOME/workspace"
export HF_HOME="$WORKSPACE/models/huggingface"
export HF_HUB_CACHE="$WORKSPACE/models/huggingface"
export OLLAMA_MODELS="$WORKSPACE/models/ollama"
export TORCH_HOME="$WORKSPACE/models/checkpoints"

# CUDA paths (DGX OS에 사전 설치되어 있음)
export PATH="/usr/local/cuda/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"

# DGX OS에서는 CUDA_HOME 이미 설정되어 있을 가능성 높음
# 확인: echo $CUDA_HOME
```

# Convenience aliases
alias ws="cd $WORKSPACE"
alias models="cd $WORKSPACE/models"
alias projects="cd $WORKSPACE/projects"
EOF

source ~/.bashrc
```

### 1.5 Docker 및 NVIDIA Container Toolkit

```bash
# Docker 상태 확인 (DGX OS에 사전 설치됨)
docker --version
docker info

# NVIDIA Container Toolkit 확인 (사전 설치됨)
nvidia-ctk --version

# Docker 서비스 활성화 (이미 활성화되어 있을 수 있음)
sudo systemctl enable docker
sudo systemctl start docker

# 사용자를 docker 그룹에 추가
sudo usermod -aG docker $USER
newgrp docker

# GPU 접근 테스트 (DGX OS에서는 바로 작동)
docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu24.04 nvidia-smi
```

### 1.6 원격 접속 설정

```bash
# SSH 서버 활성화
sudo systemctl enable ssh
sudo systemctl start ssh

# (선택) Tailscale VPN 설치 - 외부 접속용
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

---

## Phase 2: LLM 추론 인프라 구축

### 2.1 Ollama 설치 및 설정

Ollama는 GX10/DGX Spark에 최적화되어 있습니다.

```bash
# Ollama 설치
curl -fsSL https://ollama.com/install.sh | sh

# 서비스 상태 확인
sudo systemctl status ollama

# 외부 접속 및 모델 저장 경로 설정
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf << EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_MODELS=$HOME/workspace/models/ollama"
Environment="OLLAMA_KEEP_ALIVE=24h"
EOF

sudo systemctl daemon-reload
sudo systemctl restart ollama

# 설치 확인
ollama --version
curl http://localhost:11434/api/version
```

### 2.2 코딩용 LLM 모델 설치

128GB 통합 메모리를 활용한 대형 코딩 모델 구성:

```bash
# === 필수 코딩 모델 ===

# 1. Qwen2.5-Coder-32B (최고 성능 오픈소스 코딩 모델)
#    - 92개 이상 프로그래밍 언어 지원
#    - 128K 컨텍스트 윈도우
ollama pull qwen2.5-coder:32b

# 2. DeepSeek-Coder-V2 (다국어 코딩 + 수학 강점)
ollama pull deepseek-coder-v2:16b

# 3. Codestral-22B (Mistral의 코딩 특화 모델)
ollama pull codestral:22b

# === 빠른 응답용 경량 모델 ===

# 4. Qwen2.5-Coder-7B (자동완성, 빠른 응답)
ollama pull qwen2.5-coder:7b

# 5. DeepSeek-Coder-V2-Lite (경량 대안)
ollama pull deepseek-coder-v2:lite

# === 범용 추론 모델 (선택) ===

# 6. Qwen2.5-72B (범용 추론, 128GB 메모리 필요)
ollama pull qwen2.5:72b

# 7. Llama-3.1-70B (Meta의 대형 모델)
ollama pull llama3.1:70b

# 설치된 모델 확인
ollama list

# 모델 테스트
ollama run qwen2.5-coder:32b "Write a Python function to calculate fibonacci"
```

### 2.3 Open WebUI 설치 (웹 채팅 인터페이스)

```bash
# Open WebUI 컨테이너 실행
docker run -d \
    --name open-webui \
    --restart always \
    --gpus all \
    -p 8080:8080 \
    -v open-webui-data:/app/backend/data \
    -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
    --add-host=host.docker.internal:host-gateway \
    ghcr.io/open-webui/open-webui:main

# 상태 확인
docker logs -f open-webui

# 접속: http://localhost:8080
# 첫 접속시 관리자 계정 생성
```

---

## Phase 3: Coding Agent 시스템 구축

### 3.1 Python 기본 환경

```bash
# Python 개발 도구 (Python 3.12 포함, DGX OS에 사전 설치)
sudo apt install -y python3-pip python3-venv python3-dev

# Python 버전 확인
python3 --version  # Python 3.12.x

# pipx 설치 (CLI 도구 관리)
# DGX OS도 PEP 668 적용으로 가상환경 통한 설치 권장
python3 -m venv ~/.local/pipx-env
source ~/.local/pipx-env/bin/activate
pip install pipx
pipx ensurepath
deactivate
source ~/.bashrc
```

### 3.2 Aider 설치 (CLI 코딩 에이전트)

Aider는 Git 통합 AI 페어 프로그래밍 도구입니다.

```bash
# Aider 설치
pipx install aider-chat

# 또는 가상환경으로 설치
cd ~/workspace/agents
python3 -m venv aider-env
source aider-env/bin/activate
pip install aider-chat

# Aider 설정 파일
cat > ~/.aider.conf.yml << 'EOF'
# Ollama 로컬 모델 사용
model: ollama/qwen2.5-coder:32b

# 빠른 모델 (자동완성용)
weak-model: ollama/qwen2.5-coder:7b

# Git 설정
auto-commits: true
dirty-commits: true

# UI 설정
dark-mode: true
pretty: true
stream: true
EOF

# Aider 실행 테스트
cd ~/workspace/projects
mkdir test-project && cd test-project
git init
aider --model ollama/qwen2.5-coder:32b
```

### 3.3 Cline 설치 (VS Code 확장)

Cline은 VS Code 내 자율 코딩 에이전트입니다.

```bash
# VS Code 설치 (ARM64)
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install -y code

# Cline 확장 설치
code --install-extension saoudrizwan.claude-dev
```

**Cline 설정** (VS Code 내에서):
1. Cline 사이드바 열기
2. Settings → API Provider → Ollama 선택
3. Model: `qwen2.5-coder:32b`
4. Base URL: `http://localhost:11434`

### 3.4 Continue.dev 설치 (IDE 통합)

```bash
# Continue 확장 설치
code --install-extension Continue.continue

# 설정 파일 생성
mkdir -p ~/.continue
cat > ~/.continue/config.json << 'EOF'
{
  "models": [
    {
      "title": "Qwen2.5-Coder-32B (Main)",
      "provider": "ollama",
      "model": "qwen2.5-coder:32b",
      "apiBase": "http://localhost:11434"
    },
    {
      "title": "DeepSeek-Coder-V2",
      "provider": "ollama",
      "model": "deepseek-coder-v2:16b",
      "apiBase": "http://localhost:11434"
    },
    {
      "title": "Codestral",
      "provider": "ollama",
      "model": "codestral:22b",
      "apiBase": "http://localhost:11434"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Fast Autocomplete",
    "provider": "ollama",
    "model": "qwen2.5-coder:7b",
    "apiBase": "http://localhost:11434"
  },
  "embeddingsProvider": {
    "provider": "ollama",
    "model": "nomic-embed-text",
    "apiBase": "http://localhost:11434"
  },
  "reranker": {
    "name": "none"
  }
}
EOF

# 임베딩 모델 설치 (코드베이스 검색용)
ollama pull nomic-embed-text
```

### 3.5 OpenHands 설치 (자율 개발 에이전트)

```bash
# Docker로 OpenHands 실행
docker pull ghcr.io/all-hands-ai/openhands:main

# OpenHands 실행 스크립트
cat > ~/workspace/scripts/start-openhands.sh << 'EOF'
#!/bin/bash
docker run -it --rm \
    --name openhands \
    -p 3001:3000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v ~/workspace/projects:/opt/workspace \
    -e SANDBOX_RUNTIME_CONTAINER_IMAGE=ghcr.io/all-hands-ai/runtime:main \
    -e LLM_MODEL="ollama/qwen2.5-coder:32b" \
    -e LLM_API_KEY="ollama" \
    -e LLM_BASE_URL="http://host.docker.internal:11434/v1" \
    --add-host=host.docker.internal:host-gateway \
    ghcr.io/all-hands-ai/openhands:main
EOF
chmod +x ~/workspace/scripts/start-openhands.sh

# 접속: http://localhost:3001
```

---

## Phase 4: Vision AI 시스템 구축

### 4.1 Vision AI 환경 구성

```bash
# Vision AI 전용 가상환경
cd ~/workspace/vision
python3 -m venv vision-env
source vision-env/bin/activate

# PyTorch 설치 (ARM64 + CUDA)
pip install torch torchvision torchaudio

# 설치 확인
python3 << 'EOF'
import torch
print(f"PyTorch: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")
    print(f"Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.1f} GB")
EOF
```

### 4.2 Computer Vision 라이브러리

```bash
source ~/workspace/vision/vision-env/bin/activate

# 핵심 라이브러리
pip install \
    opencv-python \
    opencv-contrib-python \
    numpy \
    scipy \
    scikit-image \
    scikit-learn \
    pillow \
    albumentations \
    imageio \
    imageio-ffmpeg

# 딥러닝 프레임워크
pip install \
    transformers \
    accelerate \
    datasets \
    timm \
    einops \
    safetensors

# Object Detection
pip install ultralytics  # YOLO

# 시각화
pip install \
    matplotlib \
    seaborn \
    plotly
```

### 4.3 Vision Language Model 설치

```bash
# Ollama로 Vision LLM 설치

# Qwen2.5-VL (주력 Vision LLM)
# - 이미지/비디오 이해, OCR, 객체 인식
# - 29개 언어 지원
ollama pull qwen2.5-vl:7b
ollama pull qwen2.5-vl:72b  # 대형 모델 (고품질 분석용)

# LLaVA (대안)
ollama pull llava:13b

# 테스트
ollama run qwen2.5-vl:7b "이 이미지를 분석해주세요"
```

### 4.4 Hugging Face 모델 다운로드

```bash
source ~/workspace/vision/vision-env/bin/activate

# HF CLI 설치
pip install huggingface_hub[cli]

# 오프라인 사용을 위한 모델 사전 다운로드

# Depth Estimation
huggingface-cli download depth-anything/Depth-Anything-V2-Large \
    --local-dir $HF_HOME/depth-anything-v2-large

# Segmentation (SAM2)
huggingface-cli download facebook/sam2-hiera-large \
    --local-dir $HF_HOME/sam2-hiera-large

# CLIP (이미지-텍스트 임베딩)
huggingface-cli download openai/clip-vit-large-patch14 \
    --local-dir $HF_HOME/clip-vit-large
```

### 4.5 YOLO 설정

```bash
source ~/workspace/vision/vision-env/bin/activate

# YOLO 모델 다운로드 및 테스트
python3 << 'EOF'
from ultralytics import YOLO

# YOLOv8 모델 다운로드
model = YOLO('yolov8x.pt')  # Extra large model
print("YOLOv8 loaded successfully!")

# 모델 정보
print(f"Model: {model.model}")
print(f"Task: {model.task}")
EOF
```

### 4.6 Segment Anything Model 2 (SAM2)

```bash
source ~/workspace/vision/vision-env/bin/activate

cd ~/workspace/vision
git clone https://github.com/facebookresearch/segment-anything-2.git
cd segment-anything-2

pip install -e .

# 체크포인트 다운로드
mkdir -p checkpoints
cd checkpoints
wget https://dl.fbaipublicfiles.com/segment_anything_2/072824/sam2_hiera_large.pt
```

### 4.7 Jupyter Lab 설정

```bash
source ~/workspace/vision/vision-env/bin/activate

pip install jupyterlab ipywidgets jupyter-ai

# Jupyter 설정
jupyter lab --generate-config
jupyter lab password

# 서비스 파일 생성
sudo tee /etc/systemd/system/jupyter.service << EOF
[Unit]
Description=Jupyter Lab Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/workspace
Environment="PATH=$HOME/workspace/vision/vision-env/bin:/usr/local/bin:/usr/bin"
ExecStart=$HOME/workspace/vision/vision-env/bin/jupyter lab --ip=0.0.0.0 --port=8888 --no-browser
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable jupyter
sudo systemctl start jupyter

# 접속: http://localhost:8888
```

---

## Phase 5: 통합 관리 및 자동화

### 5.1 서비스 관리 스크립트

```bash
# 전체 서비스 시작 스크립트
cat > ~/workspace/scripts/start-all.sh << 'EOF'
#!/bin/bash
echo "=========================================="
echo "    GX10 AI Services Starting...          "
echo "=========================================="

# 1. Ollama
echo "[1/4] Starting Ollama..."
sudo systemctl start ollama
sleep 3

# 2. Open WebUI
echo "[2/4] Starting Open WebUI..."
docker start open-webui 2>/dev/null || \
    docker run -d --name open-webui --restart always --gpus all \
    -p 8080:8080 -v open-webui-data:/app/backend/data \
    -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
    --add-host=host.docker.internal:host-gateway \
    ghcr.io/open-webui/open-webui:main

# 3. Jupyter Lab
echo "[3/4] Starting Jupyter Lab..."
sudo systemctl start jupyter

# 4. 상태 확인
echo "[4/4] Checking services..."
sleep 2

echo ""
echo "=========================================="
echo "    Services Ready                        "
echo "=========================================="
echo "  Open WebUI  : http://localhost:8080"
echo "  Jupyter Lab : http://localhost:8888"
echo "  Ollama API  : http://localhost:11434"
echo "=========================================="
EOF
chmod +x ~/workspace/scripts/start-all.sh
```

```bash
# 상태 확인 스크립트
cat > ~/workspace/scripts/status.sh << 'EOF'
#!/bin/bash
echo "=========================================="
echo "    GX10 System Status                    "
echo "=========================================="

echo ""
echo "📊 GPU Status:"
nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader

echo ""
echo "💾 Memory:"
free -h | grep -E "Mem|Swap"

echo ""
echo "🐳 Docker Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  Docker not running"

echo ""
echo "⚙️  Services:"
systemctl is-active --quiet ollama && echo "  ✅ Ollama: Running" || echo "  ❌ Ollama: Stopped"
systemctl is-active --quiet jupyter && echo "  ✅ Jupyter: Running" || echo "  ❌ Jupyter: Stopped"
docker ps -q -f name=open-webui > /dev/null 2>&1 && echo "  ✅ Open WebUI: Running" || echo "  ❌ Open WebUI: Stopped"

echo ""
echo "🤖 Ollama Models:"
ollama list 2>/dev/null || echo "  Cannot connect to Ollama"

echo ""
echo "💿 Storage:"
df -h / | tail -1 | awk '{print "  Used: "$3" / "$2" ("$5")"}'
EOF
chmod +x ~/workspace/scripts/status.sh
```

```bash
# 환경 활성화 스크립트
cat > ~/workspace/scripts/activate-coding.sh << 'EOF'
#!/bin/bash
echo "🚀 Coding Agent Environment"
echo ""

# Ollama 확인
if curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
    echo "✅ Ollama: Connected"
    echo "   Models: $(ollama list 2>/dev/null | tail -n +2 | wc -l)"
else
    echo "⚠️  Starting Ollama..."
    sudo systemctl start ollama
fi

echo ""
echo "Available commands:"
echo "  aider              - CLI pair programming"
echo "  code .             - VS Code with Cline/Continue"
echo "  ollama run <model> - Direct model interaction"
EOF
chmod +x ~/workspace/scripts/activate-coding.sh

cat > ~/workspace/scripts/activate-vision.sh << 'EOF'
#!/bin/bash
echo "👁️  Vision AI Environment"
source ~/workspace/vision/vision-env/bin/activate
echo ""
echo "✅ Python environment activated"
echo ""
echo "Available tools:"
echo "  jupyter lab - Notebook interface"
echo "  python      - PyTorch/Vision environment"
echo "  yolo        - Object detection CLI"
EOF
chmod +x ~/workspace/scripts/activate-vision.sh
```

### 5.2 부팅시 자동 시작

```bash
# crontab 등록
(crontab -l 2>/dev/null; echo "@reboot sleep 60 && $HOME/workspace/scripts/start-all.sh >> $HOME/workspace/logs/startup.log 2>&1") | crontab -

# 로그 디렉토리 생성
mkdir -p ~/workspace/logs
```

### 5.3 Bash 별칭 추가

```bash
cat >> ~/.bashrc << 'EOF'

# GX10 AI System Aliases
alias ai-start="~/workspace/scripts/start-all.sh"
alias ai-status="~/workspace/scripts/status.sh"
alias ai-coding="source ~/workspace/scripts/activate-coding.sh"
alias ai-vision="source ~/workspace/scripts/activate-vision.sh"

# Quick model access
alias chat="ollama run qwen2.5-coder:32b"
alias chat-fast="ollama run qwen2.5-coder:7b"
alias vision="ollama run qwen2.5-vl:7b"
EOF

source ~/.bashrc
```

---

## Phase 6: 테스트 및 검증

### 6.1 Coding Agent 테스트

```bash
# Aider 테스트
ai-coding
cd ~/workspace/projects
mkdir hello-world && cd hello-world
git init

aider --model ollama/qwen2.5-coder:32b

# Aider 프롬프트에서:
# > Create a REST API with FastAPI that has CRUD operations for a todo list
# > Add unit tests using pytest
# > Generate documentation
```

### 6.2 Vision AI 테스트

```bash
ai-vision

python3 << 'EOF'
import torch
from ultralytics import YOLO
from transformers import pipeline

print("=" * 50)
print("Vision AI Environment Test")
print("=" * 50)

# PyTorch
print(f"\n✅ PyTorch: {torch.__version__}")
print(f"   CUDA: {torch.cuda.is_available()}")

# YOLO
model = YOLO('yolov8n.pt')
print(f"\n✅ YOLO: Loaded successfully")

# Transformers
print(f"\n✅ Transformers: Ready")

print("\n" + "=" * 50)
print("All tests passed!")
print("=" * 50)
EOF
```

### 6.3 통합 테스트

```bash
# 전체 시스템 상태 확인
ai-status

# 각 서비스 접속 테스트
curl -s http://localhost:11434/api/version | jq .
curl -s http://localhost:8080 > /dev/null && echo "Open WebUI: OK"
curl -s http://localhost:8888 > /dev/null && echo "Jupyter: OK"
```

---

## 빠른 참조

### 서비스 접속 URL

| Service | URL | Description |
|---------|-----|-------------|
| Open WebUI | http://localhost:8080 | 웹 채팅 인터페이스 |
| Jupyter Lab | http://localhost:8888 | 노트북 환경 |
| Ollama API | http://localhost:11434 | LLM API 엔드포인트 |
| OpenHands | http://localhost:3001 | 자율 개발 에이전트 |

### 권장 모델 구성

| 용도 | 모델 | 크기 | 비고 |
|------|------|------|------|
| 코딩 (메인) | qwen2.5-coder:32b | ~20GB | 최고 성능 |
| 코딩 (빠름) | qwen2.5-coder:7b | ~4GB | 자동완성 |
| 코딩 (대안) | deepseek-coder-v2:16b | ~10GB | 수학/논리 강점 |
| 코딩 (대안) | codestral:22b | ~13GB | Mistral |
| Vision | qwen2.5-vl:7b | ~5GB | 이미지/OCR |
| Vision (고품질) | qwen2.5-vl:72b | ~45GB | 복잡한 분석 |
| 임베딩 | nomic-embed-text | ~275MB | 코드 검색 |

### 명령어 요약

```bash
# 서비스 관리
ai-start          # 전체 서비스 시작
ai-status         # 상태 확인

# 환경 활성화
ai-coding         # 코딩 환경
ai-vision         # Vision AI 환경

# 빠른 채팅
chat              # 32B 코딩 모델
chat-fast         # 7B 빠른 응답
vision            # Vision LLM

# Ollama 관리
ollama list       # 설치된 모델
ollama ps         # 실행 중인 모델
ollama stop <model>  # 모델 중지
```

---

## 문제 해결

### Ollama 연결 문제

```bash
# 서비스 재시작
sudo systemctl restart ollama

# 로그 확인
journalctl -u ollama -f

# 포트 확인
ss -tlnp | grep 11434
```

### GPU 메모리 부족

```bash
# 실행 중인 모델 확인 및 정리
ollama ps
ollama stop <model-name>

# GPU 메모리 상태
nvidia-smi

# 캐시 정리
sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
```

### Docker 권한 문제

```bash
sudo usermod -aG docker $USER
newgrp docker
# 또는 재로그인
```

### 모델 다운로드 실패

```bash
# 재시도
ollama pull <model-name>

# 네트워크 확인
curl -I https://ollama.com

# 수동 다운로드 후 import
# ollama create <name> -f Modelfile
```
---

## 📝 문서 정보

**작성자**:

- AI: Claude Sonnet 4.5
- 환경: MoAI-ADK v11.0.0
- 작성일: 2026-02-01

**리뷰어**:

- drake

