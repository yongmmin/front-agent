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

### 6. Plan Gate

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

## Execution Steps
- Step 1: [agent] - [task]
- Step 2: [agent] - [task]

## Branch
[feat|fix|ui|refactor]/[task-name]

## Commit Units
- [type]: [description]
```

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
- Skip `component-auditor` for review-only tasks and pure API wiring with no UI change
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
