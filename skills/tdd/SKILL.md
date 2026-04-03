---
name: tdd
description: Run a compact RED -> GREEN -> REFACTOR cycle with the merged developer agent
---

# Skill: tdd

**Trigger**: `/tdd [feature description]`
**Model**: sonnet
**Purpose**: Execute a full TDD cycle with minimal agent fan-out.

---

## Workflow

```text
1. developer      -> RED + GREEN
2. test-runner    -> verify pass/fail
3. refactor-architect? -> only if real duplication or design debt appears
4. reviewer       -> final review
```

### RED

- Write tests first
- Confirm they fail for the intended reason

### GREEN

- Implement the smallest change that makes tests pass
- Hand off to `test-runner`

### REFACTOR

- Run only if there is meaningful duplication or design debt
- Re-run tests after refactor

---

## Constraints

- Never skip RED
- Never weaken tests to force GREEN
- Keep outputs compact; test evidence comes from `test-runner`
