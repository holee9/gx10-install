#!/usr/bin/env python3
"""
Git Pre-commit Hook: Validate and Add Author/Reviewer Info

This hook checks all markdown files in the staging area and ensures
they have proper author/reviewer information before commit.

Usage: Place in .git/hooks/pre-commit and make executable
"""

import os
import subprocess
import sys
from datetime import datetime

# Configuration
DEFAULT_REVIEWER = "drake"
AUTHOR_SECTION_MARKER = "## 📝 문서 정보"


def get_staged_md_files():
    """Get list of staged markdown files."""
    result = subprocess.run(
        ['git', 'diff', '--cached', '--name-only', '--diff-filter=ACM', '*.md'],
        capture_output=True,
        text=True
    )
    return result.stdout.splitlines() if result.stdout.strip() else []


def has_author_section(file_path):
    """Check if file has author section."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        return AUTHOR_SECTION_MARKER in content
    except Exception:
        return False


def add_author_info_git_hook(file_path):
    """Add author info to file (Git hook version)."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        if has_author_section(file_path):
            return False

        lines = content.strip().split('\n')
        if len(lines) < 5:
            return False

        has_substantial_content = len(content) > 200

        if has_substantial_content:
            author_info = f"""- AI: {os.environ.get('CLAUDE_MODEL', 'Claude Sonnet 4.5')}
- 환경: {os.environ.get('MOAI_VERSION', 'MoAI-ADK v11.0.0')}
- 작성일: {datetime.now().strftime('%Y-%m-%d')}"""
        else:
            author_info = "- (작성자 정보 없음)"

        author_section = f"""---

{AUTHOR_SECTION_MARKER}

**작성자**:

{author_info}

**리뷰어**:

- {DEFAULT_REVIEWER}
"""

        new_content = content.rstrip() + '\n' + author_section + '\n'

        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)

        # Stage the modified file
        subprocess.run(['git', 'add', file_path], capture_output=True)
        return True

    except Exception as e:
        print(f"Warning: {file_path}: {e}", file=sys.stderr)
        return False


def main():
    """Main pre-commit hook function."""
    md_files = get_staged_md_files()

    if not md_files:
        return 0

    print(f"📝 {len(md_files)}개의 마크다운 파일을 검사합니다...")

    processed = 0
    for file_path in md_files:
        if not has_author_section(file_path):
            print(f"  + {file_path}: 작성자 정보 추가")
            if add_author_info_git_hook(file_path):
                processed += 1

    if processed > 0:
        print(f"\n✓ {processed}개 파일에 작성자/리뷰어 정보를 추가했습니다.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
