# KB-007: error-handler.sh Phase Number Parsing Failure

## Error Information

- **Severity**: CRITICAL
- **Category**: Syntax / Script Failure
- **Date**: 2026-02-03
- **Component**: lib/error-handler.sh (line 77)
- **Status**: RESOLVED

## Symptom

```
$ ./01-code-models-download.sh
lib/error-handler.sh: 줄 77: 10#phase: 해당 진법에서 표현할 수 없는 값
```

## Root Cause

`checkpoint()` function expected phase_name format `"01-code-models"` but actual call is `checkpoint "phase-01" "..."`.

```bash
# Code expected: "01-code-models" → %%-* → "01" → $((10#01)) → 1
# Actual input:  "phase-01"      → %%-* → "phase" → $((10#phase)) → ERROR
```

`${phase_name%%-*}` removes from the FIRST `-` to the end, so `"phase-01"` → `"phase"` (not a number).

## Fix Applied

```bash
# Use ##*- (remove up to LAST -) instead of %%-* (remove from FIRST -)
local phase_num="${phase_name##*-}"
# Validate it's a number before arithmetic
if [[ "$phase_num" =~ ^[0-9]+$ ]]; then
    phase_num=$((10#$phase_num))
else
    phase_num=$(echo "$phase_name" | grep -oE '[0-9]+' | head -1)
    phase_num=${phase_num:-0}
fi
```

## Prevention Rules

1. **[HARD]** Test lib functions with actual calling patterns, not assumed patterns
2. **[HARD]** Validate string-to-number conversions before `$((...))` arithmetic
3. **[CHECK]** When scripts call lib functions, verify the argument format matches what the lib expects
4. **[CHECK]** Bash parameter expansion: `%%-*` (greedy from end) vs `##*-` (greedy from start)

## Bash Parameter Expansion Reference

| Pattern | Input | Result | Description |
|---------|-------|--------|-------------|
| `${x%%-*}` | `phase-01` | `phase` | Remove from first `-` to end |
| `${x##*-}` | `phase-01` | `01` | Remove from start to last `-` |
| `${x%-*}` | `a-b-c` | `a-b` | Remove shortest match from end |
| `${x#*-}` | `a-b-c` | `b-c` | Remove shortest match from start |

## Related

- [KB-006: security.sh syntax error](KB-006-security-sh-syntax-error.md)
- Script: `scripts/install/lib/error-handler.sh`
- Caller: All scripts via `checkpoint "phase-$PHASE" "..."`
