---
id: KB-018
date: 2026-06-02
severity: medium
status: documented
---

# KB-018: GB10 GPU 활성 메모리 실측 — 동시 GPU 로드 1개 제한

## 증상

`ollama ps`에 모델이 1개만 표시됨 (MAX_LOADED_MODELS=3 설정에도 불구하고).
두 번째 모델 호출 시 첫 번째 모델이 ps에서 사라짐.

## 원인

GB10(Grace Blackwell)은 119 GiB 통합 메모리이지만, **GPU 활성 메모리(GPU-mapped UVM)는 약 32-33 GiB**로 제한됨.
- 하나의 모델 runner process가 최대 ~31,609 MiB 사용 (nvidia-smi 실측)
- 두 번째 모델(33 GB)은 같은 GPU에 동시 로드 불가

## 실측 동작

| 항목 | 값 |
|------|-----|
| GPU 활성 메모리 (nvidia-smi) | ~31,609 MiB (1개 모델 한도) |
| 모델 전환 load_duration | **0.1~0.12s** (RAM 상주 확인) |
| KEEP_ALIVE 효과 | 가중치 RAM 보관 → 전환 시 디스크 재로드 없음 |
| `ollama ps` 표시 | GPU 활성 모델만 표시 (RAM 상주 모델은 미표시) |

## 올바른 이해

- `KEEP_ALIVE=2h`: 가중치를 **시스템 RAM**에 유지 (디스크 재로드 방지)
- GPU에는 **요청 시점**에만 1개 모델 활성화
- 모델 전환: GPU evict → RAM 상주 모델을 GPU로 이동 (0.1s)
- `ollama ps`: GPU 활성 모델만 표시 — 정상 동작

## 권장 설정

```ini
OLLAMA_MAX_LOADED_MODELS=2   # kqwen-coder/rag 중 1개 + qwen3-embedding
OLLAMA_KEEP_ALIVE=2h         # RAM 상주로 빠른 전환
```

> MAX_LOADED_MODELS=3은 허용하되, GPU 동시 활성은 1개임을 인지.
