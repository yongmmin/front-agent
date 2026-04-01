---
name: pixel-check
description: Compare implemented UI against Figma design and flag deviations
---

# Skill: pixel-check

**Trigger**: `/pixel-check [figma-url]` or auto-called after figma-builder
**Purpose**: Compare the implemented UI against the Figma design and flag significant deviations.

---

## Activation

- Auto: called after figma-builder completes
- Manual: `/pixel-check [figma-url]`

---

## Workflow

```
Step 1: Fetch Figma design screenshot
  → Use Figma MCP: get_screenshot(fileKey, nodeId)

Step 2: Capture implementation screenshot
  → Use browser screenshot tool or describe current state

Step 3: Compare
  → Layout alignment
  → Spacing and sizing
  → Typography (font size, weight, line height)
  → Colors
  → Component variants and states

Step 4: Report deviations
  → Critical (must fix before PR): layout broken, wrong colors
  → Minor (acceptable): 1-2px spacing differences
```

---

## Deviation Severity

| Level | Example | Action |
|-------|---------|--------|
| **Critical** | Wrong layout, missing section | Must fix |
| **Major** | Wrong color, wrong font size | Should fix |
| **Minor** | 2px spacing diff, subtle shadow | Note only |

---

## Output Format

```
## Pixel Check Results

### Critical (must fix)
- [element]: expected [X], got [Y]

### Major (should fix)
- [element]: expected [X], got [Y]

### Minor (noted)
- [element]: minor spacing difference

Overall: PASS / NEEDS REVISION
```

---

## Constraints

- Only flag deviations above minor threshold as blockers
- Minor differences due to browser rendering are acceptable