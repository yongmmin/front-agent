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

## Model

Use `o3` for adversarial review — stronger reasoning for edge case detection than `gpt-5.4`.

```bash
codex review --base main -m o3 "..."
```

If `o3` is unavailable or rate-limited, fall back to the user's default model (omit `-m`).

---

## How To Run

Build the review prompt from two sources:

| Field | Source | Include |
|-------|--------|---------|
| Task goal | `plan.md` → ## Goal | Always — one-line summary |
| Previous reviewer notes | `reviewer` output → ### Notes | Only when present |
| `constraints.md` | — | Never — Codex judges independently |
| Full file contents | — | Never — git diff is sufficient |

```bash
codex review --base main -m o3 \
  "Task: [plan.md Goal in one line]
Previous reviewer (Claude opus) PASS notes: [reviewer Notes section, or 'none']
Now review independently. Be adversarial. Focus on: correctness, security, type safety, and edge cases. Look for what the previous reviewer missed."
```

If the branch is not yet created (uncommitted changes only):

```bash
codex review --uncommitted -m o3 "..."
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

## On FAIL

Do not auto-fix. Surface the issues to the user with a clear decision prompt:

> "Codex review found blocking issues:
> 1. [file:line] — [issue]
>
> Options:
> a) Fix — send issues to the implementation agent and re-review
> b) Override — proceed to git-commit as-is"

### If user chooses Fix

1. Send the codex issue list to the implementation agent (`developer` / `ui-builder`)
2. Re-run `reviewer`
3. Re-run `codex-review` (one attempt only)
4. If still FAIL → create a `git-issue` and report to user — do not retry again

### If user chooses Override

Proceed to `git-commit` as-is. Record the override decision in the handoff block:

```
- decisions: codex-review FAIL overridden by user — [issue summary]
```

---

## Output Format

```
## Codex Review Verdict: PASS / FAIL

### Blocking Issues (if FAIL)
1. [file:line] — [issue] → [suggested fix]

### Notes (non-blocking)
- [observation]
```

---

## Constraints

- Run only after `reviewer` (opus) has already given PASS
- Pass only task goal + previous reviewer notes — never pass `constraints.md` or full file contents
- If `codex` is not installed or not authenticated, skip and warn the orchestrator — do not block the workflow
- On FAIL: surface to user — do not auto-fix without user approval
- On PASS or user override: signal orchestrator to proceed to `git-commit`
- Max one fix-retry cycle per task
