---
name: git-pr
description: Push branch and create a GitHub Pull Request with auto-generated description
---

# Skill: git-pr

**Trigger**: called by orchestrator after git-commit
**Purpose**: Push branch and create a GitHub Pull Request with auto-generated description.

---

## Workflow

1. Push branch to remote: `git push -u origin [branch-name]`
2. Gather PR content:
   - Read `plan.md` for goal and affected files
   - Run `git log main..[branch] --oneline` for commit list
   - Run `git diff main..[branch] --stat` for changed files
3. Create PR via `gh pr create`

---

## PR Format

```markdown
## Summary
[1-3 bullet points describing what was done]

## Changes
- [file] — [what changed]
- [file] — [what changed]

## Test Plan
- [ ] All existing tests pass
- [ ] New tests written and passing
- [ ] Responsive layout verified (mobile/tablet/desktop)
- [ ] No TypeScript errors

## Related
Closes #[issue number] (if applicable)

🤖 Generated with Frontend Co-Pilot
```

---

## gh CLI Command

```bash
gh pr create \
  --title "[type]: [description]" \
  --body "$(cat <<'EOF'
[PR body]
EOF
)"
```

---

## PR Title Convention

Matches the primary commit type:
- `feat: add product filter`
- `ui: implement ProductCard from Figma`
- `refactor: extract useProductList hook`

---

## Constraints

- Never force push to main/master
- Always include test plan checklist in PR body
- Link related issues when applicable