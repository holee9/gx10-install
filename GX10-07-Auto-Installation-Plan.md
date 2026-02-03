# GX10 자동 구축 스크립트 계획서

## 문서 개요

본 문서는 GX10 OS 설치 후 자동 구축을 위한 단계별 스크립트 계획을 정의합니다.

## 구축 단계 개요

### Phase 0: Sudo 사전 실행 (권한 필요 작업 일괄 처리)

| 단계 | 스크립트 | 설명 | sudo 필요 | 예상 소요 시간 |
|------|---------|------|-----------|---------------|
| **00** | **`00-sudo-prereqs.sh`** | **모든 sudo 필요 작업 일괄 실행** | **Yes** | **15-20분** |

Phase 0이 완료되면 이후 모든 단계는 **sudo 없이** 실행 가능합니다.

```bash
# Phase 0 실행 (한 번만 sudo 필요)
cd scripts/install
sudo ./00-sudo-prereqs.sh
```

### Phase 1-10: 자동 설치 (sudo 불필요)

| 단계 | 스크립트 | 설명 | sudo 필요 | 예상 소요 시간 |
|------|---------|------|-----------|---------------|
| 01 | `01-initial-setup.sh` | 시스템 업데이트 및 필수 패키지 설치 | Phase 0에서 완료 | - |
| 02 | `02-directory-structure.sh` | 디렉토리 구조 생성 및 권한 설정 | Phase 0에서 완료 | - |
| 03 | `03-environment-config.sh` | 환경변수 및 Docker 설정 | Phase 0에서 완료 | - |
| 04 | `04-code-brain-install.sh` | Ollama 설치 및 Code Brain 구축 | Phase 0에서 완료 | - |
| 05 | `05-code-models-download.sh` | 코딩 모델 다운로드 (32B, 7B) | No | 40분 |
| 06 | `06-vision-brain-build.sh` | Vision Brain Docker 이미지 빌드 | No | 20분 |
| 07 | `07-brain-switch-api.sh` | Brain 전환 API 구축 | No* | 10분 |
| 08 | `08-webui-install.sh` | Open WebUI 설치 | No | 5분 |
| 09 | `09-service-automation.sh` | 서비스 자동화 설정 | Phase 0에서 완료 | - |
| 10 | `10-final-validation.sh` | 최종 검증 및 테스트 | No | 10분 |

> *Phase 7의 Brain 전환(systemctl stop/start ollama)은 런타임에 sudo가 필요합니다. 이는 sudoers 설정으로 해결할 수 있습니다.

**총 예상 시간**: Phase 0 (15-20분) + Phase 5-10 (약 1시간 25분) = **약 1시간 45분**

### Phase 0이 커버하는 sudo 작업 요약

| 카테고리 | 작업 내용 | 기존 단계 |
|---------|---------|---------|
| 패키지 설치 | apt update/upgrade, 개발 도구 설치 | Phase 1 |
| SSH/방화벽 | SSH 활성화, UFW 포트 설정 (22, 11434, 8080, 5678) | Phase 1 |
| 디렉토리 생성 | /gx10 전체 구조 생성 및 소유권 설정 | Phase 2 |
| Docker 그룹 | 사용자를 docker 그룹에 추가 | Phase 3 |
| Ollama 설치 | curl 설치 + systemd 서비스 등록 | Phase 4 |
| 서비스 설정 | Ollama override.conf, 모니터링 서비스 등록 | Phase 4, 9 |

---

## 01. 초기 설정 (01-initial-setup.sh)

### 목표
- 시스템 업데이트
- 필수 패키지 설치
- SSH 및 방화벽 설정

### 주요 작업
```bash
# 1. 시스템 업데이트
sudo apt update && sudo apt upgrade -y

# 2. 필수 패키지 설치
sudo apt install -y build-essential cmake git curl wget htop btop tmux vim neovim tree jq unzip net-tools openssh-server python3-pip python3-venv

# 3. SSH 설정
sudo systemctl enable ssh
sudo systemctl start ssh

# 4. 방화벽 설정
sudo ufw allow ssh
sudo ufw allow 11434/tcp  # Ollama
sudo ufw allow 8080/tcp   # Open WebUI
sudo ufw allow 5678/tcp   # n8n
sudo ufw enable
```

