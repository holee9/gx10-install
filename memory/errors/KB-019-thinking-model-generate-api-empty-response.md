---
id: KB-019
date: 2026-06-05
severity: medium
status: documented
---

# KB-019: Thinking 모델 generate API 빈 응답

## 증상

`gpt-oss:120b` (thinking 모델)에 `/api/generate`로 `num_predict: 10~20` 설정 시 응답 content가 빈 문자열 반환.

```bash
curl http://localhost:11434/api/generate -d '{"model":"gpt-oss:120b","prompt":"...","options":{"num_predict":20}}'
# → response: ""
```

## 원인

Thinking 모델은 응답 생성 전 내부 추론(think 블록) 단계를 거침.
`num_predict`가 작으면 모든 토큰이 think 블록에서 소비되어 실제 content가 0자가 됨.

## 해결

1. `/api/chat` 엔드포인트 사용 (generate 대신)
2. `num_predict` 최소 1000 이상 설정 (think 블록 + 실제 응답 여유분)

```bash
curl http://localhost:11434/api/chat \
  -d '{"model":"gpt-oss:120b","messages":[{"role":"user","content":"..."}],"options":{"num_predict":1500}}'
```

## 실측

- num_predict 300 → content 빈 문자열 (think 블록 전량 소비)
- num_predict 1500 → 정상 응답, 21.0 tok/s

## 적용 모델

gpt-oss:120b 및 기타 thinking 모델 (DeepSeek-R1 계열 등) 공통
