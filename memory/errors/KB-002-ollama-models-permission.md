# KB-002: Ollama Models Directory Permission Denied

## Metadata

**Date**: 2026-02-03
**Author**: MoAI
**Category**: code-error
**Severity**: critical
**Status**: resolved

## Tags

`severity: critical`
`type: code`
`status: resolved`
`recurrence: first-time`
`component: 00-sudo-prereqs.sh, ollama-service`

---

## Problem Description

### What Happened?

After running `00-sudo-prereqs.sh`, Ollama service entered a crash loop (`activating (auto-restart)`, restart counter reached 521). The error was:

```
Error: mkdir /gx10/brains/code/models/blobs: permission denied: ensure path elements are traversable
```

### When Did It Happen?

2026-02-03, immediately after Phase 0 execution and `systemctl restart ollama`.

### Context

The `00-sudo-prereqs.sh` script created `/gx10` directory structure and set `OLLAMA_MODELS=/gx10/brains/code/models` in the systemd override. However, the script then ran `chown -R holee:holee /gx10`, making the models directory owned by `holee`, while Ollama service runs as the `ollama` system user.

---

## Root Cause Analysis

### Immediate Cause

Ollama service (`User=ollama`) could not write to `/gx10/brains/code/models` because the directory was owned by `holee:holee`.

### Underlying Causes

1. **Service user mismatch**: Ollama installs with its own system user (`ollama`), but the script assumed the actual user would need ownership of all directories.
2. **Blanket chown**: `chown -R holee:holee /gx10` applied ownership recursively without considering service-specific directories.

### Why Wasn't It Caught?

- The script did not verify Ollama service health after `systemctl restart ollama`.
- No post-restart validation step (e.g., `curl http://localhost:11434/api/version`).

---

## Impact Assessment

### Technical Impact

- [x] System downtime: Ollama service in crash loop (~30 minutes until diagnosed)
- [x] Broken functionality: AI model download impossible without running Ollama

---

## Solution Implemented

### Immediate Fix

```bash
sudo chown -R ollama:ollama /gx10/brains/code/models
sudo systemctl restart ollama
```

### Long-term Fix

Updated `00-sudo-prereqs.sh` Section 3 to add:
```bash
# After general chown to actual user
chown -R ollama:ollama /gx10/brains/code/models
```

### Verification

```bash
ollama list          # Responded with empty model list (OK)
curl http://localhost:11434/api/version  # {"version":"0.15.4"}
```

**Commit**: `987ecf5`

---

## Prevention Strategies

### Script Changes

1. Always check the runtime user of a service (`grep User= <service-file>`) before assigning directory ownership
2. Add health-check validation after service restart in installation scripts
3. When using `OLLAMA_MODELS` custom path, always ensure the `ollama` user has write access

### Checklist for Future Scripts

- [ ] After `chown` on shared directories, verify service-specific subdirectories have correct ownership
- [ ] After `systemctl restart <service>`, wait and verify the service is healthy
- [ ] Log service user vs directory owner mismatches as warnings

---

## Prevention Rule (for AI agents)

**RULE**: When a systemd service writes to a custom directory path:
1. Identify the service's `User=` from the unit file
2. Ensure that user has write permission to the target directory
3. Apply targeted `chown` AFTER any blanket ownership changes
4. Validate service health after restart (`curl`, `systemctl is-active`, etc.)

---

## References

- Commit: `987ecf5` (fix: grant ollama user ownership of models directory)
- File: `scripts/install/00-sudo-prereqs.sh` (Section 3)
- Related: `KB-001-kv-cache-inconsistent.md`