### 검증
- SSH 서비스 상태: `systemctl status ssh`
- UFW 상태: `sudo ufw status`

---

## 02. 디렉토리 구조 (02-directory-structure.sh)

### 목표
- GX10 표준 디렉토리 구조 생성
- 소유권 및 권한 설정

### 디렉토리 구조
```
/gx10/
├─ brains/
│ ├─ code/
│ │ ├─ models/
│ │ ├─ prompts/
│ │ ├─ execution/
│ │ └─ logs/
│ └─ vision/
│   ├─ models/
│   ├─ cuda/
│   ├─ benchmarks/
│   └─ logs/
├─ runtime/
│ ├─ locks/
│ └─ logs/
├─ api/
├─ automation/
│ ├─ n8n/
│ └─ mcp/
└─ system/
  ├─ monitoring/
  ├─ update/
  └─ backup/
```

### 주요 작업
```bash
sudo mkdir -p /gx10/{brains,runtime,api,automation,system}
sudo mkdir -p /gx10/brains/code/{models,prompts,execution,logs}
sudo mkdir -p /gx10/brains/vision/{models,cuda,benchmarks,logs}
sudo mkdir -p /gx10/runtime/{locks,logs}
sudo mkdir -p /gx10/api
sudo mkdir -p /gx10/automation/{n8n,mcp}
sudo mkdir -p /gx10/system/{monitoring,update,backup}
sudo chown -R $USER:$USER /gx10
```

### 검증
- 디렉토리 구조: `tree /gx10`
- 소유권: `ls -la /gx10`

---

## 03. 환경 설정 (03-environment-config.sh)

### 목표
- 환경변수 설정
- Docker 설정
- 사용자 그룹 추가

### 주요 작업
```bash
# 1. 환경변수 추가
cat >> ~/.bashrc << 'EOF'

# === GX10 AI System Configuration ===
export GX10_HOME="/gx10"
export OLLAMA_MODELS="/gx10/brains/code/models"
export HF_HOME="/gx10/brains/vision/models/huggingface"
export TORCH_HOME="/gx10/brains/vision/models/torch"
export PATH="/usr/local/cuda/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
alias gx="cd /gx10"
alias brain-status="/gx10/api/status.sh"
alias brain-switch="/gx10/api/switch.sh"
EOF
source ~/.bashrc

# 2. Docker 그룹 추가
sudo usermod -aG docker $USER
newgrp docker

# 3. GPU 접근 테스트
docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu22.04 nvidia-smi
```

### 검증
- 환경변수: `echo $GX10_HOME`
- Docker GPU: `docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu22.04 nvidia-smi`

---

## 04. Code Brain 설치 (04-code-brain-install.sh)

### 목표
- Ollama 설치
- systemd 서비스 설정

### 주요 작업
```bash
# 1. Ollama 설치
curl -fsSL https://ollama.com/install.sh | sh

# 2. systemd 오버라이드
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf << EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_MODELS=/gx10/brains/code/models"
Environment="OLLAMA_KEEP_ALIVE=24h"
Environment="OLLAMA_NUM_PARALLEL=2"
Environment="OLLAMA_MAX_LOADED_MODELS=2"
EOF

# 3. 서비스 재시작
sudo systemctl daemon-reload
sudo systemctl restart ollama
sudo systemctl enable ollama
```

### 검증
- Ollama 버전: `ollama --version`
- API 상태: `curl http://localhost:11434/api/version`
- 서비스 상태: `sudo systemctl status ollama`

---

## 05. 모델 다운로드 (05-code-models-download.sh)

### 목표
- 코딩 모델 다운로드
- 모델 테스트

