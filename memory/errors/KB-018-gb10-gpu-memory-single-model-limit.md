---
id: KB-018
date: 2026-06-02
severity: medium
status: documented
---

# KB-018: GB10 GPU 동시 로드 실효 한도 ~46 GiB

## 증상

33 GB 모델 2개를 동시 GPU 로드하려 하면 교대로만 동작함.
`ollama ps`에 GPU 활성 모델만 표시되어 "1개 제한"으로 오해하기 쉬움.

## 실측값 (2026-06-02 nvidia-smi 직접 확인)

| 조합 | GPU 합계 | 동시 로드 |
|------|---------|---------|
| kqwen-coder(31,609 MiB) + qwen3-embedding(14,386 MiB) | ~46 GiB | ✅ 가능 |
| kqwen-coder(33 GB) + kqwen-rag(33 GB) | ~63 GiB | ❌ 불가, GPU 교대 |

## 결론

- GB10 GPU 동시 활성 실효 한도: **약 46-48 GiB**
- 33 GB 모델 2개(~63 GiB) = 동시 GPU 불가 → GPU 교대, RAM 상주로 보완
- 33 GB + 15 GB(embedding) = 동시 가능 → 기본 운영 권장 구성

## 운영 동작

| 항목 | 값 |
|------|-----|
| GPU 동시 로드 한도 | ~46-48 GiB (실측) |
| 모델 전환 load_duration | **0.1~0.12s** (RAM 상주 → GPU 이동) |
| `ollama ps` 표시 | GPU 활성 모델만 표시, RAM 상주 모델은 미표시 (정상) |

## 권장 설정

```ini
OLLAMA_MAX_LOADED_MODELS=3   # RAM에 최대 3개 유지 (coder + rag + embedding)
OLLAMA_KEEP_ALIVE=2h         # RAM 상주로 0.1s GPU 전환
```
