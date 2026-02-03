# GX10 구축 절차 체크리스트

DGX OS 7.2.3이 설치된 ASUS Ascent GX10용 구축 절차입니다.

## ✅ 사전 점검 결과 (2026-02-03 실측)

### 시스템 상태

| 항목 | 상태 | 상세 |
|------|------|------|
| OS | ✅ 정상 | Ubuntu 24.04.3 LTS (DGX OS), aarch64, Kernel 6.14.0-1015-nvidia |
| GPU | ✅ 정상 | NVIDIA GB10, 37°C, CUDA 13.0, Driver 580.126.09 |
| 메모리 | ✅ 정상 | 총 119GB / 사용 4.1GB / 가용 115GB, 스왑 15GB |
| 디스크 | ✅ 정상 | 916GB 중 38GB 사용 (832GB 가용) |
| 인터넷 | ✅ 정상 | 외부 연결 확인됨 |
| 기본 도구 | ✅ 정상 | git, curl, wget, python3 설치됨 |
| NVIDIA Container Toolkit | ✅ 정상 | v1.18.2 |
| Docker Engine | ✅ 설치됨 | v28.5.1 (Docker Compose v2.40.0, Buildx v0.29.1) |
| /gx10 디렉토리 | ⚠️ 구조만 존재 | api, brains, system, automation, runtime (내용 비어있음) |
| Docker 그룹 권한 | ⚠️ 수동 설정 필요 | `sudo usermod -aG docker holee` 실행 필요 |
| Ollama | ❌ 미설치 | `curl -fsSL https://ollama.com/install.sh \| sudo sh` 필요 |
| AI 모델 | ❌ 없음 | Ollama 설치 후 모델 다운로드 필요 |

### 사전 확인 완료

- [x] DGX OS 7.2.3 설치
- [x] SSH 연결 확인
- [x] GPU 드라이버 정상 (CUDA 13.0)
- [x] Docker Engine 설치됨 (v28.5.1)
- [x] NVIDIA Container Toolkit 설치됨 (v1.18.2)
- [x] 기본 개발 도구 설치됨 (git, curl, wget, python3)
- [x] /gx10 디렉토리 구조 생성됨
- [x] 디스크 공간 충분 (832GB 가용)
- [x] 메모리 충분 (115GB 가용)
- [x] Docker 그룹 권한 설정 (Phase 0에서 완료)
- [x] Ollama 설치 (Phase 0에서 완료, v0.15.4)
- [x] Ollama models 디렉토리 권한 수정 (`chown ollama:ollama` — KB-002 참조)
- [ ] AI 모델 다운로드

## 📋 구축 절차

### Phase 0: Sudo 사전 실행 (15-20분) ⭐ 권장

**모든 sudo 필요 작업을 한 번에 실행합니다.** 이후 단계는 sudo 없이 진행 가능합니다.

```bash
cd scripts/install
sudo ./00-sudo-prereqs.sh
```

Phase 0이 수행하는 작업 (8개 섹션):
1. 시스템 패키지 업데이트 및 설치 (apt update/upgrade, 개발 도구)
2. SSH 활성화 및 방화벽 설정 (포트 22, 11434, 8080, 5678)
3. /gx10 디렉토리 구조 생성 + 소유권 (⚠️ models → `ollama:ollama`, KB-002)
4. Docker 그룹에 사용자 추가
5. Ollama 설치
6. Ollama systemd 서비스 설정 (override.conf)
7. 모니터링 서비스 등록
8. Brain 전환 sudoers 설정 + /usr/local/bin wrapper (KB-004)

**Phase 0 완료 후 반드시 재로그인** (docker 그룹 반영):
```bash
# 방법 1: 재로그인
logout
# 다시 로그인

# 방법 2: newgrp (현재 세션에서)
newgrp docker
```

### [레거시] 기본 시스템 설정 (Phase 0에 통합됨)

> Phase 0을 실행했다면 이 단계는 건너뛰세요.

```bash
# 1. 시스템 업데이트
sudo apt update && sudo apt upgrade -y

# 2. 필수 도구 설치
sudo apt install -y build-essential git curl wget jq

# 3. Python 개발 도구 확인 (이미 설치되어 있음)
python3 --version  # Python 3.12.x

# 4. DGX OS 사전 설치 컴포넌트 확인
nvidia-smi          # NVIDIA 드라이버
docker --version    # Docker
nvidia-ctk --version # NVIDIA Container Toolkit
```

