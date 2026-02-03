# KB-013: Docker Container Name Conflict on Reinstall

## Issue

When running `04-webui-install.sh` a second time (reinstallation), the script fails with:

```
docker: Error response from daemon: Conflict. The container name "/open-webui" is already in use by container "abc123...". You have to remove (or rename) that container to be able to reuse that name.
```

## Root Cause

The `docker run --name open-webui` command cannot create a container with a name that already exists, even if the existing container is stopped.

## Solution

Add container removal before `docker run`:

```bash
# Remove existing container if present (idempotent reinstall)
docker rm -f open-webui 2>/dev/null || true

docker run -d \
  --name open-webui \
  ...
```

## Affected Scripts

| Script | Status | Fix Applied |
|--------|--------|-------------|
| 04-webui-install.sh | ✅ Fixed | v2.2.0 |
| 03-brain-switch-api.sh | ✅ Already Safe | switch.sh has `docker rm -f` |
| 02-vision-brain-build.sh | ✅ Already Safe | Docker build overwrites |

## Idempotency Review Summary

All Phase 0-5 scripts are now reinstall-safe:

| Phase | Script | Idempotent | Notes |
|-------|--------|------------|-------|
| 0 | 00-sudo-prereqs.sh | ✅ | `mkdir -p`, `apt install` are idempotent |
| 1 | 01-code-models-download.sh | ✅ | Ollama skips existing models |
| 2 | 02-vision-brain-build.sh | ✅ | Docker build overwrites |
| 3 | 03-brain-switch-api.sh | ✅ | `cat >` overwrites, switch.sh has `docker rm -f` |
| 4 | 04-webui-install.sh | ✅ | Fixed: Added `docker rm -f open-webui` |
| 5 | 05-final-validation.sh | ✅ | Validation only, no resource conflicts |

## Prevention

When creating Docker-based installation scripts:

1. Always remove existing container before `docker run --name`
2. Use `docker rm -f <name> 2>/dev/null || true` pattern
3. Consider using `docker compose` for multi-container orchestration

## Document Info

| Field | Value |
|-------|-------|
| **KB ID** | KB-013 |
| **Category** | Installation / Idempotency |
| **Severity** | Medium |
| **Status** | Resolved |
| **Created** | 2026-02-03 |
| **Script Version** | 04-webui-install.sh v2.2.0 |
