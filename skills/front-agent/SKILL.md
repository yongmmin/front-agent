---
name: front-agent
description: Single entry point for all frontend tasks. Natural language → auto plan → execute.
---

# Skill: front-agent

**Trigger**: `/front-agent [request]`
**Purpose**: One command handles setup → intent detection → Figma URL check → plan → execution automatically.

---

## Overall Flow

```
/front-agent "create a login form"
       ↓
1. Auto-detect project (lazy setup)
2. Classify intent
3. If UI task → ask "Do you have a Figma URL?"
4. Generate plan.md and wait for user approval
5. After approval → run agent orchestration
```

---

## Step 1: Auto-Detect Project (Lazy Setup)

If `knowledge/index.md` is missing, run setup automatically. Do not ask the user for `/setup`.

```
- Read package.json → detect stack (Next.js, React, TypeScript, Tailwind, etc.)
- Initialize knowledge/ directory
- Run component-auditor (haiku) → create knowledge/components.md
- Check gh auth status, git remote -v
```

Skip this step if setup is already complete.

---

## Step 1.5: Ambiguity Check (isAmbiguous)

Before classifying intent, determine if the request is sufficiently clear.
If any of the following conditions apply, ask a clarifying question before generating plan.

### Ambiguous Request Conditions
- Target is unclear ("fix the button" — which button?)
- "Connect it" / "hook it up" without an API spec
- Scope is excessively broad ("everything", "all", "the whole thing")
- Technology choice is vague ("optimize it", "improve it" — what? performance? code quality?)
- Multiple requirements mixed in one request

### Clarification Question Format
When a request is ambiguous, ask in this format and proceed to Step 2 after receiving the answer.

> "[What part] is unclear. Please clarify the following:
> 1. [specific question 1]
> 2. [specific question 2 (if needed)]"

**Important**: Maximum 2 questions. Skip this step for clear requests.

---

## Step 2: Intent Classification

Analyze the request and classify into one of the following:

| Intent | Example Keywords | Workflow |
|--------|-----------------|----------|
| `figma` | Contains figma.com URL | Figma implementation |
| `ui` | Contains Korean UI request terms such as `만들어줘`, `폼`, `버튼`, `페이지`, `화면`, `컴포넌트` | UI implementation (ask for Figma URL) |
| `feature` | Contains Korean feature terms such as `기능`, `추가`, `연결`, `API`, `로직` | Feature implementation |
| `refactor` | Contains Korean refactor terms such as `리팩토링`, `정리`, `개선`, `중복` | Refactoring |
| `review` | Contains Korean review terms such as `리뷰`, `검토`, `확인해줘` | Code review |

---

## Step 3: Figma URL Check (UI/Figma intent only)

If intent is `ui` or `figma` and no figma.com URL in the request:

> "Do you have a Figma URL? Paste it if so. If not, say 'no' and I'll match the existing style."

- URL provided → `figma` workflow
- "No" / no URL → `ui` workflow (style-matcher)

---

## Step 4: plan.md Generation and Approval

Generate plan.md for the classified intent.

```markdown
# Plan: [task name]

## Goal
[What and why]

## Intent
[figma / ui / feature / refactor]

## Figma
[URL or "none — match existing style"]

## Reusable Components
- [component] ([file]) — [how to use]

## Affected Files
- [path] — [change description]

## Execution Steps
- Step 1: [agent] — [task]
- ...

## Branch
[feat|ui|fix|refactor]/[task-name]

## Commit Units
- [type]: [description]
```

After generating plan.md:
> "Please review plan.md. Shall we proceed?"

When the user approves ("yes", "ok", "go ahead", "proceed", etc.), move to Step 5.

---

## Step 5: Agent Execution by Workflow

> **CRITICAL**: The orchestrator never writes code or modifies files directly.
> All implementation must be handled by spawning subagents via the `Agent` tool.
> Write/Edit tools are only allowed for plan.md.

> **Context Manager Rules**: When spawning each agent, include at the front of the prompt:
> 1. The relevant constraints sections for that agent (from CLAUDE.md context selection table)
> 2. plan.md content
> 3. Previous agent results (if any)
>
> **NEVER**: include all of constraints.md at once.
> **NEVER**: include files unrelated to the current task.

