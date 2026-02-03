# KB-008: lib/ Runtime Errors Under set -u (Unbound Variables)

## Error Information

- **Severity**: CRITICAL
- **Category**: Runtime / Function Signature Mismatch
- **Date**: 2026-02-03
- **Component**: lib/logger.sh, lib/state-manager.sh
- **Status**: RESOLVED

## Symptom

```
$ ./01-code-models-download.sh
lib/logger.sh: 줄 44: $2: 바인딩 해제한 변수
```

## Root Cause

Three compounding factors:

1. **`set -u` in all scripts**: Unset variables cause immediate fatal error
2. **`log()` required 2 args**: `log(level, message)` — but ALL 52 call sites use `log "message"` (1 arg)
3. **`bash -n` does NOT catch this**: Syntax check passes, runtime fails

Also found: `state-manager.sh` `reset_state()` used `${2:-no}` instead of `${1:-no}`.

## Fixes Applied

### logger.sh — log() accepts 1 or 2 args
```bash
# Before: always required 2 args
log() {
    local level="$1"      # OK
    local message="$2"    # CRASH under set -u if only 1 arg
}

# After: detect arg count
log() {
    local level message
    if [ $# -ge 2 ]; then
        level="$1"
        message="$2"
    else
        level="INFO"
        message="$1"
    fi
}
```

### state-manager.sh — reset_state() parameter index
```bash
# Before: wrong parameter index
local confirm="${2:-no}"

# After: correct parameter index
local confirm="${1:-no}"
```

## Prevention Rules

1. **[HARD]** All lib functions MUST use `${N:-default}` for optional parameters under `set -u`
2. **[HARD]** Before committing lib changes, test with: `bash -c 'set -eu; source lib/X.sh; function_call "args"'`
3. **[HARD]** `bash -n` is NOT sufficient — always do runtime smoke tests for lib functions
4. **[CHECK]** For every function, verify: actual call sites match the expected signature
5. **[CHECK]** Pre-commit validation: `bash -n` + runtime test under `set -eu`

## Validation Command

```bash
# Run this before every commit touching .sh files:
bash -c '
set -eu
source lib/logger.sh
source lib/state-manager.sh
source lib/error-handler.sh
source lib/security.sh
log "single arg test"
log "INFO" "two arg test"
echo "ALL PASSED"
'
```

## Related

- [KB-006: security.sh syntax error](KB-006-security-sh-syntax-error.md)
- [KB-007: error-handler.sh phase parsing](KB-007-error-handler-phase-parsing.md)
