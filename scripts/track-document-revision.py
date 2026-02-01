#!/usr/bin/env python3
"""
Document Revision History Tracker

This script tracks document revisions and updates the revision history section.
It adds a new entry each time a document is significantly modified.

Usage: python3 scripts/track-document-revision.py <file.md> "<description>"
"""

import os
import sys
import re
from datetime import datetime
from pathlib import Path

# Configuration
DEFAULT_REVIEWER = "drake"
REVISION_HISTORY_MARKER = "## 3. 수정 이력"
REVISION_TABLE_PATTERN = r"\| 일자 \| 버전 \| 설명 \| 리뷰어 \|"


def get_current_date():
    """Get current date in YYYY-MM-DD format."""
    return datetime.now().strftime("%Y-%m-%d")


def get_git_author():
    """Get current git author name."""
    try:
        result = os.popen('git config user.name').read().strip()
        return result if result else "Unknown"
    except:
        return "Unknown"


def has_revision_history(content):
    """Check if document already has revision history section."""
    return REVISION_HISTORY_MARKER in content


def get_next_version(content):
    """Determine next version number based on existing revisions."""
    # Extract existing version numbers
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


def create_revision_history(existing_content, description, reviewer=None):
    """Create or update revision history section."""
    current_date = get_current_date()
    reviewer = reviewer or DEFAULT_REVIEWER
    version = "1.0"

    if has_revision_history(existing_content):
        version = get_next_version(existing_content)

    new_entry = f"| {current_date} | {version} | {description} | {reviewer} |"

    if has_revision_history(existing_content):
        # Find the revision history table and add new entry
        lines = existing_content.split('\n')

        # Find the table end (separator line after header)
        table_start = -1
        separator_line = -1

        for i, line in enumerate(lines):
            if REVISION_HISTORY_MARKER in line:
                table_start = i
            elif table_start >= 0 and separator_line < 0 and "---" in line and i > table_start + 1:
                separator_line = i
                break

        if separator_line >= 0:
            # Insert new entry after separator
            lines.insert(separator_line + 1, new_entry)
            return '\n'.join(lines)
    else:
        # Create new revision history section
        revision_section = f"""

---

{REVISION_HISTORY_MARKER}

문서의 주요 수정 사항을 기록합니다.

| 일자 | 버전 | 설명 | 리뷰어 |
|------|------|------|--------|
| {current_date} | {version} | {description} | {reviewer} |
"""

        # Find the last section before document info
        doc_info_marker = "## 📝 문서 정보"
        if doc_info_marker in existing_content:
            # Insert before document info
            parts = existing_content.split(doc_info_marker)
            return parts[0] + revision_section + "\n" + doc_info_marker + parts[1]
        else:
            # Append at the end
            return existing_content.rstrip() + revision_section


def update_document_info(content, version, date, reviewer):
    """Update document info section with new version and date."""
    # Update version
    content = re.sub(
        r"(\*\*문서 버전\*\*:\s*)\d+\.\d+",
        f"\\1{version}",
        content
    )

    # Update last modified date
    content = re.sub(
        r"(\*\*최종 수정\*\*:\s*)\d{4}-\d{2}-\d{2}",
        f"\\1{date}",
        content
    )

    return content


def track_revision(file_path, description, reviewer=None):
    """Track document revision."""
    try:
        # Read file
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Get current version and date
        current_date = get_current_date()
        reviewer = reviewer or DEFAULT_REVIEWER

        # Add or update revision history
        content = create_revision_history(content, description, reviewer)

        # Get version for document info update
        version = get_next_version(content) if has_revision_history(content) else "1.0"

        # Update document info section
        content = update_document_info(content, version, current_date, reviewer)

        # Write back
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)

        print(f"✓ {file_path}: 수정 이력 기록 완료")
        print(f"  버전: {version}, 일자: {current_date}, 리뷰어: {reviewer}")
        print(f"  설명: {description}")
        return True

    except Exception as e:
        print(f"✗ {file_path}: 오류 - {e}", file=sys.stderr)
        return False


def main():
    """Main function."""
    if len(sys.argv) < 3:
        print("Usage: track-document-revision.py <file.md> \"<description>\" [reviewer]")
        print("\n예시:")
        print("  python3 scripts/track-document-revision.py README.md \"초안 작성\"")
        print("  python3 scripts/track-document-revision.py README.md \"API 섹션 추가\" drake")
        sys.exit(1)

    file_path = sys.argv[1]
    description = sys.argv[2]
    reviewer = sys.argv[3] if len(sys.argv) > 3 else None

    if not os.path.exists(file_path):
        print(f"✗ 오류: 파일을 찾을 수 없습니다: {file_path}", file=sys.stderr)
        sys.exit(1)

    if track_revision(file_path, description, reviewer):
        return 0
    else:
        return 1


if __name__ == "__main__":
    sys.exit(main())
