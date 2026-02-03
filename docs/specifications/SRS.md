# System Requirements Specification (SRS)

## Status
- Overall: COMPLETE
- Hardware Requirements: COMPLETE
- Software Requirements: COMPLETE
- Interface Requirements: COMPLETE

## Table of Contents
1. [Introduction](#introduction)
2. [Hardware Requirements](#hardware-requirements)
3. [Software Requirements](#software-requirements)
4. [Interface Requirements](#interface-requirements)
5. [Performance Requirements](#performance-requirements)
6. [Security Requirements](#security-requirements)
7. [Open Items](#open-items)

---

## Introduction

### 문서 목적

본 문서는 GX10 시스템의 하드웨어, 소프트웨어, 인터페이스 요구사항을 상세히 명세합니다.

---

## 문서 계층 구조

### 상위 문서
- [MRD.md](MRD.md) (DOC-MRD-001) - Market Requirements Document
- [PRD.md](PRD.md) (DOC-PRD-001) - Product Requirements Document

### 동급 문서
- [PRS.md](PRS.md) (DOC-PRS-001) - Product Requirements Specification

### 하위 문서
- [FRS.md](FRS.md) (DOC-FRS-001) - Functional Requirements Specification
- [Test_Plan.md](Test_Plan.md) (DOC-TEST-001) - Test Plan

### 관련 문서
- [../GX10-03-Final-Implementation-Guide.md](../GX10-03-Final-Implementation-Guide.md) - 최종 구현 가이드
- [../GX10-04-Build-Checklist.md](../GX10-04-Build-Checklist.md) - 빌드 체크리스트

---

## Hardware Requirements

### HR-1: ASUS GX10 하드웨어 사양

**우선순위**: P0 (필수)

**필수 사양**:

**CPU**:
- 아키텍처: ARM v9.2-A
- 코어: 20-core (10x Cortex-X925 + 10x Cortex-A725)

**GPU**:
- 모델: NVIDIA Blackwell GB10
- 성능: 1 petaFLOP FP4 sparse
- VRAM: 48GB (최대 76GB with TensorRT)

**메모리**:
- 용량: 128GB LPDDR5x Unified Memory
- 대역폭: 273 GB/s (CPU+GPU 공유)

**스토리지**:
- 용량: 1TB NVMe SSD
- 최소 여유 공간: 100GB

**네트워크**:
- 10GbE
- ConnectX-7 (200Gbps QSFP)

**권장 사양**:
- USB 포트: 최소 4개 (외부 장치 연결)
- 디스플레이 출력: HDMI 2.1 or DP 1.4 (선택사항)

---

### HR-2: 주변 장치 (Peripherals)

**우선순위**: P1 (중요)

**권장 장치**:
- 키보드, 마우스 (초기 설정용)
- 모니터 (초기 설정용, 이후 SSH로 대체)
- 이더넷 케이블 (고정 IP 권장)

---

## Software Requirements

### SR-1: 운영체제 (Operating System)

**우선순위**: P0 (필수)

**필수 요구사항**:
- OS: DGX OS (Ubuntu 24.04 기반) 프리인스톨
- 아키텍처: ARM64 (aarch64)
- 커널 버전: 5.15+

**권장 패키지**:
- build-essential
- cmake
- git
- curl
- wget
- htop
- btop
- tmux
- vim / neovim
- tree
- jq
- python3-pip
- python3-venv

---

### SR-2: 컨테이너 런타임 (Container Runtime)

**우선순위**: P0 (필수)

**필수 요구사항**:
- Docker: 24.x+
- NVIDIA Container Toolkit: 설치됨
- GPU Runtime: nvidia

**검증**:
- `docker --version`
- `docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu22.04 nvidia-smi`

---

### SR-3: 로컬 LLM (Local LLM)

**우선순위**: P0 (필수)

**Code Brain (필수)**:
- Ollama: 0.5+
- qwen2.5-coder:32b (메인)
- qwen2.5-coder:7b (빠른 응답)
- deepseek-coder-v2:16b (대안)

**Vision Brain (권장)**:
- qwen2.5-vl:72b 또는 :7b
- YOLOv8x (Ultralytics)
- SAM2-Large (Meta)
- Depth-Anything-V2

**임베딩 (선택)**:
- nomic-embed-text

---

### SR-4: 웹 서버 (Web Server)

**우선순위**: P1 (중요)

**Open WebUI (선택사항)**:
- Docker 컨테이너: ghcr.io/open-webui/open-webui:main
- 포트: 8080
- Ollama 연동

**n8n (권장)**:
- Docker 컨테이너: docker.n8n.io/n8nio/n8n
- 포트: 5678
- 자동화 워크플로우

---

### SR-5: 개발 도구 (Development Tools)

**우선순위**: P2 (낮음)

**개발자 PC**:
- Claude Code
- VS Code
- Warp 터미널
- Git

**GX10**:
- SSH 서버
- systemd 서비스 관리
- cron (스케줄링)

---

## Interface Requirements

### IR-1: 네트워크 인터페이스 (Network Interface)

**우선순위**: P0 (필수)

**포트**:
- SSH: 22
- Ollama API: 11434
- Open WebUI: 8080
- n8n: 5678
- Jupyter Lab (Vision Brain): 8888

**방화벽**:
- UFW (Uncomplicated Firewall)
- 필요 포트만 개방
- IP 제한 (선택사항)

---

### IR-2: API 인터페이스 (API Interface)

**우선순위**: P0 (필수)

**REST API**:
- 프로토콜: HTTP/HTTPS
- 포맷: JSON
- 인증: JWT Bearer Token
- Base URL: `http://<gx10-ip>:8080/api`

**주요 엔드포인트**:
- `GET /api/brain/status`
- `POST /api/brain/switch`
- `POST /api/task/execute`
- `GET /api/task/{task_id}`

---

### IR-3: CLI 인터페이스 (CLI Interface)

**우선순위**: P0 (필수)

**스크립트**:
- `/gx10/api/status.sh`: Brain 상태 조회
- `/gx10/api/switch.sh [code|vision]`: Brain 전환
- `ollama run <model>`: 직접 모델 실행

---

## Performance Requirements

### PER-1: 응답 시간 (Response Time)

**API 응답**:
- Brain 상태 조회: < 1초
- Brain 전환: < 30초
- 작업 제출: < 5초 (초기 처리)

**코드 생성**:
- 소규모 프로젝트 (< 10파일): < 30분
- 중규모 프로젝트 (10-50파일): < 2시간
- 대규모 프로젝트 (> 50파일): TBD

---

### PER-2: 처리량 (Throughput)

**Code Brain**: 단일 작업만 처리 (동시 처리 불가)

**Vision Brain**: 단일 작업만 처리 (동시 처리 불가)

**API**: 최소 10 req/s

---

### PER-3: 리소스 사용 (Resource Usage)

**Code Brain**:
- 메모리: 50-60GB (권장, Option A) 또는 40-45GB (보수적)
  - qwen2.5-coder:32b: 24GB (16K KV Cache)
  - qwen2.5-coder:7b: 5GB (상시 로드)
  - deepseek-coder-v2:16b: 10GB (on-demand)
  - Ollama 오버헤드: 4GB
- GPU: 중간 (23-48GB VRAM)
- CPU: 중간
- 참고: [GX10-08-CodeBrain-Memory-Optimization.md](../GX10-08-CodeBrain-Memory-Optimization.md)

**Vision Brain**:
- 메모리: 70-90GB
- GPU: 최대 (48-76GB VRAM)

**Idle 시스템**:
- 메모리: < 10GB (Ollama 제외)
- CPU: < 20%

---

## Security Requirements

### SE-1: 인증 및 인가 (Authentication and Authorization)

**우선순위**: P0 (필수)

**요구사항**:
- JWT 기반 인증
- 역할 기반 접근 제어 (RBAC)
- API 토큰 만료: 24시간

**역할**:
- developer: 작업 제출, 상태 조회
- data_scientist: Vision Brain 전환, 벤치마크
- admin: 모든 API 접근
- ci_cd: 작업 제출 (긴 timeout)

---

### SE-2: 네트워크 보안 (Network Security)

**우선순위**: P0 (필수)

**요구사항**:
- 방화벽: UFW
- 포트 제한: 필요 포트만 개방
- SSH: 키 기반 인증 (비밀번호 인증 비권장)

**모니터링**:
- 실패한 로그인 시도 로깅
- 비정상적인 트래픽 감지
- Rate Limiting: 100 req/min/IP

---

### SE-3: 데이터 프라이버시 (Data Privacy)

**우선순위**: P0 (필수)

**요구사항**:
- 코드가 외부 서버로 전송되지 않음
- 로그에서 민감 정보 마스킹
- 사용자 데이터 암호화 (저장 시)

**민감 정보 예시**:
- API 토큰
- 비밀번호
- 개인 식별 정보 (PII)

---

## Open Items

### TBD (To Be Determined)

1. **정확한 API 스키마**
   - 현재: 기본 엔드포인트만 정의
   - 필요: OpenAPI 3.0/Swagger 전체 스키마
   - 우선순위: P1

2. **HTTPS 지원**
   - 현재: HTTP만 지원
   - 필요: HTTPS/TLS 인증서
   - 우선순위: P2

3. **모니터링 시스템**
   - 현재: 기본 로그만 수집
   - 필요: Prometheus, Grafana 통합
   - 우선순위: P2

---

## 📝 문서 정보

**작성자**:
- AI: Claude Sonnet 4.5
- 환경: MoAI-ADK v11.0.0
- 작성일: 2026-02-01

**리뷰어**:
- drake

---

## 📜 수정 이력

| 일자 | 버전 | 설명 | 리뷰어 |
|------|------|------|--------|
| 2026-02-01 | 1.0 | 기존 문서 기반 전면 보완 | drake |
| 2026-02-01 | 1.1 | Code Brain 메모리 요구사항 업데이트 (PER-3, 30-40GB → 50-60GB, GX10-08 반영) | drake |
