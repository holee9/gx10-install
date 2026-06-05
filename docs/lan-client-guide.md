# GX10 AI 서버 사용 가이드

**서버:** NVIDIA DGX Spark (GB10 Grace Blackwell)  
**위치:** 2.5G 로컬 LAN 스위치 연결  
**최종 업데이트:** 2026-06-05

---

## 1. 접속 정보

| 구분 | 주소 | 용도 |
|------|------|------|
| **2.5G LAN** | `192.168.100.1` | 권장 — 고속 연결 |
| 1G LAN | `10.20.6.141` | 대체 |
| Tailscale VPN | `100.78.1.7` | 원격 접속 |

### 서비스 포트

| 서비스 | URL | 용도 |
|--------|-----|------|
| **Open WebUI** | `http://192.168.100.1:8080` | 웹 브라우저 채팅 UI |
| **Ollama API** | `http://192.168.100.1:11434` | 프로그램 연동 (OpenAI 호환) |
| **SearXNG** | `http://192.168.100.1:8888` | 프라이빗 검색엔진 |

---

## 2. 운영 모델

| 모델 | 용도 | 속도 |
|------|------|------|
| `gpt-oss:120b` | 범용 (서치·코딩·RAG 추론) | 41–58 tok/s |
| `qwen3-embedding:latest` | 텍스트 임베딩 (벡터 생성) | — |

> **단일 엔드포인트 원칙:** 모든 추론 요청은 `gpt-oss:120b` 하나로 처리됩니다.  
> 호출 시스템에서 모델을 선택하거나 구분할 필요가 없습니다.

---

## 3. 브라우저로 사용 (Open WebUI)

1. 브라우저에서 `http://192.168.100.1:8080` 접속
2. 계정 생성 또는 로그인
3. 모델 선택: `gpt-oss:120b`
4. 채팅 시작

### 웹 검색 활성화 (실시간 서치)

Open WebUI 채팅창 하단의 🔍 버튼 클릭 → 자동으로 SearXNG를 통해 실시간 검색 후 답변합니다.

---

## 4. API로 사용 (프로그램 연동)

Ollama는 OpenAI API와 호환되는 엔드포인트를 제공합니다.  
기존 OpenAI SDK 코드에서 `base_url`만 변경하면 바로 사용 가능합니다.

### 4-1. curl

```bash
# 단순 질의
curl http://192.168.100.1:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-oss:120b",
    "prompt": "파이썬으로 피보나치 수열을 구현해줘",
    "stream": false
  }'

# 스트리밍 (실시간 출력)
curl http://192.168.100.1:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-oss:120b",
    "prompt": "머신러닝과 딥러닝의 차이를 설명해줘",
    "stream": true
  }'
```

### 4-2. Python — Ollama 네이티브

```python
from ollama import Client

client = Client(host="http://192.168.100.1:11434")

response = client.chat(
    model="gpt-oss:120b",
    messages=[
        {"role": "user", "content": "파이썬으로 REST API 서버를 만드는 방법을 알려줘"}
    ]
)
print(response.message.content)
```

**스트리밍:**

```python
from ollama import Client

client = Client(host="http://192.168.100.1:11434")

for chunk in client.chat(
    model="gpt-oss:120b",
    messages=[{"role": "user", "content": "도커 컨테이너 개념을 설명해줘"}],
    stream=True
):
    print(chunk.message.content, end="", flush=True)
```

### 4-3. Python — OpenAI SDK (호환 모드)

기존 OpenAI 코드 재사용 가능:

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://192.168.100.1:11434/v1",
    api_key="ollama"  # 임의 값, 필수 파라미터이므로 아무 값이나 입력
)

response = client.chat.completions.create(
    model="gpt-oss:120b",
    messages=[
        {"role": "system", "content": "당신은 유능한 AI 어시스턴트입니다."},
        {"role": "user", "content": "SQL에서 JOIN의 종류를 설명해줘"}
    ]
)
print(response.choices[0].message.content)
```

### 4-4. Python — 비동기 (AsyncIO)

```python
import asyncio
from openai import AsyncOpenAI

client = AsyncOpenAI(
    base_url="http://192.168.100.1:11434/v1",
    api_key="ollama"
)

async def ask(question: str) -> str:
    response = await client.chat.completions.create(
        model="gpt-oss:120b",
        messages=[{"role": "user", "content": question}]
    )
    return response.choices[0].message.content

