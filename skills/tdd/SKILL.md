---
name: tdd
description: Run a full TDD cycle: RED to GREEN to REFACTOR
---

# Skill: tdd

**Trigger**: `/tdd [feature description]`
**Model**: sonnet
**Purpose**: Run a full TDD cycle: RED → GREEN → REFACTOR.

---

## Activation

User types: `/tdd [what to implement]`

---

## TDD Cycle

### RED Phase — test-writer
1. Analyze feature requirements
2. Write test cases (do not implement yet)
3. Run tests — confirm all FAIL
4. Report: "RED phase complete. X tests failing."

### GREEN Phase — implementer
1. Write minimum code to make tests pass
2. Run tests via test-runner
3. Iterate until all tests pass
4. Report: "GREEN phase complete. All tests passing."

### REFACTOR Phase — refactor-architect (if needed)
1. Identify any code smell or duplication in new code
2. If refactor needed: produce plan.md → user review → implement
3. Run tests again to confirm still GREEN
4. Report: "REFACTOR phase complete."

---

## Workflow

```
test-writer (sonnet)    → RED: write failing tests
test-runner (sonnet)    → confirm tests fail
implementer (sonnet)    → GREEN: make tests pass
test-runner (sonnet)    → confirm tests pass
refactor-architect (opus) → REFACTOR: clean up if needed [optional]
reviewer (opus)         → final review
git-branch → git-commit → git-pr
```

---

## Output at each phase

```
🔴 RED: 5 tests written, 5 failing
🟢 GREEN: 5/5 tests passing
🔵 REFACTOR: extracted useProductList hook (no behavior change)
✅ TDD cycle complete
```

---

## Constraints

- Never skip the RED phase — tests must fail first
- Never modify tests to make them pass
- Refactor only when tests are GREEN