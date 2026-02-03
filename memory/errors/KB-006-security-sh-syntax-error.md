# KB-006: security.sh Bash Syntax Error in Regex

## Error Information

- **Severity**: CRITICAL
- **Category**: Syntax / Script Failure
- **Date**: 2026-02-03
- **Component**: lib/security.sh (line 373)
- **Status**: RESOLVED

## Symptom

```
$ ./01-code-models-download.sh
lib/security.sh: 줄 373: 조건 표현식에 문법 오류: 예상치 못한 토큰 `&'
```

All scripts that `source lib/security.sh` fail immediately at load time.

## Root Cause

```bash
# WRONG: &, * are regex metacharacters inside [[ =~ ]]
[[ "$password" =~ [!@#$%^&*] ]] && ((score++))
```

In Bash `[[ ... =~ ... ]]`, the regex character class `[!@#$%^&*]` is invalid because:
- `&` is not a valid regex metacharacter inside `[]` without escaping
- `*` is a regex quantifier

Bash's `=~` uses POSIX Extended Regular Expressions, not glob patterns.

## Fix Applied

```bash
# CORRECT: match any non-alphanumeric character (special chars)
[[ "$password" =~ [^a-zA-Z0-9] ]] && ((score++))
```

This achieves the same goal (detect special characters) using a valid regex negation pattern.

## Prevention Rules

1. **[HARD]** Always run `bash -n script.sh` syntax check before committing any .sh file
2. **[HARD]** In `[[ =~ ]]` regex, avoid raw special chars (`&`, `*`, `(`, `)`) in character classes
3. **[CHECK]** After any lib/ change, run: `for f in lib/*.sh; do bash -n "$f"; done`
4. **[CHECK]** After any script change, run: `for f in 0*.sh; do bash -n "$f"; done`

## Lesson Learned

- Code review and document consistency checks do NOT catch shell syntax errors
- `bash -n` (syntax check) should be a mandatory pre-commit step for all .sh files
- lib/ files affect ALL scripts — a single lib error breaks the entire installation

## Related

- Script: `scripts/install/lib/security.sh`
- Affected: All 5 active scripts (01-05) that source security.sh
