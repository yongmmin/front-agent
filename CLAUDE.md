# Frontend Co-Pilot Runtime

Lean runtime rules for the plugin. Human-oriented detail belongs in `README.md`, not here.

---

## Entry Point

- `/front-agent` is the single public entry point
- If a user message looks like a frontend development request, invoke `front-agent` automatically
- The canonical execution spec lives in `skills/front-agent/SKILL.md`
- Do not load `README.md` during execution unless the user explicitly asks for documentation

---

## Intent Routing

| Intent | Detection rule | Action |
|--------|----------------|--------|
| `figma` | Contains a `figma.com` URL | Figma implementation |
| `ui` | Contains Korean UI request terms such as `만들어줘`, `폼`, `버튼`, `페이지`, `화면`, `컴포넌트` | UI implementation |
| `feature` | Contains Korean feature terms such as `기능`, `추가`, `연결`, `API`, `로직` | Feature implementation |
| `refactor` | Contains Korean refactor terms such as `리팩토링`, `정리`, `개선`, `중복` | Refactoring |
| `review` | Contains Korean review terms such as `리뷰`, `검토`, `확인해줘` | Code review |

If the intent is `ui` and no Figma URL is present, ask for one in the user's language.
If the intent is `feature` and the request contains API keywords (`fetch`, `axios`, `API`, `GraphQL`, `mutation`, `WebSocket`, `서버`, `백엔드`, `연결`, `데이터`, `실시간`), run API Spec Check before planning — spec is passed only to `api-integrator`, never to other agents.

---

## Runtime Rules

- `front-agent` orchestrates; implementation belongs to specialist agents
- In orchestration mode, Write/Edit is allowed only for `plan.md`
- Use only the active merged agents: `component-auditor`, `developer`, `ui-builder`, `api-integrator`, `test-runner`, `reviewer`, `refactor-architect`
- Do not use legacy agents such as `implementer`, `test-writer`, `figma-builder`, `style-matcher`, or `orchestrator`
- Never load the full `constraints.md` into every agent
- Never pass unrelated files, full repo docs, or raw verbose logs to spawned agents
- `git-commit` requires both `reviewer` PASS and `codex-review` PASS (or explicit user override)
- `reviewer` and `codex-review` run in parallel (`[reviewer || codex-review]`) — both read the same changed files, launch concurrently, and commit proceeds only when both return PASS

---

## Context Budget

For each spawned agent, pass only:

1. The agent file
2. The relevant `constraints.md` sections — obtained via `bash hooks/extract-constraints.sh <agent-name>`. Never pass the full `constraints.md`.
3. The minimal `plan.md` excerpt needed for that step
4. A compact handoff block
5. Only the exact files required for the task

### Compact Handoff Format

Use this structure and omit empty fields:

```markdown
## Handoff
- changed_files: path1, path2
- reusable_components: Button, Card
- decisions: use existing ProductCard layout
- blockers: waiting on failing test in cart.spec.ts
- test_status: not_run | passed:npm run test | failed:npm run test
```

Rules:

- Max 5 bullets
- One line per bullet
- No prose paragraphs
- Prefer identifiers and paths over explanation

---

## On-Demand Loading

- `constraints.md`: load only tagged sections needed by the current agent
- Project knowledge: load on demand through `search-knowledge`
- Session start should load only compact summaries, not full project knowledge files
- `search-knowledge` should return compact bullet summaries, not long excerpts

### Skip Rules

- Skip `search-knowledge` if stored knowledge is empty or clearly irrelevant
- Skip `component-auditor` for review-only tasks and pure API wiring with no UI changes
- Skip `api-integrator` unless UI data fetching or mutation behavior changes
- Skip `save-knowledge` if no durable pattern, decision, or issue was learned

---

## Model Routing

| Model | Use cases |
|------|-----------|
| `haiku` | search, audit, lightweight discovery |
| `sonnet` | implementation, tests, UI building, API integration |
| `opus` | planning, refactor design, review |
