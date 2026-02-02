# DGX OS 7.2.3 스크립트 설치 가이드

DGX OS 7.2.3 (Ubuntu 24.04 LTS 기반) 최적화 GX10 관리 스크립트 모음입니다.

## 📁 디렉토리 구조

```
gx10-scripts/
├── api/                          # Brain 관리 API
│   ├── status.sh                 # 시스템 상태 조회
│   └── switch.sh                 # Code/Vision Brain 전환
├── brains/
│   └── vision/                   # Vision Brain
│       ├── Dockerfile            # Docker 이미지 빌드 파일
│       └── run.sh                # 컨테이너 실행 스크립트
├── system/                       # 시스템 관리
│   ├── start-all.sh              # 전체 서비스 시작
│   └── monitoring/
│       └── health-check.sh       # 헬스체크 (cron용)
└── workspace-scripts/            # 개발자용 스크립트
    ├── start-all.sh              # AI 서비스 시작
    ├── status.sh                 # 시스템 상태 확인
    ├── activate-coding.sh        # 코딩 환경 활성화
    └── activate-vision.sh        # Vision 환경 활성화
```

## 🚀 DGX OS 특징

DGX OS는 표준 Ubuntu 24.04와 다릅니다:

| 항목 | DGX OS 7.2.3 | 표준 Ubuntu 24.04 |
|------|-------------|-------------------|
| 기반 | Ubuntu 24.04 LTS | Ubuntu 24.04 LTS |
| 커널 | 6.8.x-dgx (최적화) | 6.8.x (일반) |
| NVIDIA 드라이버 | ✅ 사전 설치됨 | 수동 설치 필요 |
| CUDA Toolkit | ✅ 사전 설치됨 (12.x) | 수동 설치 필요 |
| Docker | ✅ 사전 설치됨 | 수동 설치 필요 |
| NVIDIA Container Toolkit | ✅ 사전 설치됨 | 수동 설치 필요 |
| cuDNN | ✅ 사전 설치됨 | 수동 설치 필요 |
| 관리 도구 | DGX Dashboard | 수동 관리 |

## 📋 설치 전 확인 사항

```bash
# DGX OS 버전 확인
cat /etc/os-release

# NVIDIA 드라이버 확인
nvidia-smi

# CUDA 확인
nvcc --version

# Docker 확인
docker --version

# NVIDIA Container Toolkit 확인
nvidia-ctk --version
```

## 🚀 설치 방법

### 1. GX10 서버에 스크립트 복사

```bash
# 개발자 PC에서 GX10으로 복사
scp -r gx10-scripts/ user@gx10-brain.local:/tmp/

# 또는 Git을 사용하는 경우
git clone <your-repo> /tmp/gx10-scripts
```

### 2. 스크립트 설치

```bash
# GX10 서버에서 실행
cd /tmp/gx10-scripts

# 디렉토리 구조 생성
sudo mkdir -p /gx10/{api,brains/vision,runtime/logs,system/monitoring}

# 스크립트 복사 및 실행 권한 설정
sudo cp api/*.sh /gx10/api/
sudo cp brains/vision/run.sh /gx10/brains/vision/
sudo cp brains/vision/Dockerfile /gx10/brains/vision/
sudo cp system/start-all.sh /gx10/system/
sudo cp system/monitoring/health-check.sh /gx10/system/monitoring/

# 실행 권한 설정
sudo chmod +x /gx10/api/*.sh
sudo chmod +x /gx10/brains/vision/run.sh
sudo chmod +x /gx10/system/start-all.sh
sudo chmod +x /gx10/system/monitoring/health-check.sh

# 소유권 설정
sudo chown -R $USER:$USER /gx10

# Workspace 스크립트 복사
mkdir -p ~/workspace/scripts
cp workspace-scripts/*.sh ~/workspace/scripts/
chmod +x ~/workspace/scripts/*.sh
```

### 3. Vision Brain Docker 이미지 빌드

