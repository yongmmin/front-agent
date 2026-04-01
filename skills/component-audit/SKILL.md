---
name: component-audit
description: Audit existing components and update knowledge base
---

# Skill: component-audit

**Trigger**: `/component-audit` or auto-called before any UI work
**Purpose**: Audit existing components and update knowledge/components.md.

---

## Activation

- Manual: `/component-audit`
- Auto: called by orchestrator before UI work

---

## Workflow

```
Step 1: component-auditor (haiku)
  → Scan all component directories
  → Catalog: name, file path, props, variants

Step 2: Cross-reference with knowledge/components.md
  → Identify new components not yet documented
  → Identify documented components that were removed

Step 3: Update knowledge/components.md
  → Add new entries
  → Mark removed components

Step 4: Report to orchestrator
  → Reusable components for current task
  → Pattern alerts (3+)
```

---

## knowledge/components.md Entry Format

```markdown
## [ComponentName]
- **File**: `components/ui/ComponentName.tsx`
- **Props**: variant, size, className, children
- **Variants**: primary, secondary, ghost
- **Use when**: [description]
```

---

## Constraints

- Read only during scan phase
- Update knowledge/components.md after scan