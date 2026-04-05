---
name: pixel-check
description: Compare implemented UI against Figma and report only meaningful deviations
---

# Skill: pixel-check

**Trigger**: `/pixel-check [figma-url]` or auto-called after `ui-builder`
**Purpose**: Flag only deviations large enough to matter before review.

---

## Check Criteria

| Category | What to check | Blocker threshold |
|----------|--------------|-------------------|
| Spacing | Gap, padding, margin match 4px grid | >4px off |
| Typography | Font size, weight, line-height, letter-spacing | Any deviation |
| Color | Design token used — not raw hex or hardcoded rgba | Any raw value |
| Component | Mapped codebase component used — not custom re-implementation | Re-implementation present |
| States | Hover, focus, disabled, loading, error states rendered | Any interactive state missing |
| Responsive | Breakpoint behavior matches Figma variants | Layout breaks at defined breakpoint |

---

## Workflow

```text
1. Fetch Figma screenshot via get_design_context
2. Compare implementation against check criteria above
3. Report only blocker-level or meaningful major deviations
```

---

## Output Format

```markdown
## Pixel Check Results

### Blockers
- [element]: [expected] vs [actual]

### Notes
- [non-blocking major deviation]

Overall: PASS | NEEDS REVISION
```

Rules:

- Omit empty sections
- Ignore minor browser rendering differences