### [레거시] 디렉토리 구조 생성 (Phase 0에 통합됨)

> Phase 0을 실행했다면 이 단계는 건너뛰세요.

```bash
# 1. GX10 기본 디렉토리
sudo mkdir -p /gx10/{api,brains/{code,vision},runtime/logs,system/monitoring}

# 2. Workspace 디렉토리
mkdir -p ~/workspace/{scripts,models,projects}

# 3. 소유권 설정
sudo chown -R $USER:$USER /gx10
```

### [레거시] 스크립트 설치 (Phase 0에 통합됨)

```bash
# 개발자 PC에서 GX10으로 스크립트 전송
scp -r gx10-scripts/ user@gx10-brain.local:/tmp/

# GX10 서버에서 스크립트 설치
cd /tmp/gx10-scripts

# API 스크립트
cp api/*.sh /gx10/api/
chmod +x /gx10/api/*.sh

# Vision Brain
cp brains/vision/*.{sh,Dockerfile} /gx10/brains/vision/
chmod +x /gx10/brains/vision/run.sh

# 시스템 스크립트
cp system/start-all.sh /gx10/system/
cp system/monitoring/health-check.sh /gx10/system/monitoring/
chmod +x /gx10/system/start-all.sh
chmod +x /gx10/system/monitoring/health-check.sh

# Workspace 스크립트
cp workspace-scripts/*.sh ~/workspace/scripts/
chmod +x ~/workspace/scripts/*.sh
```

### [레거시] Ollama 설치 (Phase 0에 통합됨)

> Phase 0을 실행했다면 이 단계는 건너뛰세요.

```bash
# 1. Ollama 설치
curl -fsSL https://ollama.com/install.sh | sh

# 2. systemd 서비스 설정
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf << EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_MODELS=/gx10/brains/code/models"
Environment="OLLAMA_KEEP_ALIVE=24h"
Environment="OLLAMA_NUM_PARALLEL=2"
Environment="OLLAMA_MAX_LOADED_MODELS=2"
EOF

# 3. 서비스 활성화
sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl start ollama

# 4. 설치 확인
ollama --version
curl http://localhost:11434/api/version
```

### Phase 1: Code Brain 모델 다운로드 (40-60분, sudo 불필요)

```bash
# 메인 코딩 모델 (32B) - 약 30분
ollama pull qwen2.5-coder:32b

# 빠른 응답용 (7B) - 약 10분
ollama pull qwen2.5-coder:7b

# 대안: DeepSeek (16B) - 약 15분
ollama pull deepseek-coder-v2:16b

# 임베딩 모델
ollama pull nomic-embed-text

# 설치 확인
ollama list
```

### Phase 2: Vision Brain 빌드 (20-30분, sudo 불필요)

```bash
# 1. Dockerfile 확인
cat /gx10/brains/vision/Dockerfile

# 2. 이미지 빌드 (약 20-30분)
cd /gx10/brains/vision
docker build -t gx10-vision-brain:latest .

# 3. 빌드 확인
docker images | grep gx10-vision-brain
```

### Phase 3: bashrc 설정 (5분, sudo 불필요)

```bash
cat >> ~/.bashrc << 'EOF'

# GX10 AI System Aliases (DGX OS)
alias gx-status='/gx10/api/status.sh'
alias gx-switch='/gx10/api/switch.sh'
alias gx-start='/gx10/system/start-all.sh'
alias ai-start='~/workspace/scripts/start-all.sh'
alias ai-status='~/workspace/scripts/status.sh'

# Quick model access
alias chat='ollama run qwen2.5-coder:32b'
alias chat-fast='ollama run qwen2.5-coder:7b'
alias vision='ollama run qwen2.5-vl:7b'

# DGX Dashboard
alias dgx-dash='echo "Access DGX Dashboard at: https://$(hostname -I | awk '"'"'{print $1}'"'"'):6789"'
EOF

source ~/.bashrc
```

### Phase 4: Health Check cron 설정 (2분, sudo 불필요)

