# GX10 로컬 AI 개발 환경 자동 구축

ASUS Ascent GX10을 활용한 로컬 AI 개발 환경 **완전 자동 구축** 프로젝트입니다.

> **프로젝트 상태**: ✅ **1차 구축 완료** (2026-02-03)
> **목표**: 2차 이후 GX10에서 **Full Auto** 구축 가능

---

## 🚀 2차 GX10 Full Auto 구축 가이드

### 개요

| 단계 | 작업 | 시간 | sudo 필요 |
|------|------|------|-----------|
| **준비** | git clone, 재로그인 | 5분 | ❌ |
| **Phase 0** | sudo 사전 실행 | 2분 | ✅ (1회) |
| **Phase 1-6** | 자동 설치 | ~28분 | ❌ |
| **합계** | - | **~35분** | - |

### Step 0: 사전 요구사항

| 항목 | 요구사항 |
|------|----------|
| 하드웨어 | ASUS Ascent GX10 (128GB RAM, GB10 GPU) |
| OS | DGX OS 7.2.3 (Ubuntu 24.04 기반) |
| 네트워크 | 인터넷 연결 (모델 다운로드용) |
| 계정 | sudo 권한 있는 사용자 |

### Step 1: 준비 단계

```bash
# 1. 저장소 클론
git clone https://github.com/holee9/gx10-install.git
cd gx10-install/scripts/install

# 2. Phase 0 실행 (sudo 필요 - 1회만)
sudo ./00-sudo-prereqs.sh

# 3. 재로그인 (docker 그룹 반영 필수!)
logout
# 다시 SSH 로그인
```

**Phase 0이 수행하는 작업:**
- 시스템 패키지 업데이트 (apt)
- SSH, UFW 방화벽 설정
- `/gx10` 디렉토리 생성 및 소유권 이전
- Docker 그룹에 사용자 추가
- Ollama 설치 및 systemd 서비스 설정
- sudoers 설정 (이후 Phase에서 sudo 불필요)
- 스크립트 wrapper 생성

### Step 2: 자동 설치 (Full Auto)

```bash
# 재로그인 후 실행
cd ~/gx10-install/scripts/install

# 전체 자동 설치 (권장)
./00-install-all.sh

# 또는 개별 Phase 실행
./01-code-models-download.sh   # ~11분 (AI 모델 다운로드)
./02-vision-brain-build.sh     # ~5분  (Vision Brain Docker)
./03-brain-switch-api.sh       # ~1분  (Brain 전환 API)
./04-webui-install.sh          # ~3분  (Open WebUI)
./05-final-validation.sh       # ~2분  (최종 검증)
./06-dashboard-install.sh      # ~3분  (시스템 모니터링 대시보드)
```

### Step 3: 설치 완료 확인

```bash
# Brain 상태 확인
/gx10/api/status.sh

# Brain 전환 테스트
sudo /gx10/api/switch.sh code
sudo /gx10/api/switch.sh vision
sudo /gx10/api/switch.sh code

# WebUI 접속
# http://<GX10-IP>:8080
```

### 설치 결과

| 서비스 | URL/명령어 | 설명 |
|--------|-----------|------|
| **Dashboard** | `http://<IP>:9000` | 시스템 모니터링 대시보드 |
| Open WebUI | `http://<IP>:8080` | AI 채팅 인터페이스 |
| Brain Status | `/gx10/api/status.sh` | 현재 Brain 상태 확인 |
| Brain Switch | `sudo /gx10/api/switch.sh [code\|vision]` | Brain 전환 (5-17초) |
| Ollama API | `http://localhost:11434` | Code Brain API |

> 외부 접근: Tailscale VPN으로 외부에서 GX10에 접근할 수 있습니다. [외부 접근 가이드](docs/external-access.md)

---

## Dashboard

GX10 시스템을 실시간으로 모니터링하는 웹 대시보드입니다.

### 주요 기능 (v2.0)

| 기능 | 설명 |
|------|------|
| **실시간 모니터링** | CPU, Memory, GPU, Disk, Network 상태를 2초 간격으로 업데이트 |
| **Alert 시스템** | CPU/GPU/Memory/Disk 임계값 설정 및 브라우저 알림 |
| **프로세스 모니터링** | GPU 프로세스, CPU/Memory 상위 프로세스 목록 |
| **히스토리 차트** | IndexedDB 기반 24시간 데이터 보존 (1분/5분/1시간/24시간 뷰) |
| **데이터 내보내기** | JSON/CSV 형식으로 메트릭 데이터 내보내기 |
| **Prometheus 메트릭** | `/metrics` 엔드포인트로 외부 모니터링 시스템 연동 |
| **테마 지원** | Dark/Light 모드 토글 |
| **키보드 단축키** | 탭 전환(1-4), 새로고침(R), 설정(S), 테마(T) |

