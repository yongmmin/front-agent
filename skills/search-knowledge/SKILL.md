---
name: search-knowledge
description: Search project and global knowledge sources using compact, on-demand retrieval
---

# Skill: search-knowledge

**Trigger**: `/search-knowledge [query]` or auto-called by `front-agent`
**Purpose**: Load only the smallest useful knowledge slice for the current task.

---

## Search Order

1. `~/.front-agent/wisdom/summary.md`
2. `knowledge/index.md`
3. Detail files only when needed:
   - `~/.front-agent/wisdom/learnings.md`
   - `~/.front-agent/wisdom/decisions.md`
   - `~/.front-agent/wisdom/issues.md`
   - `knowledge/components.md`
   - `knowledge/patterns.md`
   - `knowledge/design-system.md`

---

## Fast-Skip Rules

- If summaries contain only placeholders or no relevant matches, stop early
- Do not open detail files unless the summary/index suggests a relevant hit
- Do not load unrelated domains "just in case"

---

## Output Format

Return compact bullets only.

```markdown
## Knowledge Search: "[query]"

### Global
- [max 3 one-line bullets]

### Project
- [max 3 one-line bullets]

### Details
- [max 3 one-line bullets]
```

Rules:

- Max 3 bullets per section
- One line per bullet
- Prefer summaries over long excerpts
- If nothing is relevant, say `No relevant entries found`

---

## Constraints

- Use `haiku`
- Read-only
- Keep results compact enough to paste directly into the next agent prompt
