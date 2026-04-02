---
name: search-knowledge
description: Search the knowledge base and global wisdom hub for relevant information
---

# Skill: search-knowledge

**Trigger**: `/search-knowledge [query]` or auto-called by agents needing context
**Purpose**: Search project `knowledge/` and global wisdom hub (`~/.front-agent/wisdom/`) for relevant information.

---

## Search Priority

1. `~/.front-agent/wisdom/summary.md` — always load (20 lines, minimal tokens)
2. `knowledge/index.md` — project context
3. Load detail files on demand based on query:
   - Learnings → `~/.front-agent/wisdom/learnings.md`
   - Decisions → `~/.front-agent/wisdom/decisions.md`
   - Issues → `~/.front-agent/wisdom/issues.md`
   - Components → `knowledge/components.md`
   - Patterns → `knowledge/patterns.md`
   - Design → `knowledge/design-system.md`

**Core principle**: Load only what is needed. Do not load all files at once.

---

## Output Format

```
## Knowledge Search: "[query]"

### Wisdom (global)
[relevant entries from summary.md]

### Project Knowledge
[relevant entries from knowledge/index.md]

### Detail (on-demand loaded)
[excerpts from relevant detail files]
```

---

## Constraints

- Use haiku model (read-only, no modifications)
- Do not load files unrelated to the query
- If no results found, explicitly state "No relevant entries found"