When calling each agent:
1. The agent file (`agents/*.md`) content
2. Only the relevant constraints sections for that agent (from CLAUDE.md context selection table)
3. plan.md content
4. Previous agent results (if any)
— Include only these 4. Nothing more.

> **Common Step 0 for all workflows**: `search-knowledge (haiku)` — load relevant patterns/components/decisions first

### Figma Implementation
```
0. Skill(search-knowledge, model=haiku)  — load relevant knowledge
1. Agent(component-auditor, model=haiku) — find reusable components
2. Agent(ui-builder, model=sonnet)       — implement design via Figma MCP + responsive
3. Agent(ui-builder, model=sonnet)       — pixel-check: compare design vs implementation
4. Agent(ui-builder, model=sonnet)       — a11y-check: accessibility audit
5. Agent(reviewer, model=opus)           — code review
6. Agent(git-branch → git-commit → git-pr)
```

### UI Implementation (No Figma)
```
0. Skill(search-knowledge, model=haiku)  — load relevant knowledge
1. Agent(component-auditor, model=haiku) — find reusable components
2. Agent(ui-builder, model=sonnet)       — implement matching existing style
3. Agent(ui-builder, model=sonnet)       — a11y-check: accessibility audit
4. Agent(reviewer, model=opus)           — code review
5. Agent(git-branch → git-commit → git-pr)
```

### Feature Implementation
```
0. Skill(search-knowledge, model=haiku)  — load relevant knowledge
1. Agent(component-auditor, model=haiku) — find reusable components
2. Skill(tdd, model=sonnet)              — dedicated RED→GREEN→REFACTOR TDD cycle
3. Agent(api-integrator, model=sonnet)   — API integration (if needed)
4. Agent(reviewer, model=opus)           — code review
5. Agent(git-branch → git-commit → git-pr)
```

### Refactoring
```
0. Skill(search-knowledge, model=haiku)  — load relevant knowledge
1. Agent(refactor-architect, model=opus) — detect patterns → update plan.md
2. Wait for user re-approval
3. Agent(component-auditor, model=haiku) — confirm reusable components
4. Skill(tdd, model=sonnet)              — implement refactor + verify tests
5. Agent(reviewer, model=opus)           — code review
6. Agent(git-branch(refactor/) → git-commit → git-pr)
```

### Code Review
```
1. Agent(reviewer, model=opus) → output results
```

---

## harness_loop: Auto-Correction Loop

> **This is the heart of the harness.** An agent cannot declare completion until tests pass.

### How It Works

```
MAX_ATTEMPTS = 3
attempt = 0

while attempt < MAX_ATTEMPTS:
  1. Run implementation agent (developer / ui-builder)
  2. Verify with test-runner

  if tests pass:
    → proceed to reviewer agent
    → done
  else:
    attempt++
    feed error message back to implementation agent
    "Please fix the following errors: [error content]"

if attempt >= MAX_ATTEMPTS:
  → auto-create git-issue (title: [HARNESS FAIL] + task name)
  → report to user and stop
```

### Error Feedback Format for Agent Retry

Context to pass to the implementation agent on retry:
```
The previous implementation produced the following errors (attempt {attempt}/3):

[error content]

Fix only the above errors. Do not touch other code.
```

### Applied Workflows

- **Feature implementation**: run tdd agent → test-runner verification → retry on failure
- **UI implementation**: run ui-builder → test-runner verification (if tests exist) → retry on failure
- **Refactoring**: run tdd → test-runner verification → retry on failure

---

## After Completion

- Save learnings from this task with `save-knowledge`
- Output PR URL

---

## Constraints

- **The orchestrator never writes code directly. Violation = immediate stop.**
- Do not use Write/Edit tools except for plan.md.
- Include agents/*.md content and current context in each agent prompt.
- Handle setup automatically. Do not ask the user for `/setup`.
- Do not start implementation without plan.md.
- Do not proceed to execution without user approval.
- Do not declare completion without tests.
- Do not skip harness_loop and declare completion.
- Do not skip isAmbiguous check. Always ask when request is ambiguous.
- If MAX_ATTEMPTS (3) is exceeded, must create git-issue and report to user.
