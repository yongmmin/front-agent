---
name: match-style
description: Implement new UI matching existing product style when no Figma design is available
---

# Skill: match-style

**Trigger**: `/match-style [description]`
**Purpose**: Implement new UI without a Figma design, matching the existing product's visual style.

---

## Activation

User types: `/match-style [what to build]`
Use when: No Figma design is available.

---

## Workflow

```
Step 1: component-auditor (haiku)
  → Find reusable components

Step 2: style-matcher (sonnet)
  → Scan existing pages/components
  → Extract design language
  → Implement matching UI with responsive layout

Step 3: a11y-check (sonnet)
  → Accessibility verification

Step 4: reviewer (opus)
  → Code review

Step 5: git-branch → git-commit → git-pr
  → Branch: ui/[component-name]
```

---

## Constraints

- Must analyze at least 3 existing components before implementing
- Must include responsive breakpoints
- Document extracted patterns in code comments