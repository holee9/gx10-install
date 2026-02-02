# GX10 포트 할당 표준

**버전**: 1.0
**작성일**: 2026-02-01
**수정자**: omc-planner (2026-02-01 - 포트 할당 표준화 문서 작성)

---

## 개요

본 문서는 GX10 시스템의 모든 네트워크 서비스에 대한 포트 할당 표준을 정의합니다. 포트 충돌을 방지하고 향후 확장을 위한 예약 풀을 관리합니다.

---

## 표준 포트 할당

| 포트 | 서비스 | 프로토콜 | 용도 | 관리자 | 외부 노출 |
|------|--------|----------|------|--------|-----------|
| 22 | SSH | TCP | 시스템 관리 | 시스템 | 선택적 (VPN만) |
| 11434 | Ollama API | HTTP | Code Brain LLM API | Code Brain | localhost만 |
| 8080 | Open WebUI | HTTP | 웹 채팅 인터페이스 | Code Brain | 선택적 (UFW IP 제한) |
| 8888 | Jupyter Lab | HTTP | Vision Brain 노트북 | Vision Brain | VPN/LAN만 |
| 5678 | n8n | HTTP | 워크플로우 자동화 | Automation | VPN/LAN만 |
| 9000 | GX10 API | HTTP | Brain 제어 API | 시스템 | localhost만 |
| 9001-9100 | 예약 풀 | HTTP | 향후 서비스용 | 시스템 | 미정 |

---

## 포트별 상세

### 22: SSH (시스템 관리)

**용도**: 원격 시스템 관리

**접근 제어**:
- VPN 또는 Tailscale 통해서만 접근 허용
- 공개 인터넷에서 직접 접근 금지

**설정**:
```bash
# /etc/ssh/sshd_config
Port 22
PermitRootLogin no
PasswordAuthentication no
```

---

### 11434: Ollama API (Code Brain)

**용도**: Code Brain LLM 추론 API

**접근 제어**:
- **localhost만** (127.0.0.1)
- 외부 접근 시 SSH 터널 사용 필요

**설정**:
```bash
# 방화벽 (외부 접근 차단)
sudo ufw deny 11434

# SSH 터널 예시 (개발자 PC)
ssh -L 11434:localhost:11434 user@gx10-ip
```

**API 예시**:
```bash
# localhost에서만 접근 가능
curl http://localhost:11434/api/generate
```

---

### 8080: Open WebUI (웹 채팅)

**용도**: LLM과의 웹 기반 채팅 인터페이스

**접근 제어**:
- 선택적 공개 가능
- IP 기반 접근 제한 권장

**설정**:
```bash
# 방화벽 (특정 IP만 허용)
sudo ufw allow from 192.168.1.0/24 to any port 8080
```

---

### 8888: Jupyter Lab (Vision Brain)

**용도**: Vision Brain 개발 환경

**접근 제어**:
- VPN 또는 LAN 내부만
- 공개 인터넷에서 접근 금지

**설정**:
```bash
# Docker Compose
ports:
  - "127.0.0.1:8888:8888"  # localhost만
  # 또는
  - "8888:8888"  # VPN/LAN만 허용
```

---

### 5678: n8n (워크플로우 자동화)

**용도**: CI/CD, MCP 통합, 자동화 파이프라인

**접근 제어**:
- VPN 또는 LAN 내부만
- 공개 인터넷에서 접근 금지

**설정**:
```bash
# 방화벽 (VPN만 허용)
sudo ufw allow from 10.0.0.0/8 to any port 5678
```

---

### 9000: GX10 API (Brain 제어)

**용도**: Brain 전환, 상태 조회, 헬스체크

**접근 제어**:
- **localhost만** (127.0.0.1)
- MCP 통신용

**API 엔드포인트**:
```
GET  /api/health          # 시스템 헬스체크
GET  /api/brain/status    # 현재 활성 Brain 상태
POST /api/brain/switch    # Brain 전환 (code <-> vision)
```

---

### 9001-9100: 예약 풀

**용도**: 향후 확장을 위한 포트 예약 풀

**할당 정책**:
- 선착순이 아닌 필요성 검토 후 할당
- 새로운 서비스 추가 시 본 문서 업데이트
- 포트 사용 로그 유지

---

## 네트워크 토폴로지

```
┌─────────────────────────────────────────────────────────┐
│                      인터넷                             │
└───────────────────────┬─────────────────────────────────┘
                        │ (금지)
                        ▼
┌─────────────────────────────────────────────────────────┐
│                    VPN/LAN                             │
│  10.0.0.0/8 또는 192.168.1.0/24                        │
│                                                         │
│  허용된 포트:                                           │
│  - 22 (SSH)                                             │
│  - 8080 (Open WebUI - 선택적)                           │
│  - 8888 (Jupyter Lab)                                   │
│  - 5678 (n8n)                                           │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                   GX10 시스템                           │
│                                                         │
│  ┌───────────────────────────────────────────┐          │
│  │   localhost 전용 (SSH 터널 필요)          │          │
│  │   - 11434 (Ollama API)                   │          │
│  │   - 9000 (GX10 API)                      │          │
│  └───────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────┘
```

---

## 방화벽 설정 표준

### 기본 정책

```bash
# 기본 정책: 모든 인바운드 거부, 아웃바운드 허용
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH 허용 (VPN만)
sudo ufw allow from 10.0.0.0/8 to any port 22
sudo ufw allow from 192.168.1.0/24 to any port 22

# Code Brain
sudo ufw deny 11434  # Ollama API (localhost만)
sudo ufw allow from 192.168.1.0/24 to any port 8080  # Open WebUI

# Vision Brain
sudo ufw allow from 10.0.0.0/8 to any port 8888  # Jupyter Lab

# Automation
sudo ufw allow from 10.0.0.0/8 to any port 5678  # n8n

# GX10 API
sudo ufw deny 9000  # localhost만

# 방화벽 활성화
sudo ufw enable
```

---

## 포트 충돌 방지

### 검증 절차

새로운 서비스 추가 전:

1. **포트 사용 확인**:
   ```bash
   sudo netstat -tulpn | grep <포트>
   sudo lsof -i :<포트>
   ```

2. **예약 풀 확인**: 본 문서의 예약 풀 범위 확인

3. **문서 업데이트**: 포트 할당 테이블에 추가

---

## 보안 정책

### 원칙

1. **최소 권한**: 필요한 포트만 개방
2. **localhost 우선**: API 서비스는 localhost만 노출
3. **VPN 강제**: 시스템 관리는 VPN 통해야만 접근
4. **IP 제한**: 공개 서비스는 IP 기반 접근 제한

### 감사

```bash
# 접속 로그 모니터링
sudo journalctl -u ssh -f
sudo tail -f /var/log/nginx/access.log

# 포트 스캔 탐지
sudo ufw logging medium
```

---

## 참고 문서

- [SRS.md](SRS.md) - IR-1: 네트워크 인터페이스 요구사항
- [scripts/install/01-initial-setup.sh](../scripts/install/01-initial-setup.sh) - 방화벽 설정
- [GX10-03-Final-Implementation-Guide.md](../GX10-03-Final-Implementation-Guide.md) - 네트워크 설정

---

## 변경 이력

| 일자 | 버전 | 변경 사항 | 수정자 |
|------|------|-----------|--------|
| 2026-02-01 | 1.0 | 초기 표준화 | omc-planner |

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
- 수정 내용: 포트 할당 표준화 문서 작성 (omc-planner)
