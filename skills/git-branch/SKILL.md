---
name: git-branch
description: Create a Git branch following naming conventions based on task type
---

# Skill: git-branch

**Trigger**: called by orchestrator after plan.md approval
**Purpose**: Create a Git branch following naming conventions based on task type.

---

## Branch Naming Convention

| Task Type | Pattern | Example |
|-----------|---------|---------|
| Feature | `feat/[name]` | `feat/product-filter` |
| Bug fix | `fix/[name]` | `fix/cart-total-error` |
| Refactor | `refactor/[target]` | `refactor/product-card` |
| Redesign | `redesign/[component]` | `redesign/nav-mobile` |
| UI implementation | `ui/[component]` | `ui/product-card` |

---

## Workflow

1. Read task type and name from `plan.md`
2. Check if branch already exists
3. Create branch from latest `main` (or `develop` if it exists)
4. Switch to new branch

```bash
git checkout main
git pull origin main
git checkout -b [branch-name]
```

---

## Constraints

- Always branch from latest main
- Never create branches with spaces — use hyphens
- Branch name must be lowercase