# KB-003: sudo and Session Limitations in Claude Code

## Metadata

**Date**: 2026-02-03
**Author**: MoAI
**Category**: process-mistake
**Severity**: high
**Status**: mitigated

## Tags

`severity: high`
`type: process`
`status: mitigated`
`recurrence: first-time`
`component: claude-code, installation-workflow`

---

## Problem Description

### What Happened?

Multiple failures occurred because Claude Code cannot:
1. Execute `sudo` commands (no TTY for password input)
2. Refresh group memberships mid-session (`newgrp docker` doesn't propagate to Claude Code's shell)
3. Access `journalctl` logs without `adm` group membership

This caused repeated failed attempts and wasted diagnostic time.

### Context

During GX10 installation, the following operations all failed from Claude Code:
- `sudo usermod -aG docker holee`
- `sudo apt install gh`
- `curl -fsSL https://ollama.com/install.sh | sudo sh`
- `sudo systemctl restart ollama`
- `sudo journalctl -u ollama`

---

## Root Cause Analysis

### Immediate Cause

Claude Code runs in a sandboxed shell without TTY, so `sudo` cannot prompt for password.

### Underlying Causes

1. **No upfront separation of privileged tasks**: The installation plan mixed sudo and non-sudo operations.
2. **Session state not refreshable**: Group membership changes require re-login, which Claude Code cannot trigger.

---

## Solution Implemented

### Strategy: Phase 0 Pattern

Created `00-sudo-prereqs.sh` that bundles ALL privileged operations into a single script the user runs manually. All subsequent phases are sudo-free.

### Key Principle

**Never assume Claude Code can run sudo.** All privileged operations must be:
1. Pre-executed by the user via a consolidated script
2. OR clearly documented as manual steps with copy-paste commands

---

## Prevention Strategies

### Process Rules for AI Agents

1. **NEVER attempt `sudo` from Claude Code** — it will always fail
2. **NEVER attempt `systemctl` commands** — they require sudo or polkit
3. **Group changes** (`usermod -aG`) require session restart — plan for this
4. **journalctl** may require `adm` group — use alternative log sources when possible
5. **Always consolidate sudo operations** into a single user-executable script
6. **After user runs sudo script**, verify results with non-sudo commands (e.g., `curl`, `groups`, `ls -la`)

### Diagnostic Alternatives (no sudo required)

| Need | Instead of (requires sudo) | Use (no sudo) |
|------|---------------------------|---------------|
| Service status | `systemctl status X` | `curl` the service endpoint |
| Service logs | `journalctl -u X` | `cat /var/log/X.log` or ask user |
| Process check | `systemctl is-active X` | `ps aux \| grep X` |
| Port check | `ss -tlnp` (may need sudo) | `curl localhost:PORT` |
| Directory permissions | `sudo ls -la` | `ls -la` (works if readable) |
| Docker commands | `docker ps` (needs group) | Ask user to verify |

---

## Prevention Rule (for AI agents)

**RULE**: Before executing ANY command, check if it needs elevated privileges:
1. Does it start with `sudo`? → Delegate to user
2. Does it use `systemctl`? → Delegate to user
3. Does it modify `/etc/`? → Delegate to user
4. Does it need docker group? → Verify `groups` output first
5. Package the privileged commands into a script for the user to run

---

## References

- Script: `scripts/install/00-sudo-prereqs.sh`
- Commits: `641e041`, `987ecf5`
