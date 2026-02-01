# MoAI 문서 작성자 정보 자동 추가 설정

## 개요

이 시스템은 Claude Code 또는 MoAI로 생성/수정된 문서에 자동으로 작성자와 리뷰어 정보를 추가합니다.

## 구성 요소

### 1. Claude Code Hook

**위치**: `.claude/hooks/add-author-info.py`

**동작**: Claude Code가 파일을 생성할 때 자동으로 실행

**트리거**: `*.md` 파일 생성/수정

### 2. Git Pre-commit Hook

**위치**: `scripts/pre-commit-add-author.py`

**동작**: Git 커밋 전 모든 `.md` 파일 검사 및 정보 추가

**트리거**: `git commit` 실행 시

### 3. MoAI 문서 템플릿

**위치**: `.moai/templates/document-template.md`

**용도**: 새 문서 생성 시 템플릿으로 사용

## 설치 방법

### 1. Claude Code Hook 활성화

```bash
# Hook 스크립트에 실행 권한 부여
chmod +x .claude/hooks/add-author-info.py

# Claude Code 설정 파일에 Hook 등록
# (Claude Code가 Hook 시스템을 지원하는 경우)
```

### 2. Git Hook 설치

```bash
# Pre-commit Hook 설치
cp scripts/pre-commit-add-author.py .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# 또는 pre-commit 도구 사용 (권장)
pip install pre-commit
pre-commit install
```

### 3. MoAI 템플릿 사용

```bash
# 새 문서 생성 시 템플릿 복사
cp .moai/templates/document-template.md your-document.md

# 또는 MoAI 명령어 사용
/moai template document your-document.md
```

## 환경 변수

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `CLAUDE_MODEL` | Claude 모델 ID | claude-sonnet-4-5-20250929 |
| `MOAI_VERSION` | MoAI 버전 | MoAI-ADK v11.0.0 |
| `MOAI_LANGUAGE` | 언어 설정 | Korean Language Support |
| `DEFAULT_REVIEWER` | 기본 리뷰어 | drake |

## 사용 예시

### 예시 1: Claude Code로 문서 생성

```bash
# Claude Code에서 문서 생성
# Hook이 자동으로 실행되어 작성자 정보 추가
```

### 예시 2: 수동으로 문서 생성 후 Git 커밋

```bash
# 문서 생성
echo "# My Document" > my-doc.md

# Git 커밋 (pre-commit hook이 자동으로 실행)
git add my-doc.md
git commit -m "Add my document"
# ✓ Hook이 작성자 정보를 자동 추가
```

### 예시 3: MoAI 템플릿 사용

```bash
# 템플릿 복사
cp .moai/templates/document-template.md new-doc.md

# 내용 작성 후 커밋
git add new-doc.md
git commit -m "Add new document"
```

## 작성자 정보 포맷

### AI 생성 문서 (내용이 있는 경우)

```markdown
## 📝 문서 정보

**작성자**:

- AI: Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)
- 환경: MoAI-ADK v11.0.0 (Claude Code + Korean Language Support)
- 작성일: 2026-02-01

**리뷰어**:

- drake
```

### 기존 문서 또는 내용이 적은 경우

```markdown
## 📝 문서 정보

**작성자**:

- (작성자 정보 없음)

**리뷰어**:

- drake
```

## 문제 해결

### Hook이 실행되지 않음

```bash
# Claude Code Hook 권한 확인
ls -la .claude/hooks/add-author-info.py
# 실행 권한이 없으면:
chmod +x .claude/hooks/add-author-info.py

# Git Hook 권한 확인
ls -la .git/hooks/pre-commit
# 실행 권한이 없으면:
chmod +x .git/hooks/pre-commit
```

### 작성자 정보가 중복 추가됨

```bash
# 이미 작성자 정보가 있는 파일은 자동으로 건너뜁니다.
# 중복 추가된 경우 수동으로 제거하세요.
```

## 확장

### 프로젝트별 리뷰어 설정

```bash
# 프로젝트별로 다른 리뷰어 설정
export DEFAULT_REVIEWER="project-reviewer"
git commit -m "Add document"
```

### 커스텀 작성자 정보

```python
# .claude/hooks/add-author-info.py 수정
def get_claude_info():
    # 커스텀 로직 추가
    return {
        "model": os.environ.get("CUSTOM_MODEL", "default-model"),
        "environment": os.environ.get("CUSTOM_ENV", "default-env"),
        "date": datetime.now().strftime("%Y-%m-%d")
    }
```

## 유지보수

- **버전**: 1.0
- **마지막 수정**: 2026-02-01
- **유지관리자**: MoAI Team

---

## 📝 문서 정보

**작성자**:

- AI: Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)
- 환경: MoAI-ADK v11.0.0 (Claude Code + Korean Language Support)
- 작성일: 2026-02-01

**리뷰어**:

- drake
