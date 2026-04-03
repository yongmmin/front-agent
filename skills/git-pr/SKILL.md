---
name: git-pr
description: Push the branch and create a PR with a compact generated summary
---

# Skill: git-pr

**Trigger**: called by `front-agent` after `git-commit`
**Purpose**: Push the branch and create a PR with a compact, reviewable body.

---

## PR Body

- Summary
- Changed areas
- Test evidence
- Related issue link when applicable

---

## Constraints

- Never push to `main` directly
- Include test evidence
- Link related issues when available
