# GX10 자동 구축 스크립트

GX10 OS 설치 후 자동 구축을 위한 단계별 스크립트 모음입니다.

---

## 프로젝트 목표

> **재현 가능한 자동 구축**: 이 스크립트로 여러 대의 GX10에 동일한 환경을 구축합니다.

- 1차 GX10에서 검증 완료된 스크립트를 `git clone`으로 배포
- 2-Step 설치: `sudo ./00-sudo-prereqs.sh` → `./00-install-all.sh`
- 발생한 모든 오류는 `memory/errors/`에 기록되어 스크립트에 반영 완료

---

## 전제 조건

- DGX OS 7.2.3이 설치된 ASUS Ascent GX10 하드웨어
- 인터넷 연결
- sudo 권한 (Phase 0에서만 필요)

---

## 설치 방법

### 2차+ GX10 배포 (Quick Start)

```bash
git clone https://github.com/holee9/gx10-install.git
cd gx10-install/scripts/install

# Step 1: sudo 작업 일괄 실행 (1회, 15-20분)
sudo ./00-sudo-prereqs.sh

# Step 2: 재로그인 (docker 그룹 반영)
logout
# 다시 로그인 후:

# Step 3: 나머지 자동 실행 (sudo 불필요, ~1시간 20분)
cd ~/gx10-install/scripts/install   # 또는 clone 경로
./00-install-all.sh
```

> **참고 (KB-005)**: `Permission denied` 오류 시 sudo가 아닌 `chmod +x *.sh`를 먼저 확인하세요. Git clone 시 실행 권한이 자동 반영됩니다.

### 단계별 수동 설치

개별 Phase를 하나씩 실행하려면:

```bash
cd scripts/install

# Step 1: sudo 사전 실행 (필수, 1회)
sudo ./00-sudo-prereqs.sh
# → 재로그인 필요 (docker 그룹 반영)

# Step 2: AI 모델 다운로드 (~40분, sudo 불필요)
./01-code-models-download.sh

# Step 3: Vision Brain Docker 빌드 (~20분, sudo 불필요)
./02-vision-brain-build.sh

# Step 4: Brain 전환 API (~5분, sudo 불필요)
./03-brain-switch-api.sh

# Step 5: Open WebUI 설치 (~5분, sudo 불필요)
./04-webui-install.sh

# Step 6: 최종 검증 (~10분, sudo 불필요)
./05-final-validation.sh
```

---

## 스크립트 목록

### Phase 0: sudo 사전 실행 (1회)

| 스크립트 | 설명 | sudo | 시간 |
|---------|------|------|------|
| `00-sudo-prereqs.sh` | 모든 sudo 작업 일괄 실행 | **Yes** | 15-20분 |

Phase 0이 수행하는 작업:
- 시스템 패키지 업데이트 (apt update/upgrade)
- SSH 활성화 및 방화벽 설정 (포트 22, 11434, 8080, 5678)
- `/gx10` 디렉토리 구조 생성 및 소유권 설정
- Docker 그룹에 사용자 추가
- Ollama 설치 및 systemd 서비스 구성
- models 디렉토리 ollama 유저 소유권 설정 (KB-002)
- 모니터링 서비스 등록

### Phase 1-5: 자동 설치 (sudo 불필요)

| 스크립트 | 설명 | sudo | 시간 |
|---------|------|------|------|
| `00-install-all.sh` | **전체 자동 실행 (아래 Phase 일괄)** | No | ~1시간 20분 |
| `01-code-models-download.sh` | AI 코딩 모델 다운로드 (32B, 7B) | No | 40분 |
| `02-vision-brain-build.sh` | Vision Brain Docker 이미지 빌드 | No | 20분 |
| `03-brain-switch-api.sh` | Brain 전환 API 구축 | No | 5분 |
| `04-webui-install.sh` | Open WebUI 설치 | No | 5분 |
| `05-final-validation.sh` | 최종 검증 및 테스트 | No | 10분 |

