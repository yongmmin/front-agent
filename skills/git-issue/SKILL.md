---
name: git-issue
description: Create a GitHub issue to track bugs, failed tests, or new tasks
---

# Skill: git-issue

**Trigger**: called automatically on test failure, or manually `/git-issue [description]`
**Purpose**: Create a GitHub issue to track bugs, failed tests, or new tasks.

---

## Activation Scenarios

1. **Auto**: test-runner detects failing tests
2. **Auto**: new feature work starts (task tracking)
3. **Manual**: `/git-issue [description]`

---

## Workflow

1. Gather issue content based on trigger type
2. Create issue via `gh issue create`
3. Return issue number to orchestrator (for PR linking)

---

## Issue Templates

### Test Failure Issue
```markdown
**Title**: [TEST FAIL] [test name]

**Description**:
## Failed Test
- File: [filename]
- Test: [test name]
- Branch: [branch name]

## Error
\`\`\`
[full error message]
\`\`\`

## Reproduce
\`\`\`bash
[test command]
\`\`\`

## Context
[what was being implemented]
```

### Feature Task Issue
```markdown
**Title**: [feat] [feature name]

**Description**:
## Goal
[what needs to be done]

## Acceptance Criteria
- [ ] [criterion 1]
- [ ] [criterion 2]
```

---

## gh CLI Command

```bash
gh issue create \
  --title "[title]" \
  --body "[body]" \
  --label "[bug|enhancement|test-failure]"
```

---

## Constraints

- Always include reproduction steps for bug/test-failure issues
- Return issue number after creation for PR linking