### 주요 작업
```bash
# 1. 메인 코딩 모델 (32B) - 30분, 20GB
ollama pull qwen2.5-coder:32b

# 2. 빠른 응답용 (7B) - 10분, 5GB
ollama pull qwen2.5-coder:7b

# 3. DeepSeek 대안 (16B) - 15분, 10GB
ollama pull deepseek-coder-v2:16b

# 4. 임베딩 모델
ollama pull nomic-embed-text

# 5. 모델 테스트
ollama list
time ollama run qwen2.5-coder:32b "Write a Python function to calculate fibonacci" --verbose
```

### 검증
- 모델 리스트: `ollama list`
- 32B 모델 테스트: TTFT 20-40초, 토큰/초 8-12

---

## 06. Vision Brain 빌드 (06-vision-brain-build.sh)

### 목표
- Vision Brain Docker 이미지 빌드
- CUDA/PyTorch 환경 구성

### 주요 작업
```bash
# 1. Dockerfile 생성
cat > /gx10/brains/vision/Dockerfile << 'EOF'
FROM nvcr.io/nvidia/pytorch:24.01-py3

WORKDIR /workspace

# PyTorch 및 의존성 업데이트
pip install --upgrade pip
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Computer Vision 라이브러리
pip install opencv-python pillow transformers accelerate

# Hugging Face Hub
pip install huggingface_hub

# 벤치마크 도구
pip install tqdm psutil GPUtil

# 작업 디렉토리
ENV PYTHONPATH=/workspace:$PYTHONPATH

CMD ["python"]
EOF

# 2. 이미지 빌드
docker build -t gx10-vision-brain:latest /gx10/brains/vision/
```

### 검증
- 이미지 확인: `docker images | grep gx10-vision-brain`
- 컨테이너 테스트: `docker run --rm --gpus all gx10-vision-brain:latest python -c "import torch; print(torch.cuda.is_available())"`

---

## 07. Brain 전환 API (07-brain-switch-api.sh)

### 목표
- Brain 상태 관리 API 구축
- 전환 스크립트 작성

### 주요 작업
```bash
# 1. active_brain.json 생성
cat > /gx10/runtime/active_brain.json << EOF
{
  "brain": "code",
  "pid": null,
  "since": null,
  "last_switch": null
}
EOF

# 2. status.sh 작성
cat > /gx10/api/status.sh << 'EOF'
#!/bin/bash
cat /gx10/runtime/active_brain.json | jq '.'
EOF
chmod +x /gx10/api/status.sh

# 3. switch.sh 작성
cat > /gx10/api/switch.sh << 'EOF'
#!/bin/bash
TARGET_BRAIN=$1
CURRENT=$(cat /gx10/runtime/active_brain.json | jq -r '.brain')

if [ "$TARGET_BRAIN" == "$CURRENT" ]; then
  echo "Already on $TARGET_BRAIN brain"
  exit 0
fi

case $TARGET_BRAIN in
  code)
    # Stop Vision Brain
    docker stop gx10-vision-brain 2>/dev/null
    # Start Code Brain
    sudo systemctl start ollama
    ;;
  vision)
    # Stop Code Brain
    sudo systemctl stop ollama
    # Start Vision Brain
    docker run -d --name gx10-vision-brain --gpus all gx10-vision-brain:latest
    ;;
  *)
    echo "Usage: switch.sh [code|vision]"
    exit 1
    ;;
esac

# Update state
echo "{\"brain\":\"$TARGET_BRAIN\",\"pid\":$(pgrep -f "$TARGET_BRAIN" | head -1),\"since\":\"$(date -Iseconds)\",\"last_switch\":\"$(date -Iseconds)\"}" > /gx10/runtime/active_brain.json
EOF
chmod +x /gx10/api/switch.sh
```

### 검증
- 상태 확인: `/gx10/api/status.sh`
- 전환 테스트: `sudo /gx10/api/switch.sh vision`

---

## 08. Open WebUI 설치 (08-webui-install.sh)

### 목표
- Open WebUI 컨테이너 실행
- 웹 인터페이스 접속 테스트

