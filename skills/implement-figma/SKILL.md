---
name: implement-figma
description: Implement a Figma design with the merged ui-builder flow
---

# Skill: implement-figma

**Trigger**: `/implement-figma [figma-url]`
**Model**: sonnet
**Purpose**: Build production-ready UI from Figma with compact verification steps.

---

## Workflow

```text
1. Parse Figma URL
2. component-auditor
3. ui-builder
4. pixel-check
5. a11y-check
6. reviewer
7. git-branch -> git-commit -> git-pr
```

---

## Constraints

- Use existing components when possible
- Keep responsive behavior mobile-first
- Prefer project tokens over raw Figma values
