---
name: implement-figma
description: Implement a Figma design into React code with responsive layout
---

# Skill: implement-figma

**Trigger**: `/implement-figma [figma-url]`
**Model**: sonnet
**Purpose**: Implement a Figma design into production-ready React code with responsive layout.

---

## Activation

User types: `/implement-figma https://figma.com/design/...`

---

## Workflow

```
Step 1: Parse Figma URL
  → Extract fileKey and nodeId from URL
  → node-id: convert "-" to ":" (e.g., 123-456 → 123:456)

Step 2: component-auditor (haiku)
  → Scan existing components before building new ones

Step 3: figma-builder (sonnet)
  → Call Figma MCP: get_design_context(fileKey, nodeId)
  → Implement component with Tailwind (or project CSS)
  → Mobile-first responsive: base → sm → md → lg

Step 4: pixel-check (sonnet)
  → Compare implementation screenshot vs Figma design
  → Flag significant deviations

Step 5: a11y-check (sonnet)
  → Verify semantic HTML, ARIA labels, keyboard navigation

Step 6: reviewer (opus)
  → Code quality review

Step 7: git-branch → git-commit → git-pr
  → Branch: ui/[component-name]
  → Commit: ui: implement [component-name] from Figma
```

---

## Figma URL Parsing

| URL Pattern | fileKey | nodeId |
|------------|---------|--------|
| `figma.com/design/:fileKey/...?node-id=:nodeId` | `:fileKey` | `:nodeId` (replace `-` with `:`) |
| `figma.com/design/:fileKey/branch/:branchKey/...` | `:branchKey` | from node-id param |

---

## Responsive Requirements

Every Figma implementation must include:
- **Mobile** (base): single column, stacked layout
- **Tablet** (md: 768px): adjusted grid/flex
- **Desktop** (lg: 1024px): full designed layout

---

## Constraints

- Never hardcode pixel values from Figma — use design tokens or Tailwind classes
- Never skip responsive breakpoints
- If Figma MCP is unavailable, use screenshot + manual analysis