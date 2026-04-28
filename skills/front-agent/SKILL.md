---
name: front-agent
description: Single entry point for frontend work. Classify intent, create a plan, and run the minimal agent workflow.
---

# Skill: front-agent

**Trigger**: `/front-agent [request]`
**Purpose**: Handle setup, intent detection, planning, execution, and verification with minimal context overhead.

---

## Canonical Rules

- This file is the canonical runtime workflow
- `README.md` is documentation only and should not be loaded during execution
- `front-agent` never implements directly
- Use only active merged agents: `component-auditor`, `developer`, `ui-builder`, `api-integrator`, `test-runner`, `reviewer`, `refactor-architect`
- Do not use legacy agents: `implementer`, `test-writer`, `figma-builder`, `style-matcher`, `orchestrator`

---

## Request Gate

### 0. RTK Mode Gate

Resolve the rtk token-filter mode before any agent spawn. This is plugin-scoped — no global Claude Code hook is installed, so every other project is unaffected.

**Resolution order:**

1. **Inline arg** — if the user message contains `--rtk=<mode>` or `--no-rtk`, persist it with `bash hooks/rtk-wrap.sh --set <mode>` (use `off` for `--no-rtk`). Skip UI.
2. **Env var** — if `FE_COPILOT_RTK` is set, do nothing. It is a hard override.
3. **Session flag** — if `.fe-copilot-cache/rtk-session.flag` already exists, reuse it.
4. **Otherwise** — launch the `AskUserQuestion` tool with a single question:
   - Question: `이 작업에서 rtk로 명령 출력을 압축할까요?`
   - Options:
     - `Off — raw 명령 그대로 (기본 동작)`
     - `On — standard (git/tsc/lint/test 압축) (Recommended)`
     - `On — aggressive (+ ultra-compact)`
     - `On — git-only (git 계열만 압축)`
   - After answer, call `bash hooks/rtk-wrap.sh --set <mode>` where mode is `off | standard | aggressive | git-only`.

Valid mode strings: `off`, `standard`, `aggressive`, `git-only`. Anything else must be rejected with a one-line error.

The user can re-run `/rtk` at any time to change the mode mid-session.

### 1. Lazy Setup

If `knowledge/index.md` is missing, initialize project knowledge automatically.
Do not ask the user to run `/setup`.

### 2. Ambiguity Check

Ask a clarification question before planning if any of the following apply:

- The target is unclear
- Scope is overly broad
- The request mixes multiple major tasks
- "Optimize" or "improve" does not specify what dimension matters

Rules:

- Ask at most 2 questions
- Ask only for missing information that blocks planning

### 3. Intent Classification

| Intent | Detection rule | Workflow |
|--------|----------------|----------|
| `figma` | Contains a `figma.com` URL | Figma implementation |
| `ui` | Contains Korean UI terms such as `만들어줘`, `폼`, `버튼`, `페이지`, `화면`, `컴포넌트` | UI without design file unless a Figma URL is provided |
| `feature` | Contains Korean feature terms such as `기능`, `추가`, `연결`, `API`, `로직` | Feature implementation |
| `refactor` | Contains Korean refactor terms such as `리팩토링`, `정리`, `개선`, `중복` | Refactoring |
| `review` | Contains Korean review terms such as `리뷰`, `검토`, `확인해줘` | Code review |

### 4. Figma Check

If intent is `ui` and no Figma URL is present, ask for one in the user's language.

- URL provided -> `figma`
- No URL -> `ui`

### 5. API Spec Check

**Trigger**: intent is `feature` AND request contains any API keyword:
`fetch`, `axios`, `API`, `GraphQL`, `query`, `mutation`, `Apollo`, `WebSocket`, `endpoint`, `서버`, `백엔드`, `연결`, `데이터`, `불러와`, `저장`, `실시간`

If triggered, ask once in the user's language:
> "Do you have an API spec? (Swagger/OpenAPI URL, GraphQL schema, `.md`/`.yaml` file, or paste the endpoint directly)"

| Response | Action |
|----------|--------|
| URL or file provided | Record in `plan.md → Inputs.API`; fetch on demand in `api-integrator` step only |
| Endpoint/query pasted directly | Record as-is in `plan.md → Inputs.API` |
| None available | Ask: "What request/response shape do you expect?" — record the described shape |

**Token budget rules:**
- Pass API spec only to `api-integrator` — never to `developer`, `ui-builder`, or other agents
- If a URL was provided, `api-integrator` fetches only the relevant endpoint(s) on demand — do not load the full document upfront

### 6. Review Fast-Path

If intent is `review`, **skip the Plan Gate entirely** and spawn `reviewer` directly on the current changes. No `plan.md`, no user approval wait — pure review tasks do not need a plan. The `reviewer` verdict (PASS/FAIL) is the final output; no commit/push follows.

Applies only when intent is exactly `review`. Any other intent still goes through the Plan Gate below.

### 7. Plan Gate

Create `plan.md`, then wait for explicit user approval before any execution.

Use this format:

