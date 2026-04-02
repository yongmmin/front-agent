---
name: save-knowledge
description: Save learnings, decisions, and component info to the knowledge base and global wisdom hub
---

# Skill: save-knowledge

**Trigger**: `/save-knowledge [topic]` or auto-called after task completion
**Purpose**: Save learnings to the project `knowledge/` and global wisdom hub (`~/.front-agent/wisdom/`).

---

## Storage Location

| Content Type | Storage Location |
|-------------|-----------------|
| Components, patterns, design rules | `knowledge/` (project-scoped) |
| Learnings | `~/.front-agent/wisdom/learnings.md` + update summary |
| Decisions | `~/.front-agent/wisdom/decisions.md` + update summary |
| Known issues | `~/.front-agent/wisdom/issues.md` + update summary |

---

## Workflow

1. Determine the type of content to save
2. Append entry to the appropriate file
3. Update `~/.front-agent/wisdom/summary.md` (keep under 20 lines)
   - If over limit: delete the oldest entry before adding the new one

---

## Entry Format

### Learnings
```
- [YYYY-MM-DD] [project-name] content
```

### Decisions
```
- [YYYY-MM-DD] [project-name] decision — reason
```

### Issues
```
- [YYYY-MM-DD] [project-name] problem — solution or warning
```

### summary.md Update Format
```markdown
# Wisdom Summary
> 20-line limit.

## Learnings
- [keep latest 3 only]

## Decisions
- [keep latest 3 only]

## Issues
- [keep latest 3 only]
```

---

## Project knowledge/ Storage (components/patterns/design)

| Type | File |
|------|------|
| Components | `knowledge/components.md` |
| Code patterns | `knowledge/patterns.md` |
| Design rules | `knowledge/design-system.md` |

If over 300 lines, split into domain sub-files and link from index.md.

---

## Constraints

- summary.md must never exceed 20 lines
- learnings/decisions/issues.md have a 300-line limit
- Always include the project name in each entry for traceability
