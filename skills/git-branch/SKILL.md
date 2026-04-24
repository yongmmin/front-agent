---
name: git-branch
description: Create a task branch after plan approval
---

# Skill: git-branch

**Trigger**: called by `front-agent` after plan approval
**Purpose**: Create a task branch with the project's naming rules.

---

## Rules

- Feature: `feat/[name]`
- Bug fix: `fix/[name]`
- Refactor: `refactor/[target]`
- Redesign: `redesign/[component]`
- UI: `ui/[component]`

---

## Constraints

- Use lowercase
- Use hyphens, not spaces
- Start from the current integration branch
- Route `git` calls through `bash hooks/rtk-wrap.sh git ...` (see `CLAUDE.md → RTK Wrapping`)