### 주요 작업
```bash
docker run -d \
  --name open-webui \
  --restart unless-stopped \
  -p 8080:8080 \
  -v /gx10/brains/code/webui:/app/backend/data \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-webui/open-webui:main
```

### 검증
- 컨테이너 상태: `docker ps | grep open-webui`
- 웹 접속: `http://<gx10-ip>:8080`

---

## 09. 서비스 자동화 (09-service-automation.sh)

### 목표
- systemd 서비스 등록
- 자동 시작 설정

### 주요 작업
```bash
# n8n 설치 (선택)
docker run -d \
  --name n8n \
  --restart unless-stopped \
  -p 5678:5678 \
  -v /gx10/automation/n8n:/home/node/.n8n \
  n8nio/n8n
```

### 검증
- n8n 상태: `docker ps | grep n8n`
- 웹 접속: `http://<gx10-ip>:5678`

---

## 10. 최종 검증 (10-final-validation.sh)

### 목표
- 전체 시스템 검증
- 성능 벤치마크

### 주요 작업
```bash
# 1. 시스템 상태 체크
echo "=== System Status ==="
nvidia-smi
free -h
df -h

# 2. Code Brain 테스트
echo "=== Code Brain Test ==="
/gx10/api/status.sh
ollama list
time ollama run qwen2.5-coder:32b "def hello(): print('GX10 AI System')" --verbose

# 3. Vision Brain 테스트
echo "=== Vision Brain Test ==="
sudo /gx10/api/switch.sh vision
docker run --rm --gpus all gx10-vision-brain:latest python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}, GPU: {torch.cuda.get_device_name(0)}')"
sudo /gx10/api/switch.sh code

# 4. 웹 인터페이스 확인
echo "=== Web Interfaces ==="
echo "Open WebUI: http://$(hostname -I | awk '{print $1}'):8080"
echo "n8n: http://$(hostname -I | awk '{print $1}'):5678"

# 5. 디렉토리 구조 확인
echo "=== Directory Structure ==="
tree /gx10 -L 2
```

---

## 스크립트 실행 순서

### 권장: Phase 0 먼저 실행 후 나머지 자동 진행

```bash
# Step 1: sudo 사전 실행 (한 번만 sudo 필요)
cd scripts/install
sudo ./00-sudo-prereqs.sh

# Step 2: 재로그인 (docker 그룹 반영)
# 또는: newgrp docker

# Step 3: 나머지 단계 실행 (sudo 불필요)
./05-code-models-download.sh    # AI 모델 다운로드 (~40분)
./06-vision-brain-build.sh      # Vision Brain Docker 빌드 (~20분)
./07-brain-switch-api.sh        # Brain 전환 API 배포
./08-webui-install.sh           # Open WebUI 설치
./10-final-validation.sh        # 최종 검증
```

### 대안: 기존 일괄 실행 (모든 단계에서 sudo 필요)

```bash
# 모든 스크립트 순차 실행 (sudo 환경에서)
sudo ./00-install-all.sh
```

### Claude Code 등 자동화 도구에서 실행할 때

```bash
# Phase 0을 터미널에서 수동 실행한 후,
# Claude Code에서 나머지를 자동으로 진행 가능:
ollama pull qwen2.5-coder:32b
ollama pull qwen2.5-coder:7b
docker build -t gx10-vision-brain:latest /gx10/brains/vision/
# ... (이후 단계 모두 sudo 불필요)
```

---

## 오류 처리 및 재시도

각 스크립트는 다음 규칙을 따릅니다:

1. **롤백 지원**: 실패 시 변경 사항 롤백
2. **로그 기록**: 모든 작업은 `/gx10/runtime/logs/`에 로그 저장
3. **검증 단계**: 각 단계 완료 후 자동 검증
4. **재시도 가능**: 개별 스크립트는 독립적으로 재실행 가능

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
| 2026-02-01 | 1.0 | 자동 구축 스크립트 계획서 작성 | drake |
| 2026-02-03 | 1.1 | Phase 0 (sudo 사전 실행) 추가, sudo/non-sudo 분리 | holee |