### 탭 구성

| 탭 | 내용 |
|----|------|
| **Overview** | 시스템 전체 요약, Brain 상태, Ollama 모델 |
| **Performance** | CPU 코어별 사용률, 상세 메모리 정보, 프로세스 목록 |
| **Storage** | 디스크 사용량, 메모리 상세 분석, 히스토리 차트 |
| **Network** | 네트워크 인터페이스 통계, 실시간 메트릭 |

### 접속 방법

```bash
# 로컬 접속
http://localhost:9000

# 네트워크 접속
http://<GX10-IP>:9000

# Tailscale 접속
http://<Tailscale-IP>:9000
```

### 설정

Settings 페이지에서 다음을 구성할 수 있습니다:
- Alert 임계값 (CPU, GPU 온도, Memory, Disk)
- 브라우저 알림 활성화
- 테마 설정

### API 엔드포인트

```bash
# 시스템 상태
curl http://localhost:9000/api/status

# 실시간 메트릭
curl http://localhost:9000/api/metrics

# 프로세스 목록
curl http://localhost:9000/api/processes

# Prometheus 메트릭
curl http://localhost:9000/metrics

# Health 체크
curl http://localhost:9000/api/health
```

상세 문서: [gx10-dashboard/README.md](../gx10-dashboard/README.md)

---

## 📋 1차 구축 완료 기록 (2026-02-03)

### 구축 결과 요약

| 항목 | 결과 |
|------|------|
| **총 소요 시간** | ~4시간 (문제 해결 포함) |
| **Phase 완료** | 0~5 전체 완료 |
| **발견된 이슈** | 14개 (KB-001 ~ KB-014) |
| **이슈 해결** | 14개 모두 해결, 스크립트 반영 |

### Phase별 실행 결과

| Phase | 작업 | 소요 시간 | 결과 |
|-------|------|----------|------|
| Phase 0 | sudo 사전 실행 | 2분 | ✅ 8개 섹션 완료 |
| Phase 1 | AI 모델 다운로드 | 10분 35초 | ✅ 4개 모델 (32GB) |
| Phase 2 | Vision Brain Docker | 4분 20초 | ✅ NGC 25.12, CUDA 13.1 |
| Phase 3 | Brain Switch API | 3분 | ✅ 5-17초 전환 달성 |
| Phase 4 | WebUI 설치 | 3분 | ✅ HTTP 8080 |
| Phase 5 | 최종 검증 | 44초 | ✅ 22개 자동화 테스트 통과 |
| Phase 6 | Dashboard 설치 | 3분 | ✅ HTTP 9000 |

### 다운로드된 AI 모델

| 모델 | 크기 | 용도 |
|------|------|------|
| qwen2.5-coder:32b | 19GB | 메인 코딩 |
| qwen2.5-coder:7b | 4.7GB | 빠른 응답 |
| deepseek-coder-v2:16b | 8.9GB | 수학/논리 |
| nomic-embed-text | 274MB | 임베딩 |

### 발견 및 해결된 이슈 (Knowledge Base)

| KB | 이슈 | 해결 | 스크립트 반영 |
|----|------|------|--------------|
| KB-001 | KV cache inconsistent | 메모리 최적화 | ✅ |
| KB-002 | Ollama models 권한 | chown ollama:ollama | ✅ Phase 0 |
| KB-003 | Docker 소켓 권한 | 재로그인 필요 | ✅ 안내 추가 |
| KB-004 | sudo 잔존 호출 | sudoers 설정 | ✅ Phase 0 |
| KB-005 | 스크립트 실행 권한 | chmod +x | ✅ Git mode |
| KB-006 | security.sh regex | 패턴 수정 | ✅ |
| KB-007 | error-handler 파싱 | 문자열 처리 수정 | ✅ |
| KB-008 | lib/ set -u 오류 | 파라미터 기본값 | ✅ |
| KB-009 | GB10 CUDA 호환성 | NGC 25.12 업그레이드 | ✅ Dockerfile |
| KB-010 | 중첩 heredoc 충돌 | 구분자 변경 | ✅ |
| KB-011 | WebUI HTTPS 미지원 | HTTP 모드 | ✅ |
| KB-012 | switch.sh jq/PID/컨테이너 | 다중 수정 | ✅ |
| KB-013 | 재설치 시 Docker 컨테이너 충돌 | docker rm -f 추가 | ✅ |
| KB-014 | 검증 스크립트 자동화 부족 | 22개 자동화 테스트 | ✅ |

