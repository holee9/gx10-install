# MoAI-ADK Hooks Library

Shared utilities for Claude Code hooks in MoAI-ADK.

## Module Overview

```
lib/
├── __init__.py           # Package exports
├── common.py             # Shared utilities (format_duration, merge_configs)
├── config_manager.py     # Configuration loading and management
├── config_validator.py   # Configuration schema validation
├── exceptions.py         # Exception hierarchy
├── models.py             # Data structures (HookPayload, HookResult)
├── path_utils.py         # Project root detection, safe paths
├── project.py            # Project metadata (language, Git, SPEC)
├── unified_timeout_manager.py  # Unified timeout management (basic + advanced)
├── git_operations_manager.py   # Optimized Git operations
├── checkpoint.py         # Risky operation detection
├── language_validator.py # Language config validation
└── tool_registry.py      # Formatter/linter tool registry
```

## Exit Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 0 | Success | Normal completion |
| 1 | Warning/Error | Non-critical error, logged |
| 2 | Critical Error | Blocks operation |
| 3 | Configuration Error | Invalid config |

## Exception Hierarchy

```
HooksBaseError (base)
├── TimeoutError
│   └── HookTimeoutError (with context)
├── GitOperationError
├── ConfigurationError
├── ValidationError
└── SecurityError
```

## Key Functions

### Path Management (`path_utils.py`)

```python
from lib.path_utils import find_project_root, get_safe_moai_path

# Find project root (with caching)
root = find_project_root()

# Get safe path within .moai/
cache_path = get_safe_moai_path("cache/version.json")
```

### Configuration (`config_manager.py`)

```python
from lib.config_manager import ConfigManager, get_config

# Load configuration
config = ConfigManager().load_config()

# Get specific value
timeout = get_config("hooks.timeout_ms", default=5000)
```

### Timeout Handling (`unified_timeout_manager.py`)

The unified timeout manager provides both basic and advanced timeout functionality:

```python
# Basic timeout (lightweight cross-platform handler)
from lib.unified_timeout_manager import CrossPlatformTimeout

with CrossPlatformTimeout(5):
    long_running_operation()

# Advanced timeout with retry, memory monitoring, and graceful degradation
from lib.unified_timeout_manager import get_timeout_manager

manager = get_timeout_manager()
result = manager.execute_with_timeout("hook_name", func, config=config)
```

### Common Utilities (`common.py`)

```python
from lib.common import merge_configs, format_duration

# Merge configs recursively
merged = merge_configs(base_config, override_config)

# Format duration
formatted = format_duration(125.5)  # "2.1m"
```

## Configuration Files

### Main Config
Location: `.moai/config/config.yaml`

### Section Files
Location: `.moai/config/sections/`
- `user.yaml` - User name
- `language.yaml` - Language preferences
- `project.yaml` - Project metadata
- `git-strategy.yaml` - Git workflow
- `quality.yaml` - DDD settings

## Hook Data Flow

```
Claude Code Event
    ↓
stdin (JSON)
    ↓
Hook Process
    ↓
stdout (JSON response)
    ↓
Claude Code
```

### Response Format

```json
{
  "continue": true,
  "systemMessage": "...",
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask"
  }
}
```

## Hook Development Best Practices

### Shebang in Hook Scripts

**Important:** Hook scripts include shebang (`#!/usr/bin/env python3`) for documentation and IDE compatibility, but **shebang is not used during execution**.

#### How Hooks Are Executed

Hooks are **always executed via `uv run`** by Claude Code, as configured in `settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [{
      "type": "command",
      "command": "uv run \"%CLAUDE_PROJECT_DIR%//.claude/hooks/moai/post_tool__linter.py\""
    }]
  }
}
```

#### Platform Behavior

- **macOS/Linux**: Shebang is ignored (executed via `uv run`)
- **Windows**: Shebang is ignored (Windows doesn't recognize shebang)
- **All platforms**: `uv run` determines the Python interpreter

#### Testing Hooks Manually

**Do not execute hook scripts directly.** Always use `uv run`:

```bash
# ✅ CORRECT: Use uv run (all platforms)
uv run .claude/hooks/moai/session_start__show_project_info.py

# ❌ WRONG: Direct execution (may fail on Windows)
./.claude/hooks/moai/session_start__show_project_info.py
```

#### Why Shebang Is Included

1. **Documentation**: Indicates the script is Python
2. **IDE Support**: Editors recognize the file type
3. **Direct Execution (Unix only)**: Works if user makes script executable manually

**Best Practice**: Keep shebang for documentation, but rely on `uv run` for execution.

### Cross-Platform Compatibility

When developing hooks:

1. **Use `pathlib.Path`** instead of string concatenation
2. **Normalize paths** with `path_utils.normalize_path()` for comparisons
3. **Test on multiple platforms** (macOS, Linux, Windows PowerShell)
4. **Avoid platform-specific commands** in subprocess calls

Example:

```python
from pathlib import Path
from lib.path_utils import find_project_root

# ✅ CORRECT: Cross-platform
root = find_project_root()
config_file = root / ".moai" / "config" / "config.yaml"

# ❌ WRONG: Platform-specific
config_file = f"{root}/.moai/config/config.yaml"
```

## Version

- Library Version: 1.0.0
- Last Updated: 2025-01
---

## 📝 문서 정보

**작성자**:

- AI: Claude Sonnet 4.5
- 환경: MoAI-ADK v11.0.0
- 작성일: 2026-02-01

**리뷰어**:

- drake

