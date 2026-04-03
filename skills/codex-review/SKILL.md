---
name: codex-review
description: Independent adversarial code review via Codex CLI to eliminate Claude self-review bias
---

# Skill: codex-review

**Trigger**: called by `front-agent` after `reviewer` PASS
**Purpose**: Run an independent review using Codex (OpenAI) to catch issues Claude's self-review may have missed.

---

## Why This Exists

Claude reviews code it just wrote. Same model, same biases, same blind spots.
Codex is a different model with no shared context — it will catch different things.

---

## How To Run

```bash
codex review --base main "Be adversarial. Focus on: correctness, security, type safety, and edge cases. Look for what the previous reviewer missed."
```

If the branch is not yet created (uncommitted changes only):

```bash
codex review --uncommitted "Be adversarial. Focus on: correctness, security, type safety, and edge cases. Look for what the previous reviewer missed."
```

---

## Verdict Rules

**FAIL** if any of the following:
- Security vulnerability
- Incorrect logic or broken edge case
- Type unsafety that could cause a runtime error
- Behavior change not covered by existing tests

**PASS** for everything else. Style preferences, minor suggestions, and non-blocking observations do not cause FAIL.

---

## Output Format

```
## Codex Review Verdict: PASS / FAIL

### Blocking Issues (if FAIL)
1. [file:line] — [issue] → [fix]

### Notes (non-blocking)
- [observation]
```

---

## Constraints

- Run only after `reviewer` (opus) has already given PASS
- If `codex` is not installed or not authenticated, skip and warn the orchestrator — do not block the workflow
- On FAIL: return issues to orchestrator, do not proceed to `git-commit`
- On PASS: signal orchestrator to proceed to `git-commit`
