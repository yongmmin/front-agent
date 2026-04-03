---
name: git-issue
description: Create an issue for failed tests or tracked follow-up work
---

# Skill: git-issue

**Trigger**: auto-called on test failure or manually via `/git-issue [description]`
**Purpose**: Record failures and follow-up work with enough detail to reproduce.

---

## Required Content

- What failed
- Reproduction command
- Current branch or task context
- Short error summary

---

## Constraints

- Always include reproduction steps for test failures
- Return the issue identifier for later PR linking