DGX OS에서는 Docker와 NVIDIA Container Toolkit이 사전 설치되어 있으므로 바로 빌드 가능:

```bash
# Dockerfile은 이미 /gx10/brains/vision/에 복사됨
cd /gx10/brains/vision

# DGX OS 최적화 빌드
docker build -t gx10-vision-brain:latest .

# 빌드 확인
docker images | grep gx10-vision-brain
```

### 4. bashrc에 alias 추가

```bash
cat >> ~/.bashrc << 'EOF'

# GX10 AI System Aliases (DGX OS)
alias gx-status='/gx10/api/status.sh'
alias gx-switch='/gx10/api/switch.sh'
alias gx-start='/gx10/system/start-all.sh'
alias ai-start='~/workspace/scripts/start-all.sh'
alias ai-status='~/workspace/scripts/status.sh'
alias ai-coding='source ~/workspace/scripts/activate-coding.sh'
alias ai-vision='source ~/workspace/scripts/activate-vision.sh'

# Quick model access
alias chat='ollama run qwen2.5-coder:32b'
alias chat-fast='ollama run qwen2.5-coder:7b'
alias vision='ollama run qwen2.5-vl:7b'

# DGX Dashboard quick access
alias dgx-dash='echo "Access DGX Dashboard at: https://$(hostname -I | awk \'{print $1}\"):6789"'
EOF

source ~/.bashrc
```

### 5. Ollama 설치 (DGX OS)

```bash
# DGX OS에도 Ollama 설치 필요
curl -fsSL https://ollama.com/install.sh | sh

# systemd 서비스 설정
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf << EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_MODELS=/gx10/brains/code/models"
Environment="OLLAMA_KEEP_ALIVE=24h"
Environment="OLLAMA_NUM_PARALLEL=2"
Environment="OLLAMA_MAX_LOADED_MODELS=2"
EOF

sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl start ollama

# 설치 확인
ollama --version
curl http://localhost:11434/api/version
```

### 6. Health Check cron 등록

```bash
# 5분마다 헬스체크 실행
(crontab -l 2>/dev/null; echo "*/5 * * * * /gx10/system/monitoring/health-check.sh") | crontab -

# 로그 확인
tail -f /gx10/runtime/logs/health.log
```

### 7. 부팅 시 자동 시작

```bash
# crontab에 등록
(crontab -l 2>/dev/null; echo "@reboot sleep 60 && /gx10/system/start-all.sh >> /gx10/runtime/logs/startup.log 2>&1") | crontab -
```

## 📋 사용 방법

### 시스템 상태 확인

```bash
# 전체 상태
gx-status
# 또는
/gx10/api/status.sh

# 간단 상태
ai-status
```

### Brain 전환

```bash
# Code Brain으로 전환
gx-switch code

# Vision Brain으로 전환
gx-switch vision

# 모두 정지
gx-switch none
```

### 서비스 시작

```bash
# 전체 시스템 시작
gx-start

# AI 서비스만 시작
ai-start
```

## 🔍 DGX OS 특정 주의사항

### ✅ 사전 설치된 컴포넌트 활용

DGX OS에는 다음이 이미 설치되어 있습니다:

```bash
# NVIDIA 드라이버 - 이미 설치됨, 수동 업데이트 금지
nvidia-smi

# CUDA Toolkit - 이미 설치됨
nvcc --version

# Docker - 이미 설치됨
docker --version

# NVIDIA Container Toolkit - 이미 설치됨
nvidia-ctk --version

# cuDNN, NCCL - 이미 설치됨
# 업데이트는 DGX Dashboard를 통해서만 진행
```

### ⚠️ DGX OS에서 하지 말아야 할 것

```bash
# ❌ 하지 말 것:
# 1. NVIDIA 드라이버 수동 업데이트
sudo apt install nvidia-driver-XXX  # 금지!

# 2. CUDA 수동 재설치
# DGX OS가 관리함

# 3. DGX 저장소 제거
# /etc/apt/sources.list.d/의 DGX 관련 저장소 보존

# 4. 커널 수동 업데이트
# DGX 전용 커널 사용
```

