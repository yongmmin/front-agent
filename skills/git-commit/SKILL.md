---
name: git-commit
description: Stage and commit changes using Conventional Commits format
---

# Skill: git-commit

**Trigger**: called by orchestrator after reviewer PASS
**Purpose**: Stage and commit changes using Conventional Commits format.

---

## Conventional Commits Format

```
<type>(<scope>): <description>

[optional body]
```

| Type | When to use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `ui` | UI implementation (Figma or style) |
| `refactor` | Code restructuring without behavior change |
| `test` | Adding or updating tests |
| `chore` | Build, config, dependency changes |
| `docs` | Documentation only |

---

## Workflow

1. Run `git status` to see changed files
2. Review changes with `git diff`
3. Group changes into logical commit units (from `plan.md` commit plan)
4. Stage and commit each unit

```bash
# Example: test commit first, then feat
git add [test files]
git commit -m "test: add tests for product filter"

git add [implementation files]
git commit -m "feat: implement product filter with category and price range"
```

---

## Commit Message Rules

- Use imperative mood: "add" not "added"
- Lowercase after the colon
- No period at end
- Max 72 characters for subject line
- Body: explain WHY if not obvious

---

## Constraints

- Never use `git add .` — stage specific files only
- Never commit files with secrets or API keys
- Never commit broken/failing tests