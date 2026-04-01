---
name: plan-feature
description: Create a structured implementation plan for a feature before writing any code
---

# Skill: plan-feature

**Trigger**: `/plan-feature [description]`
**Model**: opus
**Purpose**: Create a structured implementation plan for a feature before any code is written.

---

## Activation

User types: `/plan-feature [what to build]`

---

## Workflow

1. Load `knowledge/index.md` and relevant domain files
2. Run `component-auditor` — check for reusable components and patterns
3. Search existing codebase for related code
4. Draft `plan.md` in project root with the format below
5. Present plan to user: "Please review plan.md and approve to proceed."

---

## plan.md Format

```markdown
# Plan: [feature name]

## Goal
[What this feature does and why it's needed]

## Affected Files
- [path] — [what changes]

## Reusable Components
- [component] ([file]) — [how it will be used]

## Execution Steps
- Step 1: test-writer — write test cases for [scope]
- Step 2: implementer — implement [scope]
- Step 3: api-integrator — connect [endpoint] (if needed)
- Step 4: test-runner — run tests
- Step 5: reviewer — code review
- Step 6: git ops — branch, commit, PR

## Branch
feat/[feature-name]

## Commit Units
- test: add tests for [feature]
- feat: implement [feature]
- feat: connect [feature] to API
```

---

## Constraints

- Do not write any implementation code in this skill
- Do not proceed to execution without user approval