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

Use `o3` for adversarial review — it has stronger reasoning for edge case detection than `gpt-5.4`.

```bash
codex review --base main -m o3 "..."
```

If `o3` is unavailable or rate-limited, fall back to the user's default model (omit `-m`).

---

## How To Run

Build the prompt from two sources and pass it as the review instruction:

1. **Task goal** — one-line summary from `plan.md` (## Goal section)
2. **Claude reviewer notes** — non-blocking observations from the `reviewer` PASS output

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

### What to include in the prompt

| 항목 | 출처 | 포함 여부 |
|------|------|----------|
| 태스크 목표 | `plan.md` → ## Goal | 항상 포함 (1줄 요약) |
| 이전 리뷰어 비고 | `reviewer` 출력 → ### Notes | 있을 때만 포함 |
| constraints.md | — | 포함하지 않음 (Codex는 독립 판단) |
| 구현 파일 원문 | — | 포함하지 않음 (git diff로 충분) |

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
- Pass only task goal + previous reviewer notes — never pass constraints.md or full file contents
- If `codex` is not installed or not authenticated, skip and warn the orchestrator — do not block the workflow
- On FAIL: return issues to orchestrator, do not proceed to `git-commit`
- On PASS: signal orchestrator to proceed to `git-commit`