result = asyncio.run(ask("클라우드 네이티브 아키텍처의 핵심 원칙은?"))
print(result)
```

---

## 5. 임베딩 API (RAG / 벡터 검색)

텍스트를 벡터로 변환하는 임베딩 전용 엔드포인트입니다.  
벡터 DB(Chroma, Qdrant, Weaviate 등)와 연동하여 RAG 파이프라인 구성에 사용합니다.

### curl

```bash
curl http://192.168.100.1:11434/api/embed \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3-embedding:latest",
    "input": "임베딩할 텍스트를 여기에 입력합니다"
  }'
```

### Python

```python
from ollama import Client

client = Client(host="http://192.168.100.1:11434")

result = client.embed(
    model="qwen3-embedding:latest",
    input="임베딩할 텍스트"
)
print(result.embeddings)  # float 벡터 리스트

# 배치 처리
result = client.embed(
    model="qwen3-embedding:latest",
    input=["첫 번째 문서", "두 번째 문서", "세 번째 문서"]
)
for vec in result.embeddings:
    print(f"벡터 차원: {len(vec)}")
```

### OpenAI SDK 호환

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://192.168.100.1:11434/v1",
    api_key="ollama"
)

response = client.embeddings.create(
    model="qwen3-embedding:latest",
    input="임베딩할 텍스트"
)
vector = response.data[0].embedding
print(f"벡터 차원: {len(vector)}")
```

---

## 6. 멀티턴 대화 (컨텍스트 유지)

```python
from ollama import Client

client = Client(host="http://192.168.100.1:11434")

history = []

def chat(user_input: str) -> str:
    history.append({"role": "user", "content": user_input})
    response = client.chat(model="gpt-oss:120b", messages=history)
    reply = response.message.content
    history.append({"role": "assistant", "content": reply})
    return reply

print(chat("파이썬의 GIL이 뭐야?"))
print(chat("그럼 멀티스레딩이 의미없는건가?"))  # 이전 대화 기억
print(chat("asyncio는 이 문제를 어떻게 해결해?"))
```

---

## 7. 모델 상태 확인 API

```bash
# 서버 연결 확인
curl http://192.168.100.1:11434/

# 설치된 모델 목록
curl http://192.168.100.1:11434/api/tags

# 현재 로드된 모델
curl http://192.168.100.1:11434/api/ps

# 모델 상세 정보
curl http://192.168.100.1:11434/api/show \
  -d '{"name": "gpt-oss:120b"}'
```

---

## 8. 운영 사양 및 제한

| 항목 | 값 | 비고 |
|------|-----|------|
| 동시 처리 요청 | **최대 2개** | `OLLAMA_NUM_PARALLEL=2` |
| 모델 메모리 유지 | **2시간** | 마지막 요청 후 2시간 뒤 언로드 |
| 최대 컨텍스트 | 모델 기본값 | gpt-oss:120b: 128K |
| 네트워크 권장 | **2.5G LAN** | 1G LAN도 가능하나 대용량 응답 시 체감 차이 |

### 응답 속도 기준 (gpt-oss:120b)

| 상황 | 예상 속도 |
|------|-----------|
| 일반 질의 | 41–58 tok/s |
| 장문 컨텍스트 (RAG) | 28–45 tok/s |
| 모델 첫 로딩 (콜드 스타트) | 약 30–60초 소요 |

> 콜드 스타트: 2시간 이상 미사용 후 첫 요청 시 모델(65GB)을 메모리에 적재하는 시간이 소요됩니다.

---

## 9. 패키지 설치

```bash
# Ollama Python SDK
pip install ollama

# OpenAI SDK (호환 사용)
pip install openai

# 둘 다 설치
pip install ollama openai
```

---

## 10. 자주 쓰는 엔드포인트 요약

| 목적 | 엔드포인트 | 메서드 |
|------|-----------|--------|
| 채팅 (스트리밍) | `/api/chat` | POST |
| 텍스트 생성 | `/api/generate` | POST |
| 임베딩 | `/api/embed` | POST |
| 모델 목록 | `/api/tags` | GET |
| 로드된 모델 | `/api/ps` | GET |
| OpenAI 호환 채팅 | `/v1/chat/completions` | POST |
| OpenAI 호환 임베딩 | `/v1/embeddings` | POST |

**기본 URL:** `http://192.168.100.1:11434`