> 상세 내용: `memory/errors/KB-*.md`

### 1차 구축 작업 로그

<details>
<summary>전체 작업 로그 (클릭하여 펼치기)</summary>

| 일시 | 작업 | 결과 |
|------|------|------|
| 02-03 15:10 | PR 머지, main 브랜치 완료 | ✅ |
| 02-03 15:07 | Brain 전환 테스트 (code↔vision) 성공 | ✅ |
| 02-03 15:03 | KB-012 PID/컨테이너 오류 수정 | ✅ |
| 02-03 14:35 | KB-012 jq 오류 수정 | ✅ |
| 02-03 14:30 | KB-011 HTTP 모드 수정 | ✅ |
| 02-03 14:10 | Phase 3-5 완료 | ✅ |
| 02-03 13:50 | KB-010 heredoc 수정 | ✅ |
| 02-03 13:45 | Phase 2 재빌드 (NGC 25.12) | ✅ |
| 02-03 13:35 | KB-009 GB10 CUDA 호환성 발견 | ⚠️ |
| 02-03 12:55 | Phase 1 완료 | ✅ |
| 02-03 13:00 | KB-006~008 lib/ 오류 수정 | ✅ |
| 02-03 12:30 | KB-005 실행 권한 수정 | ✅ |
| 02-03 11:30 | KB-004 sudo 잔존 수정 | ✅ |
| 02-03 10:50 | KB-002,003 Ollama/Docker 권한 | ✅ |
| 02-03 10:15 | Phase 0 실행 | ✅ |
| 02-03 09:50 | GX10 사전 점검 | ✅ |

</details>

---

## 📚 프로젝트 구조

```
gx10-install/
├── README.md                    # 이 문서
├── scripts/
│   └── install/
│       ├── 00-sudo-prereqs.sh   # Phase 0: sudo 사전 실행
│       ├── 00-install-all.sh    # 전체 자동 설치
│       ├── 01-code-models-download.sh  # Phase 1
│       ├── 02-vision-brain-build.sh    # Phase 2
│       ├── 03-brain-switch-api.sh      # Phase 3
│       ├── 04-webui-install.sh         # Phase 4
│       ├── 05-final-validation.sh      # Phase 5
│       ├── 06-dashboard-install.sh     # Phase 6
│       └── lib/                 # 공통 라이브러리
├── memory/
│   └── errors/                  # Knowledge Base (KB-001~014)
├── GX10-*.md                    # 상세 가이드 문서
└── gx10-scripts/                # 추가 유틸리티
```

### 설치 후 GX10 디렉토리 구조

```
/gx10/
├── api/
│   ├── status.sh      # Brain 상태 조회
│   ├── switch.sh      # Brain 전환
│   ├── predict.sh     # 패턴 기반 예측
│   └── benchmark.sh   # 성능 벤치마크
├── brains/
│   ├── code/          # Code Brain 데이터
│   └── vision/        # Vision Brain 모델
├── runtime/
│   ├── active_brain.json
│   ├── certs/
│   ├── logs/
│   └── state/
└── automation/
    └── n8n/
```

---

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
│  │ • Qwen2.5-Coder-32B │      │ • NGC 25.12         │          │
│  │ • DeepSeek-Coder    │      │ • CUDA 13.1         │          │
│  │ • Qwen2.5-Coder-7B  │      │ • TensorRT          │          │
│  ├─────────────────────┤      ├─────────────────────┤          │
│  │ 메모리: 30-40GB     │      │ 메모리: 70-90GB     │          │
│  │ 토큰/초: 9-46       │      │ GPU: 최대 활용      │          │
│  └─────────────────────┘      └─────────────────────┘          │
│                                                                 │
│  ⚠️ 동시 실행 금지 - 단일 Brain만 활성화                         │
│  🔄 전환 시간: 5-17초 (Buffer Cache 플러시 포함)                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Brain 전환 명령

```bash
# Code Brain 활성화 (개발 작업)
sudo /gx10/api/switch.sh code

# Vision Brain 활성화 (비전 실험)
sudo /gx10/api/switch.sh vision

# 상태 확인
/gx10/api/status.sh
```

---

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
```

### Brain 전환 실패

```bash
# Vision 컨테이너 강제 정리
sudo docker rm -f gx10-vision-brain

