# KB-004: Remaining sudo Calls in Active Scripts (Post Phase 0)

## Metadata

**Date**: 2026-02-03
**Author**: MoAI
**Category**: code-error
**Severity**: high
**Status**: investigating

## Tags

`severity: high`
`type: code`
`status: investigating`
`recurrence: first-time`
`component: 07-brain-switch-api.sh, 10-final-validation.sh`

---

## Problem Description

### What Happened?

Final audit discovered that `07-brain-switch-api.sh` and `10-final-validation.sh` still contain `sudo` calls, contradicting the Phase 0 pattern where all sudo operations are consolidated upfront.

### Affected Files

**07-brain-switch-api.sh** (installation-time sudo):
- Line 400: `sudo tee /usr/local/bin/gx10-brain-switch` — writes to /usr/local/bin
- Line 404: `sudo chmod +x /usr/local/bin/gx10-brain-switch`

**07-brain-switch-api.sh** (runtime sudo in generated switch.sh):
- Line 197: `echo 3 | sudo tee /proc/sys/vm/drop_caches` — cache flush
- Line 204: `sudo systemctl stop ollama` — stop service
- Line 223: `sudo systemctl start ollama` — start service

**10-final-validation.sh** (runtime sudo):
- Line 113: `sudo /gx10/api/switch.sh vision` — brain switch test
- Line 119: `sudo /gx10/api/switch.sh code` — switch back

### Analysis

Two categories of sudo usage:

1. **Installation-time sudo** (07 lines 400,404): Writing to /usr/local/bin requires sudo.
   - **Fix**: Move this to 00-sudo-prereqs.sh OR skip the global wrapper

2. **Runtime sudo** (switch.sh, validation): Brain switching requires systemctl and cache flush.
   - **Fix**: This is EXPECTED — brain switching inherently needs elevated privileges
   - **Alternative**: Add sudoers entry for ollama control without password

---

## Impact on 2nd GX10 Deployment

- `00-install-all.sh` runs scripts WITHOUT sudo
- `07-brain-switch-api.sh` will FAIL at line 400 (sudo tee)
- `10-final-validation.sh` will FAIL at line 113 (sudo switch)

---

## Recommended Fixes

### Fix 1: Move /usr/local/bin write to Phase 0
Add to `00-sudo-prereqs.sh`:
```bash
# Create brain-switch wrapper placeholder
tee /usr/local/bin/gx10-brain-switch > /dev/null << 'EOF'
#!/bin/bash
/gx10/api/switch.sh "$@"
EOF
chmod +x /usr/local/bin/gx10-brain-switch
```
Then remove lines 398-404 from `07-brain-switch-api.sh`.

### Fix 2: Remove sudo from switch.sh generated script
Use sudoers for passwordless ollama control:
Add to `00-sudo-prereqs.sh`:
```bash
echo "$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop ollama, /usr/bin/systemctl start ollama, /usr/bin/systemctl restart ollama, /usr/bin/tee /proc/sys/vm/drop_caches" | tee /etc/sudoers.d/gx10-brain-switch
chmod 440 /etc/sudoers.d/gx10-brain-switch
```

### Fix 3: Skip brain switch test in validation if no sudo
Make `10-final-validation.sh` detect sudo availability and skip switch test gracefully.

---

## References

- Related: KB-003 (sudo session limitations)
- Script: `scripts/install/07-brain-switch-api.sh`
- Script: `scripts/install/10-final-validation.sh`
