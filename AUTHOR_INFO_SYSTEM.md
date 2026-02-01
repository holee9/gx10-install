# 📝 MoAI 문서 작성자 정보 자동 추가 시스템

Claude Code 또는 MoAI로 생성된 문서에 자동으로 작성자와 리뷰어 정보를 추가하는 전역 자동화 시스템입니다.

## 🎯 기능

- ✅ Claude Code가 문서를 생성할 때 자동으로 작성자 정보 추가
- ✅ Git 커밋 시 자동으로 모든 `.md` 파일 검사 및 정보 추가
- ✅ MoAI 문서 템플릿 제공
- ✅ 기존 문서와 AI 생성 문서를 자동으로 구분

## 📁 구조

```
gx10-install/
├── .claude/
│   └── hooks/
│       └── add-author-info.py          # Claude Code Hook
├── .moai/
│   ├── config/
│   │   └── document-author-info.md    # 상세 설정 문서
│   └── templates/
│       └── document-template.md        # 문서 템플릿
├── scripts/
│   ├── install-hooks.sh                # 설치 스크립트
│   └── pre-commit-add-author.py       # Git Hook
└── .pre-commit-config.yaml             # Pre-commit 설정
```

## 🚀 빠른 시작

### 1. 설치

```bash
# 설치 스크립트 실행
bash scripts/install-hooks.sh

# 또는 수동으로 Git Hook 설치
cp scripts/pre-commit-add-author.py .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### 2. 사용 방법

#### 방법 1: Claude Code로 문서 생성 (자동)

Claude Code에서 문서를 생성하면 Hook이 자동으로 실행되어 작성자 정보를 추가합니다.

#### 방법 2: Git 커밋 시 자동 추가

```bash
# 문서 생성
echo "# My Document" > my-doc.md

# Git 커밋 (Hook이 자동으로 실행)
git add my-doc.md
git commit -m "Add document"
# ✓ Hook이 작성자 정보를 자동 추가하고 재커밋
```

#### 방법 3: 수동 실행

```bash
# 특정 파일에 작성자 정보 추가
python3 .claude/hooks/add-author-info.py document.md

# 또는 Git Hook 직접 실행
python3 scripts/pre-commit-add-author.py
```

## 📋 작성자 정보 포맷

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

## 🔧 환경 변수

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `DEFAULT_REVIEWER` | 기본 리뷰어 이름 | drake |
| `CLAUDE_MODEL` | Claude 모델 ID | claude-sonnet-4-5-20250929 |
| `MOAI_VERSION` | MoAI 버전 | MoAI-ADK v11.0.0 |
| `MOAI_LANGUAGE` | 언어 설정 | Korean Language Support |

### 사용 예시

```bash
# 프로젝트별 리뷰어 설정
export DEFAULT_REVIEWER="project-reviewer"
git commit -m "Add document"

# 커스텀 모델 지정
export CLAUDE_MODEL="claude-opus-4-5-20250929"
python3 .claude/hooks/add-author-info.py doc.md
```

## 📚 상세 문서

자세한 설정과 사용법은 [`.moai/config/document-author-info.md`](.moai/config/document-author-info.md)를 참조하세요.

## ✅ 테스트

```bash
# 테스트 문서 생성
echo "# Test" > test-doc.md

# Hook 실행 테스트
python3 .claude/hooks/add-author-info.py test-doc.md

# 결과 확인
cat test-doc.md
```

## 🛠️ 문제 해결

### Hook이 실행되지 않음

```bash
# 권한 확인
ls -la .claude/hooks/add-author-info.py
ls -la .git/hooks/pre-commit

# 권한이 없으면 추가
chmod +x .claude/hooks/add-author-info.py
chmod +x .git/hooks/pre-commit
```

### 작성자 정보가 중복 추가됨

이미 작성자 정보가 있는 파일은 자동으로 건너뜁니다. 중복이 발생하면 수동으로 제거하세요.

## 🔗 관련 문서

- [Claude Code Hooks](https://code.anthropic.com/docs#hooks)
- [Pre-commit Framework](https://pre-commit.com/)
- [MoAI Documentation](.moai/config/)

---

## 📜 수정 이력

| 일자 | 버전 | 설명 | 리뷰어 |
|------|------|------|--------|
| 2026-02-01 | 1.0 | 문서 작성자 정보 자동 추가 시스템 구축 | drake |
| 2026-02-01 | 1.1 | 수정 이력 추적 기능 추가 | drake |

---

## 📝 문서 정보

**작성자**:

- AI: Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)
- 환경: MoAI-ADK v11.0.0 (Claude Code + Korean Language Support)
- 작성일: 2026-02-01

**리뷰어**:

- drake

**버전**: 1.0

**상태**: 완료
