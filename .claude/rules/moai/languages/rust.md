---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
  - "**/Cargo.lock"
---

# Rust Rules

Version: Rust 1.92+

## Tooling

- Linting: clippy
- Formatting: rustfmt
- Testing: cargo test with coverage
- Package management: cargo

## Preferred Patterns

- Use Result<T, E> for error handling
- Use tokio for async runtime
- Minimize unsafe blocks

## MoAI Integration

- Use Skill("moai-lang-rust") for detailed patterns
- Follow TRUST 5 quality gates
---

## 📝 문서 정보

**작성자**:

- AI: Claude Sonnet 4.5
- 환경: MoAI-ADK v11.0.0
- 작성일: 2026-02-01

**리뷰어**:

- drake

