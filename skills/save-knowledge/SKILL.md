---
name: save-knowledge
description: Save learnings, decisions, and component info to the knowledge base
---

# Skill: save-knowledge

**Trigger**: `/save-knowledge [topic]` or auto-called after task completion
**Purpose**: Save learnings, decisions, and component info to the knowledge base.

---

## Activation

- Auto: called by orchestrator after feature/refactor completion
- Manual: `/save-knowledge [what to save]`

---

## Workflow

1. Determine knowledge type: component / pattern / feature / issue / design-system
2. Select or create target file
3. Append entry (never exceed 300 lines per file)
4. If file would exceed 300 lines → create domain sub-file and link from index.md
5. Update `knowledge/index.md` if needed

---

## Knowledge Types & Target Files

| Type | File |
|------|------|
| New component | `knowledge/components.md` |
| Code pattern | `knowledge/patterns.md` |
| Design rule | `knowledge/design-system.md` |
| Feature summary | `knowledge/features/[name].md` |
| Bug/issue | `knowledge/issues/[name].md` |

---

## Entry Format

### Component Entry
```markdown
## [ComponentName]
- **File**: `path/to/Component.tsx`
- **Props**: [list]
- **Use when**: [description]
- **Added**: [date]
```

### Pattern Entry
```markdown
## [Pattern Name]
**Problem**: [what problem it solves]
**Solution**: [the pattern]
**Example**: `path/to/example.tsx`
```

---

## 300-Line Rule

If target file exceeds 300 lines after addition:
1. Split into `knowledge/[domain]/[subtopic].md`
2. Replace content in original file with a link: `→ See [subtopic.md](./[domain]/[subtopic].md)`
3. Update `knowledge/index.md`

---

## Constraints

- Never exceed 300 lines in any knowledge file
- Always update index.md when creating new domain files