### 레거시 스크립트 (Phase 0에서 대체됨)

| 스크립트 | 설명 | 비고 |
|---------|------|------|
| `01-initial-setup.sh` | 시스템 업데이트 | Phase 0에 통합됨 |
| `02-directory-structure.sh` | 디렉토리 생성 | Phase 0에 통합됨 |
| `03-environment-config.sh` | 환경 설정 | Phase 0에 통합됨 |
| `04-code-brain-install.sh` | Ollama 설치 | Phase 0에 통합됨 |
| `09-service-automation.sh` | 서비스 자동화 | Phase 0에 통합됨 (삭제됨) |

**총 예상 시간**: Phase 0 (15-20분) + Phase 1-5 (~1시간 20분) = **약 1시간 40분**

---

## Pre-flight 체크

`00-install-all.sh` 실행 시 자동으로 다음을 확인합니다:

1. `/gx10` 디렉토리 구조 존재 여부 (Phase 0 완료 확인)
2. Ollama 서비스 응답 여부 (`curl localhost:11434`)
3. Docker 접근 권한 (`docker ps`)

실패 시 구체적인 해결 방법을 안내합니다.

---

## 오류 처리

### 공통 오류 및 해결

**오류**: `mkdir /gx10/brains/code/models/blobs: permission denied`
**원인**: Ollama 서비스(`User=ollama`)가 models 디렉토리에 쓰기 권한 없음
**해결**: `sudo chown -R ollama:ollama /gx10/brains/code/models`
**참고**: KB-002 (이 문제는 00-sudo-prereqs.sh v1.1+에서 해결됨)

**오류**: Docker permission denied
**해결**: 재로그인 또는 `newgrp docker`

**오류**: Ollama connection refused
**해결**: `sudo systemctl restart ollama` (10초 대기 후 확인)

**오류**: GPU not found in Docker
**해결**: `docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu22.04 nvidia-smi`

### 실패한 단계 재실행

```bash
cd scripts/install
./<실패한-스크립트>.sh    # sudo 불필요
```

---

## 설치 후 접속 정보

| 서비스 | URL | 비고 |
|--------|-----|------|
| Open WebUI | `http://<GX10-IP>:8080` | 첫 접속 시 계정 생성 |
| Brain Status | `/gx10/api/status.sh` | CLI 명령 |
| Brain Switch | `/gx10/api/switch.sh [code\|vision]` | CLI 명령 |

```bash
# IP 확인
hostname -I

# Brain 상태 확인
/gx10/api/status.sh

# 설치된 모델 확인
ollama list
```

---

## 로그 파일

모든 로그는 `/gx10/runtime/logs/`에 저장됩니다:
- `install-all.log` — 전체 설치 로그
- `XX-script-name.log` — 개별 스크립트 로그

---

## 관련 문서

- [GX10-07 구축 계획서](../../GX10-07-Auto-Installation-Plan.md)
- [GX10-03 구현 가이드](../../GX10-03-Final-Implementation-Guide.md)
- [INSTALLATION-CHECKLIST](../../INSTALLATION-CHECKLIST.md) — 실시간 체크리스트
- [memory/errors/](../../memory/errors/) — 오류 기록 및 해결책

---

## 📝 문서 정보

**버전**: 3.0.0
**상태**: RELEASED
**최종 수정일**: 2026-02-03

**작성자**: Claude Sonnet 4.5 / MoAI-ADK v11.0.0
**리뷰어**: drake, holee

## 📜 수정 이력

| 일자 | 버전 | 설명 | 리뷰어 |
|------|------|------|--------|
| 2026-02-01 | 1.0 | 초기 작성 | drake |
| 2026-02-02 | 2.0.0 | 오류 처리, 보안 강화 추가 | drake |
| 2026-02-03 | 3.0.0 | Phase 0 패턴 반영, 2차 GX10 배포 대응, 레거시 분리 | holee |
