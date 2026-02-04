# Memory Management Rules

## Purpose

This rule ensures that all work is tracked in the memory system to prevent repeated mistakes and enable work resumption after unexpected interruptions.

---

## HARD Rules (Mandatory)

### Rule 1: Pre-Execution Memory Check

Before starting any task execution, MUST perform these checks:

1. **Check memory/errors/** for related KB entries
   ```bash
   grep -r "keyword" memory/errors/
   ```

2. **Review recent KB entries** for patterns that may apply
   - Last 5 KB entries should be scanned
   - Check if similar work has encountered issues before

3. **Document in memory/tasks/** before execution
   - Create task record using template
   - Include objective, scope, and expected outcome

### Rule 2: Task Registration Before Execution

**Before ANY significant task:**

1. Create task file in `memory/tasks/TASK-YYYY-MMDD-NNN.md`
2. Use template from `memory/templates/task-record-template.md`
3. Fill in:
   - Task ID and timestamp
   - Objective and scope
   - Files to be modified
   - Execution plan

**Task Naming Convention:**
- `TASK-2026-0204-001.md` (first task on 2026-02-04)
- `TASK-2026-0204-002.md` (second task on same day)

### Rule 3: Error/Failure Registration

**When ANY error or failure occurs:**

1. **Immediately** create KB entry in `memory/errors/`
2. Use template from `memory/templates/error-record-template.md`
3. Include:
   - Problem description
   - Root cause analysis
   - Solution implemented
   - Prevention strategies

**KB Naming Convention:**
- `KB-NNN-short-description.md`
- Next available number (check existing entries)

### Rule 4: Task Completion Update

**When task completes (success or failure):**

1. Update task file with:
   - Status: completed/failed/cancelled
   - Result summary
   - Commit references
   - Issues encountered

2. If errors occurred:
   - Reference KB entries created
   - Link to memory/errors/ files

---

## Workflow Integration

### Pre-Task Checklist

```
□ Check memory/errors/ for related issues
□ Create task record in memory/tasks/
□ Document execution plan
□ Identify potential risks from past KB entries
```

### During Task

```
□ Log progress in task file
□ If error occurs: create KB entry immediately
□ Update task status as work progresses
```

### Post-Task

```
□ Update task file with completion status
□ Create KB entry if new issues discovered
□ Link related commits and PRs
```

---

## Memory Directory Structure

```
memory/
├── README.md                 # System documentation
├── tasks/                    # Active and completed task records
│   └── TASK-YYYY-MMDD-NNN.md
├── errors/                   # Knowledge Base entries
│   └── KB-NNN-description.md
├── lessons-learned/          # Process improvement notes
├── templates/                # Document templates
│   ├── task-record-template.md
│   ├── error-record-template.md
│   └── quick-note-template.md
└── auto-detected/            # Automated detection results
```

---

## Quick Reference Commands

### Check for related KB entries

```bash
# Search by keyword
grep -ri "keyword" memory/errors/

# List all KB entries
ls -la memory/errors/

# Find most recent KB
ls -lt memory/errors/ | head -5
```

### Create new task

```bash
# Get next task number
ls memory/tasks/TASK-$(date +%Y-%m%d)*.md 2>/dev/null | wc -l

# Copy template
cp memory/templates/task-record-template.md memory/tasks/TASK-$(date +%Y-%m%d)-001.md
```

### Create new KB entry

```bash
# Find next KB number
ls memory/errors/ | grep -oP 'KB-\K\d+' | sort -n | tail -1

# Copy template
cp memory/templates/error-record-template.md memory/errors/KB-NNN-description.md
```

---

## Session Recovery

### After Unexpected Termination

1. Check `memory/tasks/` for incomplete tasks:
   ```bash
   grep -l "Status: in-progress" memory/tasks/*.md
   ```

2. Review last task file for:
   - Completed steps
   - Pending steps
   - Last progress log entry

3. Resume from last known state

### Memory Sync Commands

```bash
# Check pending tasks
grep -l "pending\|in-progress" memory/tasks/*.md

# Check recent errors
ls -lt memory/errors/ | head -10
```

---

## Enforcement

This rule is enforced through:

1. **CLAUDE.md reference** - Loaded at session start
2. **Pre-task validation** - Check before execution
3. **Post-task review** - Verify completion and KB updates

**Non-compliance results in:**
- Potential repeated errors
- Loss of work on session termination
- Incomplete documentation

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-02-04 | Initial version |

---

**Author**: MoAI
**Created**: 2026-02-04
**Purpose**: Work tracking and error prevention
