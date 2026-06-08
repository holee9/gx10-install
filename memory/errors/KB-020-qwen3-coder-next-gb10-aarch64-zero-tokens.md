---
id: KB-020
date: 2026-06-08
severity: high
status: documented
---

# KB-020: qwen3-coder-next Q4_K_M — GB10 aarch64에서 전체 `?` 토큰 출력

## 증상

NVIDIA DGX Spark (GB10, SM 12.1, aarch64)에서 `qwen3-coder-next-Q4_K_M.gguf` 실행 시
모든 출력 토큰이 `?` (U+003F)로 출력됨. 모델 로딩·컨텍스트 처리는 정상.

```
"????????????????????????????????????????"  # 40 completion tokens, 전부 ?
```

- Prefill: ~220 tok/s (정상)
- Decode: ~63 tok/s (정상, 하지만 내용 없음)
- 서버 로그: 오류 없음

## 영향 버전

llama.cpp b9014 (CUDA, SM 12.1 aarch64)

## 원인 (추정)

qwen3-coder-next의 특정 양자화 패턴(Q4_K_M 텐서 shape)과
aarch64 × CUDA 커널 조합에서의 커널 선택 오류 추정.

- **amd64 × SM 12.0 (RTX 5090)에서는 동일 GGUF 정상 작동** → GPU 아키텍처 문제 아님
- **qwen3.6-35B-A3B Q4_K_M는 동일 환경에서 정상 작동** → 일반 MoE Q4_K_M 버그 아님
- coder-next 특이 버그 (aarch64 빌드 × 특정 텐서 shape 교차)

## 레퍼런스

- llama.cpp GitHub Issue #23010 (OPEN, 2026-05-13)
- https://github.com/ggml-org/llama.cpp/issues/23010

## 해결 방법

현재 수정 미완료 (OPEN). 해결책:

1. **qwen3-coder-next 설치 금지** — 수정될 때까지 GB10에서 사용 불가
2. 대안: `qwen3-coder:latest` (30B MoE, 19GB) — 동일 환경에서 정상 작동 확인됨

## 적용 범위

GB10 Grace Blackwell (SM 12.1), aarch64, CUDA 빌드 llama.cpp/Ollama
이슈 해결 전까지 qwen3-coder-next (80B 계열) 전체 설치 금지.

## 상태 모니터링

llama.cpp #23010 closed 시 재평가 가능.