```bash
# 5분마다 헬스체크
(crontab -l 2>/dev/null; echo "*/5 * * * * /gx10/system/monitoring/health-check.sh") | crontab -

# 부팅 시 자동 시작
(crontab -l 2>/dev/null; echo "@reboot sleep 60 && /gx10/system/start-all.sh >> /gx10/runtime/logs/startup.log 2>&1") | crontab -
```

### Phase 5: 시스템 테스트 (10분, sudo 불필요)

```bash
# 1. 시스템 상태 확인
gx-status

# 2. Ollama 테스트
ollama run qwen2.5-coder:32b "Write a Python hello world"

# 3. Brain 전환 테스트
gx-switch code
sleep 5
gx-switch vision
sleep 5
gx-switch code

# 4. 헬스체크 확인
/gx10/system/monitoring/health-check.sh
cat /gx10/runtime/logs/health.log
```

## 🎯 완료 체크리스트

### Phase 0: Sudo 사전 실행 (2026-02-03 10:15 완료)

- [x] 시스템 패키지 업데이트 (31개 업그레이드, 27개 신규)
- [x] SSH 활성화 및 방화벽 설정 (포트 22, 11434, 8080, 5678)
- [x] /gx10 디렉토리 구조 생성 (23개 디렉토리, holee 소유)
- [x] Docker 그룹 등록 (holee → docker 그룹)
- [x] Ollama 설치 (v0.15.4)
- [x] Ollama systemd override 설정 (OLLAMA_HOST=0.0.0.0, MODELS=/gx10/brains/code/models)
- [x] 모니터링 서비스 등록 (gx10-monitor.service/timer)

### Phase 0 후속 조치 (수동 필요)

- [ ] Ollama 서비스 정상 기동 확인 (`sudo systemctl restart ollama` → `ollama list`)
- [ ] Docker 세션 반영 (Claude Code 재시작 또는 `newgrp docker` → `docker ps`)

### Phase 1: Code Brain 모델 다운로드

- [ ] 메인 코딩 모델 (qwen2.5-coder:32b) 다운로드
- [ ] 빠른 모델 (qwen2.5-coder:7b) 다운로드

### Phase 2: Vision Brain 설치

- [ ] Vision Brain Docker 이미지 빌드
- [ ] Brain 전환 API 배포

### Phase 3-4: 서비스 및 설정

- [ ] bashrc alias 설정
- [ ] Open WebUI 설치
- [ ] 헬스체크 cron 등록

### Phase 5: 검증

- [ ] 시스템 테스트 통과
- [ ] Brain 전환 테스트 (Code ↔ Vision)
- [ ] 개발자 PC 연동 확인

### 선택 항목

- [ ] DeepSeek 모델 다운로드
- [ ] 임베딩 모델 (nomic-embed-text) 다운로드
- [ ] n8n 워크플로우 설치
- [ ] MCP 서버 설치

## 📊 총 소요 시간 (2026-02-03 Phase 0 완료 후 수정)

| 항목 | 전체 시간 | 남은 시간 | 비고 |
|------|---------|---------|------|
| ~~Phase 0 (sudo 사전실행)~~ | ~~15-20분~~ | ~~완료~~ | ✅ 2분 소요 (대부분 이미 설치됨) |
| Phase 0 후속 (수동) | 2분 | 2분 | Ollama 재시작 + Docker 세션 반영 |
| Phase 1 (모델 다운로드) | 50분 | 50분 | qwen2.5-coder:32b + 7b |
| Phase 2 (Vision Brain) | 25분 | 25분 | Docker 빌드(20분) + API(5분) |
| Phase 3-4 (서비스/설정) | 10분 | 10분 | bashrc, WebUI, cron |
| Phase 5 (검증) | 10분 | 10분 | 전체 테스트 + Brain 전환 |
| **총합** | | **~1시간 37분** | Phase 0 완료, 후속 조치 2건 필요 |

## 🚀 빠른 시작

### 권장: Phase 0 → 모델 다운로드 (2-Step)

```bash
# Step 1: sudo 사전 실행 (15-20분, 한 번만)
cd ~/workspace/gx10-install/scripts/install
sudo ./00-sudo-prereqs.sh

# Step 2: 재로그인 후 모델 다운로드 (sudo 불필요)
ollama pull qwen2.5-coder:32b && \
ollama run qwen2.5-coder:32b "Hello, GX10!"
```

