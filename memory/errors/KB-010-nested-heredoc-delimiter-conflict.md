# KB-010: Nested Heredoc Delimiter Conflict

## Error Summary
- **Date**: 2026-02-03
- **Phase**: Phase 3 (Brain Switch API)
- **Severity**: Critical
- **Status**: Resolved

## Error Message
```
./03-brain-switch-api.sh: 줄 274: CURRENT: 바인딩 해제한 변수
```

## Root Cause
Nested heredoc delimiter conflict in `03-brain-switch-api.sh`:

1. Outer heredoc (line 152): `cat > /gx10/api/switch.sh << 'EOF'`
2. Inner heredoc (line 262): `cat > "$STATUS_FILE" << EOF`
3. Inner heredoc closing `EOF` (line 271) was interpreted as the **outer** heredoc closing

This caused lines 273-289 to be executed as part of `03-brain-switch-api.sh` instead of being written to `switch.sh`. Since `$CURRENT` variable doesn't exist in the parent script context, `set -u` raised an unbound variable error.

## Affected Files
- `scripts/install/03-brain-switch-api.sh`

## Solution Applied
Changed inner heredoc delimiter from `EOF` to `BRAIN_JSON`:
```bash
# Before
cat > "$STATUS_FILE" << EOF
...
EOF

# After
cat > "$STATUS_FILE" << BRAIN_JSON
...
BRAIN_JSON
```

Also escaped `${FROM_TO}` in jq command to prevent shell expansion:
```bash
jq ".statistics.\${FROM_TO} += 1"
```

## Prevention Rules
1. **Use unique heredoc delimiters** when nesting heredocs
2. **Common pattern**: Use descriptive delimiters (e.g., `BRAIN_JSON`, `CONFIG_DATA`, `SCRIPT_CONTENT`)
3. **Never use `EOF` for nested heredocs** — reserve `EOF` for outermost heredoc only
4. **Test script generation scripts** by checking generated file contents match expected output

## bash -n Limitation
`bash -n` does NOT detect this error because:
- The syntax is technically valid
- The issue is semantic (wrong delimiter matching), not syntactic
- Only runtime execution reveals the problem

## Related KBs
- KB-008: lib runtime errors under set -u
