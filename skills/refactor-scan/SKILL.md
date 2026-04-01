---
name: refactor-scan
description: Scan codebase for repeated patterns and produce a refactoring proposal
---

# Skill: refactor-scan

**Trigger**: `/refactor-scan` or auto-triggered when component-auditor detects 3+ similar patterns
**Purpose**: Scan codebase for repeated patterns and produce a refactoring proposal.

---

## Activation

- Manual: `/refactor-scan`
- Auto: component-auditor detects 3+ duplicate patterns

---

## Workflow

```
Step 1: refactor-architect (opus)
  → Full codebase scan for:
    - Duplicate JSX structures (3+ occurrences)
    - Repeated state patterns (loading/error/data)
    - Duplicate API call patterns
    - Repeated class strings / inline styles
    - Duplicate utility functions

Step 2: Produce refactor plan.md
  → List all detected patterns
  → Propose extraction targets (component/hook/utility)
  → Estimate impact (files affected, risk level)

Step 3: Present to user
  → "Refactor plan ready. Review plan.md to approve."

Step 4 (after approval): execute-feature
  → Implement the refactoring
```

---

## Output Format

```
## Refactor Scan Results

### High Priority (3+ occurrences)
1. loading/error/data state pattern — 5 files → extract: useAsyncData hook
2. Card layout pattern — 4 files → extract: BaseCard component

### Medium Priority
1. Filter + pagination pattern — 3 files → extract: useFilteredList hook

### Low Priority
1. formatDate utility — 2 files → extract: lib/utils.ts
```

---

## Constraints

- Scan only, no changes in this step
- Always produce plan.md before any refactoring