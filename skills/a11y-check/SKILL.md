---
name: a11y-check
description: Verify accessibility compliance of implemented UI
---

# Skill: a11y-check

**Trigger**: `/a11y-check` or auto-called after UI implementation
**Purpose**: Verify accessibility compliance of implemented UI.

---

## Checklist

### Semantic HTML
- [ ] Headings in correct hierarchy (h1 → h2 → h3)
- [ ] Lists use `ul`/`ol`/`li`
- [ ] Buttons use `<button>`, links use `<a href>`
- [ ] Forms use `<label>` with `htmlFor`
- [ ] Landmark regions: `<main>`, `<nav>`, `<header>`, `<footer>`

### ARIA
- [ ] Images have descriptive `alt` text (or `alt=""` if decorative)
- [ ] Icon-only buttons have `aria-label`
- [ ] Loading states use `aria-live` or `aria-busy`
- [ ] Modal dialogs have `role="dialog"` and `aria-modal`
- [ ] No `aria-hidden` on focusable elements

### Keyboard Navigation
- [ ] All interactive elements are keyboard-focusable
- [ ] Focus order is logical
- [ ] Focus is visible (not removed with `outline: none` without replacement)
- [ ] Modals trap focus correctly

### Color & Contrast
- [ ] Text contrast ratio ≥ 4.5:1 (normal text)
- [ ] Text contrast ratio ≥ 3:1 (large text)
- [ ] Information not conveyed by color alone

---

## Output Format

```
## A11y Check Results: PASS / FAIL

### Issues (if FAIL)
1. [component:element] — [issue] → [fix]

### Warnings (non-blocking)
- [suggestion]
```

---

## Constraints

- Always run after any UI implementation
- FAIL items must be fixed before PR