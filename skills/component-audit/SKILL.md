---
name: component-audit
description: Find reusable components with compact output before UI work
---

# Skill: component-audit

**Trigger**: `/component-audit` or auto-called before UI work
**Purpose**: Surface the most relevant reusable components without loading unnecessary context.

---

## Workflow

```text
1. component-auditor -> scan likely component directories
2. Return up to 3 reuse candidates
3. Optionally suggest refactor-architect if patterns repeat 3+ times
```

---

## Constraints

- Read-only
- Keep the result compact enough to paste into a handoff block
- Route `grep`/`rg`/`find`/`ls` calls through `bash hooks/rtk-wrap.sh <cmd> ...` (see `CLAUDE.md → RTK Wrapping`)
