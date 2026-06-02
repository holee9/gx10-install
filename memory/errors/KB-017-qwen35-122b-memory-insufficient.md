---
id: KB-017
date: 2026-06-02
severity: high
status: resolved
---

# KB-017: qwen3.5:122b 실행 불가 — GB10 메모리 부족

## 증상

`ollama pull qwen3.5:122b` 성공(81 GB 다운로드) 후 실행 시:
- CPU 모드: `model requires more system memory (149.1 GiB) than is available (131.0 GiB)`
- GPU 모드: `llama runner process has terminated with exit code -1`

## 원인

| 항목 | 값 |
|------|-----|
| 모델 파일 크기 | 81 GB (Q4_K_M) |
| weights 런타임 | ~81 GB |
| KV 캐시 (262K ctx) | ~68 GB |
| **총 런타임 요구량** | **149 GiB** |
| GB10 실제 가용 RAM | 119 GiB (GPU/CPU 통합 단일 풀) |
| swap 포함 합산 | ~131 GiB |

GB10(Grace Blackwell)은 GPU VRAM이 별도 없음. 시스템 RAM 119 GiB를 CPU/GPU가 공유.

## 이전 보고서 오류

- "128 GB 통합 메모리" — 스펙시트 기준. 실측 `MemTotal: 119 GiB`
- "65 GB 모델 벤치마크 확인" — 웹서치 결과를 이 장비에 무검증 적용한 오류

## 조치

- 모델 삭제 (81 GB 회수)
- qwen3:30b + 32K ctx 제한 모델(`kqwen-coder:latest`)로 운영

## GB10 운용 한계

- 단일 모델 실용 상한: weights ~50 GB 이하 (32K ctx 기준 ~63 GB 합산)
- 100B+ dense 모델: 실행 불가
- MoE 구조 대형 모델: active params 기준이 아닌 전체 weights 로드 필요 → 동일 제약
