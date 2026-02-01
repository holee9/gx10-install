#!/usr/bin/env python3
"""
Claude Code Hook: Auto-add Author/Reviewer Info + Track Revisions

This hook automatically adds author and reviewer information to markdown documents
and tracks revision history when documents are created or modified by Claude Code.

Triggered: After file write operation
Pattern: *.md files
"""

import os
import sys
import subprocess
from datetime import datetime
from pathlib import Path

# Configuration
DEFAULT_REVIEWER = "drake"
AUTHOR_SECTION_MARKER = "## 📝 문서 정보"
REVISION_HISTORY_MARKER = "## 3. 수정 이력"


def get_claude_info():
    """Get current Claude model information from environment."""
    model_id = os.environ.get("CLAUDE_MODEL", "claude-sonnet-4-5-20250929")
    moai_version = os.environ.get("MOAI_VERSION", "MoAI-ADK v11.0.0")
    language = os.environ.get("MOAI_LANGUAGE", "Korean Language Support")

    return {
        "model": model_id,
        "environment": f"{moai_version} (Claude Code + {language})",
        "date": datetime.now().strftime("%Y-%m-%d")
    }


def get_current_date():
    """Get current date in YYYY-MM-DD format."""
    return datetime.now().strftime("%Y-%m-%d")


def get_git_diff_description(file_path):
    """Get git diff description for the change."""
    try:
        # Get git status to see if file is new or modified
        result = subprocess.run(
            ['git', 'status', '--porcelain', file_path],
            capture_output=True,
            text=True,
            cwd=os.path.dirname(file_path) or '.'
        )

        if result.returncode == 0:
            status = result.stdout.strip()[:2] if result.stdout.strip() else ''
            if status == 'A ':
                return "초안 작성"
            elif status in ['M ', ' M']:
                return "내용 수정"
            elif status == 'R ':
                return "파일 이름 변경"
    except:
        pass

    return "문서 수정"


def has_author_section(content):
    """Check if document already has author section."""
    return AUTHOR_SECTION_MARKER in content


def has_revision_history(content):
    """Check if document already has revision history section."""
    return REVISION_HISTORY_MARKER in content


def get_next_version(content):
    """Determine next version number based on existing revisions."""
    import re

    # Extract existing version numbers from revision table
    pattern = r"\|\s*(\d{4}-\d{2}-\d{2})\s*\|\s*(\d+\.\d+)\s*\|"
    matches = re.findall(pattern, content)

    if not matches:
        return "1.0"

    # Find highest version number
    versions = [float(match[1]) for match in matches]
    max_version = max(versions)

    # Increment minor version
    major = int(max_version)
    minor = int((max_version - major) * 10 + 1)

    if minor > 9:
        major += 1
        minor = 0
    else:
        minor = str(minor)

    return f"{major}.{minor}"


def generate_author_section(has_author_info=True):
    """Generate author/reviewer section."""
    claude_info = get_claude_info()
    current_date = get_current_date()

    if has_author_info:
        # Full info with AI details
        author_info = """- AI: {model}
- 환경: {environment}
- 작성일: {date}""".format(**claude_info)
    else:
        # Placeholder for unknown author
        author_info = "- (작성자 정보 없음)"

    return f"""---

{AUTHOR_SECTION_MARKER}

**작성자**:

{author_info}

**리뷰어**:

- {DEFAULT_REVIEWER}
"""


def create_revision_history_section(content, description, reviewer=None):
    """Create or update revision history section."""
    current_date = get_current_date()
    reviewer = reviewer or DEFAULT_REVIEWER
    version = get_next_version(content) if has_revision_history(content) else "1.0"

    new_entry = f"| {current_date} | {version} | {description} | {reviewer} |"

    if has_revision_history(content):
        # Find the revision history table and add new entry
        lines = content.split('\n')

        # Find the table (look for the table separator)
        table_start = -1
        insert_pos = -1

        for i, line in enumerate(lines):
            if REVISION_HISTORY_MARKER in line:
                table_start = i
            elif table_start >= 0 and insert_pos < 0:
                # Insert after the table header separator (line with dashes)
                if line.startswith('|---') or line.strip().startswith('|------'):
                    insert_pos = i
                    break

        if insert_pos >= 0:
            # Insert new entry after separator
            lines.insert(insert_pos + 1, new_entry)
            return '\n'.join(lines)
    else:
        # Create new revision history section (before document info)
        revision_section = f"""

---

{REVISION_HISTORY_MARKER}

문서의 주요 수정 사항을 기록합니다.

| 일자 | 버전 | 설명 | 리뷰어 |
|------|------|------|--------|
| {current_date} | {version} | {description} | {reviewer} |
"""

        # Insert before document info section
        doc_info_marker = "## 📝 문서 정보"
        if doc_info_marker in content:
            parts = content.split(doc_info_marker)
            return parts[0] + revision_section + "\n" + doc_info_marker + parts[1]
        else:
            # Append at the end
            return content.rstrip() + revision_section

    return content


def update_document_info(content, version=None, date=None):
    """Update document info section with new version and date."""
    import re

    current_date = date or get_current_date()

    # Update version if provided
    if version:
        content = re.sub(
            r"(\*\*문서 버전\*\*:\s*)\d+\.\d+",
            f"\\1{version}",
            content
        )

    # Update last modified date
    content = re.sub(
        r"(\*\*최종 수정\*\*:\s*)\d{4}-\d{2}-\d{2}",
        f"\\1{current_date}",
        content
    )

    # Add document version if not exists
    if "**문서 버전**:" not in content:
        version = version or "1.0"
        # Find the reviewer line and add version after it
        content = content.replace(
            f"- {DEFAULT_REVIEWER}\n",
            f"- {DEFAULT_REVIEWER}\n\n**문서 버전**: {version}\n"
        )

    return content


def add_author_info_to_file(file_path):
    """Add author info and revision history to a markdown file."""
    try:
        # Read file content
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check if already has author section
        has_author = has_author_section(content)

        # Check if file has substantial content
        lines = content.strip().split('\n')
        has_substantial_content = len(content) > 200

        # Skip very short files
        if len(lines) < 5:
            return False

        # Get change description from git
        description = get_git_diff_description(file_path)

        # Add revision history first (before author section)
        content = create_revision_history_section(content, description, DEFAULT_REVIEWER)

        # Get version for document info
        version = get_next_version(content) if has_revision_history(content) else "1.0"

        # Add or update author section at the end
        if not has_author:
            author_section = generate_author_section(
                has_author_info=has_substantial_content
            )
            content = content.rstrip() + author_section + '\n'

        # Update document info section
        content = update_document_info(content, version, get_current_date())

        # Write back
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)

        print(f"✓ {file_path}: 작성자 정보 및 수정 이력 추가 완료")
        print(f"  버전: {version}, 일자: {get_current_date()}, 리뷰어: {DEFAULT_REVIEWER}")
        return True

    except Exception as e:
        print(f"✗ {file_path}: 오류 - {e}", file=sys.stderr)
        return False


def main():
    """Main hook function."""
    if len(sys.argv) < 2:
        print("Usage: add-author-info.py <file1.md> [file2.md] ...")
        sys.exit(1)

    files = sys.argv[1:]
    processed = 0

    for file_path in files:
        if not file_path.endswith('.md'):
            continue

        if not os.path.exists(file_path):
            continue

        if add_author_info_to_file(file_path):
            processed += 1

    print(f"\n총 {processed}개 파일에 작성자 정보 및 수정 이력을 추가했습니다.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