# Ollama 재시작
sudo systemctl restart ollama

# 다시 전환
sudo /gx10/api/switch.sh code
```

### WebUI 접속 불가

```bash
# 컨테이너 상태 확인
sudo docker ps | grep open-webui

# 컨테이너 재시작
sudo docker restart open-webui
```

### Dashboard 접속 불가

```bash
# 서비스 상태 확인
sudo systemctl status gx10-dashboard

# 서비스 재시작
sudo systemctl restart gx10-dashboard

# 로그 확인
sudo journalctl -u gx10-dashboard -f

# 포트 확인
ss -tlnp | grep 9000
```

### Dashboard 외부 접속 시 연결 거부

```bash
# 방화벽에서 포트 9000 열기
sudo iptables -I INPUT -p tcp --dport 9000 -j ACCEPT

# 확인
curl http://$(hostname -I | awk '{print $1}'):9000/api/health
```

> 추가 문제 해결: `memory/errors/KB-*.md` 참조

---

## 📊 하드웨어 사양

| 항목 | 사양 |
|------|------|
| CPU | ARM v9.2-A (20-core: 10x Cortex-X925 + 10x Cortex-A725) |
| GPU | NVIDIA Blackwell GB10 (1 petaFLOP FP4 sparse) |
| 메모리 | 128GB LPDDR5x Unified Memory |
| 메모리 대역폭 | 273 GB/s (CPU+GPU 공유) |
| 스토리지 | 1TB NVMe SSD |
| OS | DGX OS 7.2.3 (Ubuntu 24.04 LTS 기반) |

---

## 📖 상세 문서

| 문서 | 설명 |
|------|------|
| [docs/implementation-guide.md](docs/implementation-guide.md) | 최종 구현 가이드 |
| [docs/two-brain-architecture.md](docs/two-brain-architecture.md) | Two Brain 아키텍처 |
| [docs/build-checklist.md](docs/build-checklist.md) | 구축 체크리스트 |
| [docs/external-access.md](docs/external-access.md) | 외부 접근 가이드 (Tailscale) |
| [scripts/install/README.md](scripts/install/README.md) | 스크립트 상세 설명 |
| [memory/errors/](memory/errors/) | KB-001~014 오류 해결 |

---

## 🔮 향후 검토 항목 (Roadmap)

### AI 모델 업그레이드

| 항목 | 현재 | 목표 | 상태 |
|------|------|------|------|
| Qwen2.5-Coder → Qwen3-Coder | 32B (16K ctx) | 30B-A3B (256K ctx) | 🔍 Ollama 지원 확인 필요 |
| DeepSeek-Coder-V2 → V3 | V2:16B | V3.2 | 🔍 호환성 확인 필요 |
| 정기 업데이트 | - | `ollama pull` | 📅 월 1회 권장 |

### 모델 업데이트 명령

```bash
# 전체 모델 최신 버전 업데이트
ollama list | tail -n +2 | awk '{print $1}' | xargs -I {} ollama pull {}

# 개별 모델 업데이트
ollama pull qwen2.5-coder:32b
```

### 관련 링크

- [Qwen3-Coder 공식](https://github.com/QwenLM/Qwen3-Coder)
- [Ollama 모델 라이브러리](https://ollama.com/library)
- [DeepSeek 최신 릴리즈](https://api-docs.deepseek.com/updates)

---

## 📝 문서 정보

| 항목 | 내용 |
|------|------|
| **버전** | 2.4.0 |
| **최종 수정** | 2026-02-03 |
| **1차 구축 완료** | 2026-02-03 |
| **작성** | Claude Opus 4.5 + MoAI-ADK |
| **리뷰** | holee |

### 변경 이력

| 버전 | 일자 | 설명 |
|------|------|------|
| 2.4.0 | 2026-02-03 | Phase 6 Dashboard 설치 추가 (시스템 모니터링 웹 대시보드) |
| 2.3.0 | 2026-02-03 | 향후 검토 항목(Roadmap) 섹션 추가 |
| 2.2.0 | 2026-02-03 | docs/ 폴더 구조 정리, 외부 접근 가이드 추가 |
| 2.1.0 | 2026-02-03 | KB-013~014 추가, 검증 스크립트 v3.0.0 반영 |
| 2.0.0 | 2026-02-03 | 2차 GX10 Full Auto 가이드 중심 재작성, 1차 구축 기록 정리 |
| 1.4 | 2026-02-03 | Live 진행 상황 추가, Phase 0-5 완료 |
| 1.0 | 2026-02-01 | 초기 작성 |
