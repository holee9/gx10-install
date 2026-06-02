---
id: KB-016
date: 2026-06-02
severity: high
status: resolved
---

# KB-016: qwen3:30b 기본 컨텍스트(262K)로 인한 RAM 전체 점유

## 증상

`ollama ps` 출력에서 qwen3:30b가 SIZE 122 GB로 나타나며, 시스템 RAM 119 GiB 전부 점유.
다른 모델을 동시에 로드할 수 없음. 응답 시 swap 사용으로 성능 저하.

## 원인

qwen3:30b의 기본 컨텍스트는 262,144 토큰. KV cache 사전 할당:
- 모델 가중치: 18 GB
- KV 캐시 (262K × 94layers × 8kv_heads × 128dim × fp16 × 2): 101 GB
- 합계: **119 GB** — GB10 통합 메모리 전체

## 해결

전용 Modelfile로 컨텍스트 32,768 토큰 제한:

```
FROM qwen3:30b
PARAMETER num_ctx 32768
PARAMETER temperature 0.7
SYSTEM "..."
```

```bash
ollama create kqwen-coder -f /gx10/automation/Modelfile-kqwen-coder
```

메모리 사용량: ~31 GB (88 GB 여유)

## Open-WebUI 연결

`k-qwen-coder` 커스텀 모델의 `base_model_id`를 `kqwen-coder:latest`로 변경.

## 컨텍스트별 메모리 참고

| ctx | KV 캐시 | 합계 |
|-----|---------|------|
| 4K | 1.6 GB | 20 GB |
| 8K | 3.2 GB | 21 GB |
| 16K | 6.3 GB | 24 GB |
| 32K | 12.6 GB | 31 GB |
| 64K | 25 GB | 43 GB |
| 262K | 101 GB | 119 GB |
