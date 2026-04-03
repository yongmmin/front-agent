---
name: code-review
description: Run a compact PASS/FAIL review using the reviewer agent
---

# Skill: code-review

**Trigger**: `/code-review` or auto-called after implementation
**Purpose**: Produce a compact PASS/FAIL review with actionable findings.

---

## Workflow

```text
1. reviewer -> inspect changed files
2. On FAIL -> return compact fix list
3. On PASS -> allow git-commit
```

---

## Review Scope

- TypeScript correctness
- React/Next.js correctness
- Security and secrets
- Loading, empty, and error states
- Regressions and duplicated patterns

---

## Constraints

- Use `reviewer` only
- Keep output concise and actionable
