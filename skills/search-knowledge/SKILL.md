---
name: search-knowledge
description: Search the knowledge base for relevant information
---

# Skill: search-knowledge

**Trigger**: `/search-knowledge [query]` or auto-called by agents needing context
**Purpose**: Search the knowledge base for relevant information.

---

## Activation

- Manual: `/search-knowledge [query]`
- Auto: called by orchestrator when loading context for a task

---

## Workflow

1. Load `knowledge/index.md`
2. Search index for matching topics
3. Load relevant domain files
4. Return matched content

---

## Search Priority

1. `knowledge/index.md` — always loaded
2. `knowledge/components.md` — for UI/component queries
3. `knowledge/patterns.md` — for code pattern queries
4. `knowledge/design-system.md` — for style/design queries
5. `knowledge/features/` — for feature-specific queries
6. `knowledge/issues/` — for bug/issue queries

---

## Output Format

```
## Knowledge Search: "[query]"

### Found in: knowledge/components.md
[relevant excerpt]

### Found in: knowledge/patterns.md
[relevant excerpt]

### Not found
[topics not in knowledge base]
```

---

## Constraints

- Load only relevant files (not all files)
- Use haiku model for search — read-only, no modifications