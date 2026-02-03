# 외부 접근 가이드

GX10 구축 후 외부에서 접근하는 방법입니다.

---

## 권장: Tailscale (제로 트러스트 VPN)

### 장점
- **보안**: WireGuard 기반 암호화, 포트 노출 없음
- **속도**: P2P 직접 연결
- **간편**: 별도 설정 불필요

### 설정 방법

1. GX10에 Tailscale 설치:
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

2. Tailscale IP 확인:
```bash
tailscale ip -4
# 예: 100.x.x.x
```

3. 외부에서 접근:
```
Ollama API: http://100.x.x.x:11434
WebUI:      http://100.x.x.x:8080
SSH:        ssh user@100.x.x.x
```

### n8n 연동 예시

n8n HTTP Request 노드:
```
URL: http://<GX10-TAILSCALE-IP>:11434/api/generate
Method: POST
Headers: Content-Type: application/json
Body:
{
  "model": "qwen2.5-coder:7b",
  "prompt": "your prompt here",
  "stream": false
}
```

---

## 대안: Cloudflare Tunnel

공개 API가 필요한 경우 (권장하지 않음):

```bash
# Cloudflare Tunnel 설치
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o cloudflared
chmod +x cloudflared

# 터널 생성
./cloudflared tunnel create gx10
./cloudflared tunnel route dns gx10 gx10.your-domain.com
```

> ⚠️ **주의**: 인증 없이 노출 시 보안 위험. Cloudflare Access 설정 필수.

---

## 보안 권장사항

| 방법 | 보안 | 권장 |
|------|------|------|
| Tailscale | ⭐⭐⭐ | ✅ 내부 사용 |
| Cloudflare Tunnel + Access | ⭐⭐⭐ | ⭕ 외부 공개 |
| 포트포워딩 | ⭐ | ❌ 비권장 |

---

## 네트워크 구성 예시

```
┌─ Tailscale Network ─────────────────────────────┐
│                                                  │
│  🖥️ GX10           100.x.x.a                    │
│     ├─ :11434 (Ollama API)                      │
│     └─ :8080  (WebUI)                           │
│                                                  │
│  🍓 라즈베리파이     100.x.x.b                   │
│     └─ n8n 자동화                               │
│                                                  │
│  💻 개발자 PC        100.x.x.c                   │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## 문서 정보

| 항목 | 내용 |
|------|------|
| **버전** | 1.0.0 |
| **최종 수정** | 2026-02-03 |
