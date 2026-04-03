---
name: pixel-check
description: Compare implemented UI against Figma and report only meaningful deviations
---

# Skill: pixel-check

**Trigger**: `/pixel-check [figma-url]` or auto-called after `ui-builder`
**Purpose**: Flag only deviations large enough to matter before review.

---

## Workflow

```text
1. Fetch Figma screenshot
2. Capture implementation screenshot
3. Compare layout, spacing, typography, color, and states
4. Report only blocker-level or meaningful major deviations
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
