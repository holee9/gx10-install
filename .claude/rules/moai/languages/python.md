---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/requirements*.txt"
---

# Python Rules

Version: Python 3.13+

## Tooling

- Linting: ruff (not flake8)
- Formatting: black, isort
- Type checking: mypy
- Testing: pytest with coverage >= 85%
- Package management: uv or Poetry

## Preferred Patterns

- Use async/await over callbacks
- Use Pydantic v2 for validation
- Use SQLAlchemy 2.0 async patterns
- Use pytest-asyncio for async tests

## MoAI Integration

- Use Skill("moai-lang-python") for detailed patterns
- Follow TRUST 5 quality gates
- Configure ruff in pyproject.toml
---

## 📝 문서 정보

**작성자**:

- AI: Claude Sonnet 4.5
- 환경: MoAI-ADK v11.0.0
- 작성일: 2026-02-01

**리뷰어**:

- drake