### ✅ DGX OS에서 해도 좋은 것

```bash
# ✅ 해도 좋은 것:
# 1. 사용자 레벨 패키지 설치
sudo apt install htop btop tmux

# 2. Python 가상환경
python3 -m venv ~/myenv

# 3. Docker 사용 (이미 설정됨)
docker run --gpus all ...

# 4. DGX Dashboard 사용
# https://<gx10-ip>:6789
```

## 🔧 DGX Dashboard 활용

DGX OS는 웹 기반 관리 대시보드를 제공합니다:

### 접속 방법

```bash
# DGX Dashboard URL 확인
dgx-dash
# 또는
echo "https://$(hostname -I | awk '{print $1}'):6789"
```

### 제공 기능

1. **시스템 모니터링**
   - GPU 사용량, 온도
   - 메모리 사용량
   - 네트워크 상태

2. **컨테이너 관리**
   - 실행 중인 컨테이너 확인
   - 로그 보기

3. **시스템 업데이트**
   - DGX OS 업데이트
   - 드라이버 업데이트

4. **사용자 관리**
   - 사용자 추가/삭제
   - 권한 관리

## 🐛 문제 해결

### Ollama 연결 실패

```bash
# DGX OS에서 Ollama 서비스 확인
sudo systemctl status ollama

# 재시작
sudo systemctl restart ollama

# 로그 확인
journalctl -u ollama -f
```

### Docker GPU 접근 문제

```bash
# DGX OS에서는 기본적으로 작동해야 함
# 문제 시 NVIDIA Container Toolkit 확인

nvidia-ctk --version

# Docker runtime 설정 확인
docker info | grep -i runtime

# 테스트
docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu24.04 nvidia-smi
```

### Buffer Cache 문제

```bash
# UMA 아키텍처에서 캐시 플러시 중요
# 수동으로 플러시
sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'

# Brain 전환 시 자동으로 플러시됨
/gx10/api/switch.sh code
```

### DGX Dashboard 접속 불가

```bash
# Dashboard 서비스 상태 확인
sudo systemctl status dgx-dashboard

# 재시작
sudo systemctl restart dgx-dashboard

# 포트 확인
sudo netstat -tlnp | grep 6789
```

## 📊 모니터링

### 시스템 로그

```bash
# 시스템 로그
journalctl -f

# Ollama 로그
journalctl -u ollama -f

# Docker 로그
docker logs -f <container-name>

# 헬스체크 로그
tail -f /gx10/runtime/logs/health.log
```

### DGX Dashboard 모니터링

```bash
# 실시간 모니터링은 DGX Dashboard 추천
# https://<gx10-ip>:6789

# 또는 명령행으로
gx-status
```

## 📝 버전 정보

- **버전**: 2.0 (DGX OS)
- **DGX OS**: 7.2.3
- **기반 OS**: Ubuntu 24.04 LTS (Noble Numbat)
- **Python**: 3.12.x
- **Kernel**: 6.8.x-dgx
- **CUDA**: 12.x (사전 설치)
- **최종 수정**: 2026-02-02

## 📞 지원

### DGX OS 지원

- **NVIDIA Enterprise Support**: DGX OS 포함
- **DGX Documentation**: https://docs.nvidia.com/dgx/
- **GX10 Documentation**: ASUS 제공 문서

### 로그 위치

```bash
# 시스템 로그
/gx10/runtime/logs/

# Ollama 로그
journalctl -u ollama

# Docker 로그
docker logs <container>

# DGX Dashboard 로그
sudo journalctl -u dgx-dashboard
```

---

*이 스크립트들은 DGX OS 7.2.3 환경에서 테스트되었습니다.*
*DGX OS는 NVIDIA의 커스텀 Ubuntu 배포판으로, 표준 Ubuntu와 다른 점이 있습니다.*
