# GX10 구축 절차 체크리스트

DGX OS 7.2.3이 설치된 ASUS Ascent GX10용 구축 절차입니다.

## ✅ 사전 확인 완료

- [x] DGX OS 7.2.3 설치
- [x] SSH 연결 확인

## 📋 구축 절차

### Phase 1: 기본 시스템 설정 (15분)

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

### Phase 2: 디렉토리 구조 생성 (5분)

```bash
# 1. GX10 기본 디렉토리
sudo mkdir -p /gx10/{api,brains/{code,vision},runtime/logs,system/monitoring}

# 2. Workspace 디렉토리
mkdir -p ~/workspace/{scripts,models,projects}

# 3. 소유권 설정
sudo chown -R $USER:$USER /gx10
```

### Phase 3: 스크립트 설치 (10분)

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

### Phase 4: Ollama 설치 (10분)

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

### Phase 5: Code Brain 모델 다운로드 (60분)

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

### Phase 6: Vision Brain 빌드 (30분)

```bash
# 1. Dockerfile 확인
cat /gx10/brains/vision/Dockerfile

# 2. 이미지 빌드 (약 20-30분)
cd /gx10/brains/vision
docker build -t gx10-vision-brain:latest .

# 3. 빌드 확인
docker images | grep gx10-vision-brain
```

### Phase 7: bashrc 설정 (5분)

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

### Phase 8: Health Check cron 설정 (2분)

```bash
# 5분마다 헬스체크
(crontab -l 2>/dev/null; echo "*/5 * * * * /gx10/system/monitoring/health-check.sh") | crontab -

# 부팅 시 자동 시작
(crontab -l 2>/dev/null; echo "@reboot sleep 60 && /gx10/system/start-all.sh >> /gx10/runtime/logs/startup.log 2>&1") | crontab -
```

### Phase 9: 시스템 테스트 (10분)

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

### 필수 항목

- [ ] 시스템 업데이트 완료
- [ ] 디렉토리 구조 생성 완료
- [ ] 스크립트 설치 완료
- [ ] Ollama 설치 및 서비스 등록 완료
- [ ] 메인 코딩 모델 (32B) 다운로드 완료
- [ ] bashrc alias 설정 완료
- [ ] 헬스체크 cron 등록 완료
- [ ] 시스템 테스트 통과

### 선택 항목

- [ ] 빠른 모델 (7B) 다운로드 완료
- [ ] DeepSeek 모델 다운로드 완료
- [ ] Vision Brain Docker 이미지 빌드 완료
- [ ] Open WebUI 설치 (추후)
- [ ] n8n 설치 (추후)

## 📊 총 소요 시간

| 항목 | 시간 |
|------|------|
| Phase 1-3 (기본 설정) | 30분 |
| Phase 4 (Ollama) | 10분 |
| Phase 5 (모델 다운로드) | 60분 |
| Phase 6 (Vision Brain) | 30분 |
| Phase 7-9 (설정) | 20분 |
| **총합** | **약 2.5시간** |

## 🚀 빠른 시작 (최소)

```bash
# 1줄 설치
curl -fsSL https://ollama.com/install.sh | sh && \
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
