---
name: execute-feature
description: Execute an approved plan by orchestrating specialist agents
---

# Skill: execute-feature

**Trigger**: `/execute-feature` (after plan.md is approved)
**Model**: sonnet (delegates to agents)
**Purpose**: Execute the approved plan.md by orchestrating specialist agents.

---

## Activation

User types: `/execute-feature`
Requires: `plan.md` must exist and be approved.

---

## Workflow

1. Read `plan.md` from project root
2. Verify plan is approved (user must have confirmed)
3. Execute steps in order:

```
Step 1: component-auditor (haiku)
  → Confirm reusable components from plan

Step 2: developer (sonnet)
  → Write test cases + implement feature (TDD RED → GREEN)
  → On failure: retry once, then escalate

Step 3: api-integrator (sonnet) [if plan includes API]
  → Connect UI to API

Step 4: test-runner (sonnet)
  → Run all tests, verify pass
  → On failure: git-issue → retry developer

Step 5: reviewer (opus)
  → Code review
  → On FAIL: return to developer with fix list

Step 6: git-branch → git-commit → git-pr
  → Create branch from plan.md branch name
  → Commit with conventional format
  → Create PR with implementation summary
```

4. Save implementation summary to `knowledge/` via save-knowledge

---

## Constraints

- Do not skip any step in the sequence
- Do not create PR before reviewer PASS
- If tests fail 3 times, stop and escalate to user