```markdown
# Plan: [task name]

## Goal
[what and why]

## Intent
[figma / ui / feature / refactor / review]

## Inputs
- Figma: [URL or none]
- API: [spec, endpoint, or none]

## Affected Files
- path/to/file.tsx - [change]

## Design Check
- Reuse: [component/hook/util to reuse, or "none — new primitive justified because X"]
- Responsibility: [how logic splits across files — e.g. "fetch in hook, render in component, format in util"]
- Risk: [conflict with an existing pattern or convention, or "none"]

## Execution Steps
- Step 1: [agent] - [task]
- Step 2: [agent] - [task]

## Branch
[feat|fix|ui|refactor]/[task-name]

## Commit Units
- [type]: [description]
```

**Design Check rules**:
- Required for `ui`, `figma`, `feature`, `refactor`. Omit for `review`.
- Max 1 line per bullet. No prose paragraphs.
- If `Reuse` says "new primitive", the justification must be one concrete reason — not a vague "for flexibility".
- Authoring order:
  1. At plan creation, fill `Reuse / Responsibility / Risk` from a quick scan + project knowledge.
  2. After `component-auditor` runs, **update the `Reuse` line in place** with the concrete candidates it surfaced. This is a small in-place edit, not a new section.
  3. `developer` / `ui-builder` / `api-integrator` read the updated `plan.md` as their canonical Design Check.
- Do not duplicate the audit list. The Reuse line is the single source of truth.
- This section exists to catch design mistakes BEFORE implementation. It is read by the user during plan approval and re-read by `reviewer` during the design category check.

Ask: `Please review plan.md. Approve it and I will execute.`

---

## Context Budget

For each agent call, include only:

1. The relevant `agents/*.md` file
2. The relevant `constraints.md` sections — obtained via `bash hooks/extract-constraints.sh <agent-name>`. Do not pass the full file.
3. The minimal `plan.md` excerpt needed for that step
4. A compact handoff block
5. Only the exact files needed for execution

### Compact Handoff Schema

```markdown
## Handoff
- changed_files: path1, path2
- reusable_components: Button, Card
- decisions: keep existing filter sidebar pattern
- blockers: failing `cart.spec.ts`
- test_status: not_run | passed:npm run test | failed:npm run test
```

Rules:

- Omit empty fields
- Max 5 bullets
- One line per bullet
- No prose summaries
- Prefer paths, identifiers, and commands

---

## Workflow Selection

`||` = run in parallel — launch both agents simultaneously and wait for both before proceeding.

**Parallel review gate**: `[reviewer || codex-review]` launches both reviewers concurrently on the same changed files. `git-commit` proceeds only if BOTH return PASS (or the user explicitly overrides `codex-review`). Any FAIL blocks commit and its fix list feeds the retry loop.

### Shared Skip Rules

- Skip `search-knowledge` if stored knowledge is empty or irrelevant. Run `bash hooks/knowledge-has-content.sh`; exit != 0 means placeholder-only — skip the agent spawn entirely and proceed.
- `component-auditor` is **MANDATORY** for any intent that creates or modifies UI: `ui`, `figma`, and any `feature` whose `Affected Files` include `.tsx`/`.jsx` components, hooks, or styles. Skipping in these cases is a workflow violation.
- Skip `component-auditor` only when ALL of the following hold:
  - intent is `review` (review fast-path), OR
  - intent is `feature` AND the change touches zero component/hook/style files (pure service/util/API wiring)
- Skip `api-integrator` unless UI data fetching or mutation behavior changes
- Skip `save-knowledge` if the task produced no durable learning

### Feature

```
[search-knowledge? || component-auditor?] -> developer
-> test-runner -> api-integrator? -> [reviewer || codex-review]
-> git-branch -> git-commit -> git-pr -> save-knowledge?
```

### Figma

```
[search-knowledge? || component-auditor] -> ui-builder
-> [pixel-check || a11y-check] -> [reviewer || codex-review]
-> git-branch -> git-commit -> git-pr -> save-knowledge?
```

### UI Without Design

```
[search-knowledge? || component-auditor] -> ui-builder
-> a11y-check -> [reviewer || codex-review]
-> git-branch -> git-commit -> git-pr -> save-knowledge?
```

### Refactor

```
search-knowledge? -> refactor-architect -> user re-approval
-> component-auditor? -> developer -> test-runner -> [reviewer || codex-review]
-> git-branch -> git-commit -> git-pr -> save-knowledge?
```

### Review

Fast-path: bypasses the Plan Gate (see Request Gate step 6).

```
reviewer
```

---

## Harness Loop

Use the retry loop for `feature`, `ui`, `figma`, and `refactor` implementation steps.

```text
MAX_ATTEMPTS = 3

run implementation agent
run test-runner when applicable

if tests fail:
  retry with only the failing error context

if attempts exceed MAX_ATTEMPTS:
  create a git issue
  record a repeatable failure pattern if appropriate
  stop and report
```

Retry context must contain only:

- failing command
- failing file/test identifier
- shortest useful error excerpt

Never resend the full previous transcript.

---

## Completion

- Never declare completion without test evidence when tests are applicable
- Never move to `git-commit` without reviewer PASS
- Save knowledge only if a reusable pattern, decision, or repeatable issue emerged
