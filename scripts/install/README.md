# GX10 자동 구축 스크립트

GX10 OS 설치 후 자동 구축을 위한 단계별 스크립트 모음입니다.

## 문서 계층 구조

### 상위 문서
- [../../GX10_Project_Documents/SRS.md](../../GX10_Project_Documents/SRS.md) (DOC-SRS-001) - 시스템 요구사항
- [../../GX10-07-Auto-Installation-Plan.md](../../GX10-07-Auto-Installation-Plan.md) (DOC-GX10-07) - 자동 설치 계획

### 관련 문서
- [../../GX10-03-Final-Implementation-Guide.md](../../GX10-03-Final-Implementation-Guide.md) - 최종 구현 가이드
- [../../GX10-04-Build-Checklist.md](../../GX10-04-Build-Checklist.md) - 빌드 체크리스트
- [../../GX10-08-CodeBrain-Memory-Optimization.md](../../GX10-08-CodeBrain-Memory-Optimization.md) (DOC-GX10-08) - 메모리 최적화

---

## 전제 조건

- DGX OS가 설치된 GX10 하드웨어
- 인터넷 연결
- sudo 권한

## 설치 방법

### 방법 1: 전체 자동 설치 (권장)

```bash
cd scripts/install
sudo ./00-install-all.sh
```

### 방법 2: 단계별 설치

각 단계를 순서대로 실행합니다:

```bash
cd scripts/install

# Phase 1: 초기 설정
sudo ./01-initial-setup.sh

# Phase 2: 디렉토리 구조
sudo ./02-directory-structure.sh

# Phase 3: 환경 설정
source ./03-environment-config.sh

# Phase 4: Code Brain 설치
sudo ./04-code-brain-install.sh

# Phase 5: 모델 다운로드 (40-60분)
sudo ./05-code-models-download.sh

# Phase 6: Vision Brain 빌드 (20-30분)
sudo ./06-vision-brain-build.sh

# Phase 7: Brain 전환 API
sudo ./07-brain-switch-api.sh

# Phase 8: Open WebUI
sudo ./08-webui-install.sh

# Phase 9: 서비스 자동화
sudo ./09-service-automation.sh

# Phase 10: 최종 검증
sudo ./10-final-validation.sh
```

## 설치 단계

| 단계 | 스크립트 | 설명 | 예상 시간 |
|------|---------|------|-----------|
| 01 | `01-initial-setup.sh` | 시스템 업데이트 및 필수 패키지 | 10분 |
| 02 | `02-directory-structure.sh` | 디렉토리 구조 생성 | 2분 |
| 03 | `03-environment-config.sh` | 환경변수 및 Docker 설정 | 3분 |
| 04 | `04-code-brain-install.sh` | Ollama 설치 | 5분 |
| 05 | `05-code-models-download.sh` | 코딩 모델 다운로드 | 40분 |
| 06 | `06-vision-brain-build.sh` | Vision Brain 빌드 | 20분 |
| 07 | `07-brain-switch-api.sh` | Brain 전환 API | 5분 |
| 08 | `08-webui-install.sh` | Open WebUI 설치 | 5분 |
| 09 | `09-service-automation.sh` | 서비스 자동화 | 5분 |
| 10 | `10-final-validation.sh` | 최종 검증 | 10분 |

**참고**: 메모리 최적화 설정은 [GX10-08](../../GX10-08-CodeBrain-Memory-Optimization.md)을 참조하세요.

**총 예상 시간**: 약 2시간

## 오류 처리

### 스크립트 실행 중 오류 발생 시

1. 로그 확인:
```bash
cat /gx10/runtime/logs/XX-script-name.log
```

2. 실패한 단계 재실행:
```bash
cd scripts/install
sudo ./XX-failed-script.sh
```

3. 이전 단계부터 재실행 (필요한 경우):
```bash
sudo ./XX-script-name.sh
```

### 공통 오류 및 해결

**오류**: Docker permission denied
**해결**:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

**오류**: Ollama connection refused
**해결**:
```bash
sudo systemctl restart ollama
sudo systemctl status ollama
```

**오류**: GPU not found in Docker
**해결**:
```bash
docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu22.04 nvidia-smi
```

## 설치 후 검증

### 1. 시스템 상태 확인

```bash
# GPU 상태
nvidia-smi

# 메모리 상태
free -h

# 디스크 상태
df -h
```

### 2. Brain 상태 확인

```bash
# 현재 활성 Brain 확인
/gx10/api/status.sh

# 설치된 모델 확인
ollama list
```

### 3. 웹 인터페이스 접속

```bash
# IP 확인
hostname -I

# Open WebUI: http://<IP>:8080
# n8n: http://<IP>:5678 (admin/gx10admin)
```

### 4. Brain 전환 테스트

```bash
# Vision Brain으로 전환
sudo /gx10/api/switch.sh vision

# Code Brain으로 전환
sudo /gx10/api/switch.sh code
```

## 디렉토리 구조

```
/gx10/
├─ brains/
│ ├─ code/          # Code Brain (Ollama)
│ └─ vision/        # Vision Brain (Docker)
├─ runtime/         # 런타임 상태 및 로그
├─ api/             # Brain 제어 API
├─ automation/      # 자동화 도구 (n8n)
└─ system/          # 시스템 모니터링
```

## 로그 파일

모든 스크립트의 로그는 `/gx10/runtime/logs/`에 저장됩니다:

- `01-initial-setup.log`
- `02-directory-structure.log`
- ...
- `install-all.log` (전체 설치 로그)
- `installation-report.txt` (설치 보고서)

## 제거 방법

시스템을 초기 상태로 되돌리려면:

```bash
# 컨테이너 중지 및 제거
docker stop open-webui n8n gx10-vision-brain 2>/dev/null
docker rm open-webui n8n gx10-vision-brain 2>/dev/null

# Ollama 중지
sudo systemctl stop ollama
sudo systemctl disable ollama

# 디렉토리 제거
sudo rm -rf /gx10

# 사용자 정의 제거 (.bashrc)
# 편집기로 ~/.bashrc 열고 GX10 관련 라인 제거
```

## 지원 및 문서

- [GX10-07 계획서](../../GX10-07-Auto-Installation-Plan.md)
- [GX10-03 구현 가이드](../../GX10-03-Final-Implementation-Guide.md)
- [GX10-04 빌드 체크리스트](../../GX10-04-Build-Checklist.md)

## 버전

- 버전: 1.0
- 작성일: 2026-02-01
- 작성자: Claude Sonnet 4.5
- 리뷰어: drake
---

## 📝 문서 정보

**문서 ID**: DOC-SCR-001
**버전**: 1.1
**상태**: RELEASED
**작성일**: 2026-02-01
**최종 수정일**: 2026-02-01

**작성자**:
- AI: Claude Sonnet 4.5
- 환경: MoAI-ADK v11.0.0

**리뷰어**:
- drake

## 📜 수정 이력

| 일자 | 버전 | 설명 | 리뷰어 |
|------|------|------|--------|
| 2026-02-01 | 1.0 | 초기 작성 | drake |
| 2026-02-01 | 1.1 | 문서 계층 구조 및 메타데이터 보강 | drake |

