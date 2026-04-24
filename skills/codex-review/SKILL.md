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

Build the review prompt from two sources:

| Field | Source | Include |
|-------|--------|---------|
| Task goal | `plan.md` → ## Goal | Always — one-line summary |
| Previous reviewer notes | `reviewer` output → ### Notes | Only when present |
| `constraints.md` | — | Never — Codex judges independently |
| Full file contents | — | Never — git diff is sufficient |

**Scoped diff — only the current task's files**

`--uncommitted` and `--base main` both review ALL changes in the repo, not just the current task. Instead, generate a diff scoped to `changed_files` from the handoff and pass it directly to codex:

```bash
# 1. Generate diff for only the files changed in this task
#    Route through rtk-wrap so `rtk git diff` compresses output when the mode is on.
DIFF=$(bash hooks/rtk-wrap.sh git diff HEAD -- src/features/login/LoginForm.tsx src/features/login/LoginForm.test.tsx)

# 2. Pass scoped diff inline to codex
codex -m o3 "
Task: [plan.md Goal in one line]
Previous reviewer (Claude opus) PASS notes: [reviewer Notes section, or 'none']

Files changed in this task:
- src/features/login/LoginForm.tsx
- src/features/login/LoginForm.test.tsx

Diff:
\`\`\`diff
$DIFF
\`\`\`

Review independently. Be adversarial. Focus on: correctness, security, type safety, and edge cases. Look for what the previous reviewer missed."
```

If `o3` is unavailable or rate-limited, omit `-m` to fall back to the user's default model.

**No git repository or empty diff**: If the working directory is not a git repo, or `changed_files` is empty, skip `codex-review` and warn the orchestrator — do not block the workflow.

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
- Always scope diff to `changed_files` from the handoff — never use `--uncommitted` or `--base main` (those include unrelated changes)
- Pass only task goal + previous reviewer notes + scoped diff — never pass `constraints.md` or full file contents
- If `codex` is not installed, not authenticated, or the working directory is not a git repo: skip and warn the orchestrator — do not block the workflow
- On FAIL: surface to user — do not auto-fix without user approval
- On PASS or user override: signal orchestrator to proceed to `git-commit`
- Max one fix-retry cycle per task
- Route `git diff` through `bash hooks/rtk-wrap.sh git diff ...` (see `CLAUDE.md → RTK Wrapping`)
