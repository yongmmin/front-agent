---
name: code-review
description: Run a thorough code review on changed files
---

# Skill: code-review

**Trigger**: `/code-review` or auto-called after implementation
**Purpose**: Run a thorough code review on changed files.

---

## Activation

- Manual: `/code-review [file or PR]`
- Auto: called by orchestrator after implementation

---

## Workflow

```
Step 1: reviewer (opus)
  → Read all changed files (git diff or specified files)
  → Run full review checklist
  → Issue PASS or FAIL verdict with specifics

Step 2 (on FAIL):
  → Return to implementer with fix list

Step 2 (on PASS):
  → Signal orchestrator to proceed to git-commit
```

---

## Review Scope

- TypeScript correctness (no `any`, proper types)
- React/Next.js best practices
- Security (no secrets, no XSS)
- Performance (re-renders, image optimization)
- Error and loading state handling
- Code duplication (suggest /refactor-scan if significant)

---

## Constraints

- reviewer (opus) must be used — do not use a lower model for review
- PASS/FAIL must be explicit