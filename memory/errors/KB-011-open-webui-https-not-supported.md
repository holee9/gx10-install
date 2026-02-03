# KB-011: Open WebUI HTTPS 내부 미지원

## 오류 정보

- **발생일**: 2026-02-03
- **Phase**: Phase 4 (WebUI Install)
- **스크립트**: `04-webui-install.sh`
- **심각도**: High

## 증상

```
사이트에 연결할 수 없음
10.11.1.210에서 연결을 거부했습니다.
ERR_CONNECTION_REFUSED
```

- 브라우저에서 `https://10.11.1.210:443` 접속 시 연결 거부
- 컨테이너는 `443:8443` 포트 매핑으로 정상 실행 중
- `curl -k https://10.11.1.210` 연결 실패 (HTTP 응답 코드 000)

## 원인

**Open WebUI 컨테이너는 기본적으로 8443 포트에서 HTTPS를 지원하지 않음**

스크립트에서 설정한 환경변수들이 Open WebUI에서 공식 지원되지 않음:
- `HTTPS_ENABLED=true` - 미지원
- `SSL_CERT_PATH` - 미지원
- `SSL_KEY_PATH` - 미지원

Open WebUI는 내부적으로 **8080 포트에서 HTTP만** 제공하며, HTTPS가 필요한 경우 별도의 reverse proxy(nginx, traefik 등)를 앞단에 구성해야 함.

## 해결 방법

### 즉시 해결 (수동)

```bash
# 기존 컨테이너 중지 및 삭제
sudo docker stop open-webui
sudo docker rm open-webui

# HTTP 모드로 재시작
sudo docker run -d \
  --name open-webui \
  --restart unless-stopped \
  -p 8080:8080 \
  -v /gx10/brains/code/webui:/app/backend/data \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-webui/open-webui:main
```

### 영구 해결 (스크립트 수정)

`04-webui-install.sh`에서 HTTPS 관련 로직 제거, HTTP(8080)를 기본으로 변경

## 검증

```bash
# 컨테이너 상태 확인
sudo docker ps | grep open-webui
# Expected: 0.0.0.0:8080->8080/tcp

# 접속 테스트
curl -s -o /dev/null -w "%{http_code}" http://10.11.1.210:8080
# Expected: 200 또는 302
```

## 접속 URL

- **HTTP**: `http://10.11.1.210:8080`

## 교훈

1. 컨테이너 이미지의 실제 지원 기능을 사전에 확인할 것
2. HTTPS가 필요하면 reverse proxy 아키텍처 사용
3. 스크립트 작성 시 fallback 메커니즘보다 **검증된 기본 설정** 우선

## 관련 문서

- [Open WebUI GitHub](https://github.com/open-webui/open-webui)
- GX10-03-Final-Implementation-Guide.md