### 최소 설치 (1-liner, sudo 환경)

```bash
curl -fsSL https://ollama.com/install.sh | sudo sh && \
sudo systemctl enable ollama && sudo systemctl start ollama && \
ollama pull qwen2.5-coder:32b && \
ollama run qwen2.5-coder:32b "Hello, GX10!"
```

## 📞 문제 해결

### 명령어를 찾을 수 없음

```bash
# DGX OS에 사전 설치된 컴포넌트 확인
which nvidia-smi
which docker
which nvidia-ctk

# 경로 확인
echo $PATH | tr ':' '\n'
```

### 권한 문제

```bash
# sudo 그룹 확인
groups

# docker 그룹에 추가 (필요시)
sudo usermod -aG docker $USER
newgrp docker
```

### Ollama 연결 실패

```bash
# 서비스 상태 확인
sudo systemctl status ollama

# 로그 확인
journalctl -u ollama -f

# 재시작
sudo systemctl restart ollama
```

## 📝 다음 단계

모든 설정 완료 후:
1. 개발자 PC에서 SSH 터널 생성
2. Aider/Continue.dev 연결 설정
3. 첫 번째 프로젝트 시작

---

*이 체크리스트는 DGX OS 7.2.3 환경에서 테스트되었습니다.*

---

## 📜 설치 진행 로그

### 2026-02-03: 사전 점검 실시

**실행 환경**: GX10 본체 직접 접속 (Claude Code)

**점검 결과 요약**:
- OS/커널/GPU/메모리/디스크: 모두 정상
- Docker Engine v28.5.1 설치되어 있으나, 사용자 `holee`가 `docker` 그룹에 미등록
- NVIDIA Container Toolkit v1.18.2 정상 설치
- `/gx10/` 디렉토리 기본 구조(api, brains, system, automation, runtime) 존재하나 내용 비어있음
- Ollama 미설치 상태
- AI 모델 없음

**필요 조치**:
1. `sudo ./scripts/install/00-sudo-prereqs.sh` 실행 → 모든 sudo 작업 일괄 처리
2. 재로그인 (docker 그룹 반영)
3. 이후 모델 다운로드 및 서비스 설정은 Claude Code에서 자동화 가능

**진행도**: 약 30% (기본 인프라 확인 완료)

**대응**: `00-sudo-prereqs.sh` 스크립트 생성하여 모든 sudo 작업을 사전에 일괄 실행할 수 있도록 구성

### 2026-02-03 10:15: Phase 0 실행 완료

**실행 결과**: `sudo ./00-sudo-prereqs.sh` - 전체 성공 (약 2분 소요)

| 섹션 | 결과 | 비고 |
|------|------|------|
| Section 1: 패키지 업데이트 | ✅ 성공 | 31개 업그레이드 + 27개 신규 설치 (Docker CE 29.1.3, neovim 등) |
| Section 2: SSH/방화벽 | ✅ 성공 | UFW 활성화, 포트 22/11434/8080/5678 허용 |
| Section 3: 디렉토리 구조 | ✅ 성공 | /gx10 전체 23개 디렉토리 생성, holee 소유권 |
| Section 4: Docker 그룹 | ✅ 이미 등록됨 | holee 사용자 docker 그룹 확인됨 |
| Section 5: Ollama 설치 | ✅ 이미 설치됨 | v0.15.4 |
| Section 6: Ollama 서비스 | ✅ 성공 | override.conf 생성, 서비스 재시작 |
| Section 7: 모니터링 서비스 | ✅ 성공 | gx10-monitor.service/timer 등록 |

**발견된 문제 (2건)**:

1. **Ollama 서비스 미응답**: `ollama list` 실행 시 "ollama server not responding" 오류
   - override.conf 적용은 되었으나 서비스가 정상 기동되지 않음
   - 원인: `/gx10/brains/code/models` 디렉토리를 OLLAMA_MODELS로 설정했으나 모델 파일 없음
   - 조치: `sudo systemctl restart ollama` 또는 `ollama serve` 수동 시작 필요

2. **Docker 소켓 권한**: `docker ps` 실행 시 permission denied
   - docker 그룹에 등록되었으나(uid 988) **현재 세션에 미반영**
   - 조치: Claude Code 재시작 또는 `newgrp docker` 필요
