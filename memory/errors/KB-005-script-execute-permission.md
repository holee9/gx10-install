# KB-005: Script Execute Permission Missing

## Error Information

- **Severity**: HIGH
- **Category**: Permission / Deployment
- **Date**: 2026-02-03
- **Component**: All installation scripts (01-05, 00-install-all.sh)
- **Status**: RESOLVED

## Symptom

```
$ ./01-code-models-download.sh
bash: ./01-code-models-download.sh: Permission denied
```

User mistakenly thinks `sudo` is required, but the actual cause is missing execute permission (`chmod +x`).

## Root Cause

- `00-sudo-prereqs.sh` had execute permission (`-rwxrwxr-x`) because it was manually set
- All other scripts were committed with `-rw-rw-r--` (no execute bit)
- Git tracks execute permissions, so `git pull` on another GX10 will also lack execute bits
- After `git mv` (renumbering), permissions were preserved but were already wrong

## Fix Applied

```bash
chmod +x scripts/install/00-install-all.sh
chmod +x scripts/install/01-code-models-download.sh
chmod +x scripts/install/02-vision-brain-build.sh
chmod +x scripts/install/03-brain-switch-api.sh
chmod +x scripts/install/04-webui-install.sh
chmod +x scripts/install/05-final-validation.sh
chmod +x scripts/install/audit.sh
chmod +x scripts/install/lib/*.sh
```

Committed with `git add` — Git stores the execute bit, so `git pull` on 2nd GX10 will get correct permissions.

## Prevention Rules

1. **[HARD]** All `.sh` files MUST have execute permission before committing
2. **[HARD]** After creating or renaming any script, run `chmod +x` before `git add`
3. **[CHECK]** Verify with `ls -la *.sh | grep -v "^-rwx"` — should return empty
4. **[NEVER]** Never tell the user to use `sudo` to run Phase 1-5 scripts — if "Permission denied", check `chmod +x` first

## Lesson Learned

- "Permission denied" does NOT always mean sudo is needed
- Git preserves file permissions — fixing locally and pushing propagates to all clones
- Phase 0 is the ONLY script that requires sudo

## Related

- [KB-003: sudo session limitations](KB-003-sudo-session-limitations.md)
- [KB-004: remaining sudo in active scripts](KB-004-remaining-sudo-in-active-scripts.md)
