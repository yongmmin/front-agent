---
name: setup
description: Initialize the Frontend Co-Pilot plugin for a new project
---

# Skill: setup

**Trigger**: `/setup`
**Purpose**: Initialize the Frontend Co-Pilot plugin for a new project.

---

## Activation

User types: `/setup`
Run this once when starting a new project with this plugin.

---

## Workflow

```
Step 1: Detect project stack
  → Check package.json for: Next.js, React, TypeScript, Tailwind, test framework

Step 2: Initialize knowledge base
  → Create/update knowledge/index.md with project info
  → Create knowledge/components.md (empty template)
  → Create knowledge/design-system.md (empty template)
  → Create knowledge/patterns.md (empty template)

Step 3: Scan existing components
  → Run component-auditor
  → Populate knowledge/components.md with existing components

Step 4: Detect design system
  → Check for Tailwind config, CSS variables, design tokens
  → Populate knowledge/design-system.md

Step 5: Verify GitHub connection
  → Run: gh auth status
  → Check: git remote -v

Step 6: Report setup summary
```

---

## Setup Summary Output

```
## Frontend Co-Pilot Setup Complete ✓

### Project
- Framework: Next.js 14 (App Router)
- Language: TypeScript
- Styling: Tailwind CSS
- Tests: Vitest + React Testing Library

### Knowledge Base
- components.md: 12 components cataloged
- design-system.md: Tailwind config detected

### GitHub
- Connected: github.com/[user]/[repo]
- Default branch: main

### Ready
- Figma MCP: ✓ connected
- gh CLI: ✓ authenticated

Use /plan-feature to start your first task.
```

---

## Constraints

- Does not modify any source code
- Only reads and initializes knowledge files