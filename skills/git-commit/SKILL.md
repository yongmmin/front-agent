---
name: git-commit
description: Create scoped Conventional Commits after reviewer PASS
---

# Skill: git-commit

**Trigger**: called by `front-agent` after reviewer PASS
**Purpose**: Commit staged changes with clear Conventional Commit messages.

---

## Constraints

- Stage only the intended files
- Never use `git add .`
- Never commit secrets
- Never commit with failing tests
