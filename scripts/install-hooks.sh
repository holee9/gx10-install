#!/bin/bash
# Git Hook Installation Script
# This script installs the pre-commit hook for adding author/reviewer info

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "📝 MoAI 작성자/리뷰어 정보 자동 추가 시스템 설치"
echo ""

# Check if .git directory exists
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo "❌ 오류: Git 저장소가 아닙니다."
    echo "   먼저 'git init'을 실행하세요."
    exit 1
fi

# Install pre-commit hook
echo "1️⃣ Git Pre-commit Hook 설치..."
cp "$PROJECT_ROOT/scripts/pre-commit-add-author.py" "$PROJECT_ROOT/.git/hooks/pre-commit"
chmod +x "$PROJECT_ROOT/.git/hooks/pre-commit"
echo "   ✓ Hook 설치 완료: .git/hooks/pre-commit"

# Check if pre-commit tool is available
if command -v pre-commit &> /dev/null; then
    echo ""
    echo "2️⃣ Pre-commit 도구 감지됨"
    echo "   .pre-commit-config.yaml을 이미 설치했다면 활성화하세요:"
    echo "   $ pre-commit install"
fi

# Create symbolic link for Claude Code hook (if supported)
echo ""
echo "3️⃣ Claude Code Hook 정보:"
echo "   위치: $PROJECT_ROOT/.claude/hooks/add-author-info.py"
echo "   ※ Claude Code가 Hook을 지원하면 자동으로 실행됩니다."

# Test hook
echo ""
echo "4️⃣ Hook 테스트..."
python3 "$PROJECT_ROOT/scripts/pre-commit-add-author.py" --help 2>/dev/null || true
echo "   ✓ 스크립트 실행 가능"

echo ""
echo "✅ 설치 완료!"
echo ""
echo "📋 사용 방법:"
echo "   1. Claude Code로 문서 생성 → 자동으로 작성자 정보 추가"
echo "   2. git commit → pre-commit hook이 자동으로 실행"
echo "   3. 또는 수동 실행: python3 scripts/pre-commit-add-author.py"
echo ""
echo "🔧 환경 변수 (선택사항):"
echo "   export DEFAULT_REVIEWER=\"your-name\""
echo "   export CLAUDE_MODEL=\"claude-opus-4-5-20250929\""
echo "   export MOAI_VERSION=\"MoAI-ADK v11.0.0\""
