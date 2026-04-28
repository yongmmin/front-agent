# Global Constraints

> **On-demand loading rule**: Do not pass this entire file to every agent.
> Each agent receives only the section tags relevant to its role.
> Extract via `bash hooks/extract-constraints.sh <agent-name>` — never inline the full file into an agent prompt.
>
> | Section tag | Target agents |
> |-------------|---------------|
> | `#code-rules` | developer, ui-builder, api-integrator |
> | `#filesystem` | developer, ui-builder, api-integrator |
> | `#completion` | developer, ui-builder, api-integrator, test-runner |
> | `#review` | reviewer |
> | `#failure-patterns` | reviewer, test-runner |
>
> **GC rule**: If this file exceeds 50 lines, remove items older than 90 days from `#failure-patterns` and merge similar rules.

---

## #code-rules

- Do not introduce new libraries or packages. Use only what already exists in `package.json`
- Do not call external APIs directly. Go through the project's internal wrappers or service layer
- Do not use the `any` type. Require explicit TypeScript types for all variables and functions
- Do not use inline styles. Use Tailwind classes or CSS modules
- Do not leave `console.log` in production code
- YAGNI: implement only what was explicitly requested. Do not add speculative features

---

## #filesystem

- `src/` — read/write allowed
- `.env*` — HARD BLOCKED (deny rule in settings.json — cannot be modified under any circumstances)
- `package.json` — requires explicit user approval before modification (PreToolUse hook warns)
- `next.config.js` / `next.config.ts` / `next.config.mjs` — requires explicit user approval before modification
- `tsconfig.json` — requires explicit user approval before modification
- `node_modules/` — no access
- Do not modify existing working code outside the request scope

---

## #completion

- Never declare completion without test execution results
- If `harness_loop` exceeds `MAX_ATTEMPTS` (3), do not declare completion. Create a GitHub issue and report the failure
- Output code only. Do not include explanations, summaries, or "I did X" narration

---

## #review

- Do not proceed to `git-commit` without reviewer PASS
- Do not proceed to `git-commit` without codex-review PASS or explicit user override
- If the reviewer returns FAIL and the issue is a repeatable pattern, add a rule to `#failure-patterns`
- Do not record one-off mistakes, such as typos or file-specific edge cases, as patterns

React performance — FAIL if any:
- `useEffect` missing dependency or including unstable reference causing infinite loop
- Inline object/function literal passed as prop on every render with no `useMemo`/`useCallback`
- `React.memo` absent on a pure component receiving stable props that re-renders from parent
- `useMemo`/`useCallback` wrapping a primitive or trivially cheap expression (overhead > benefit)
- Synchronous blocking operation (sort, filter on large array, heavy computation) in render path without memoization

Logic correctness — FAIL if any:
- Property access on potentially null/undefined value without guard
- Async operation without error handling surfaced to UI
- Edge cases not handled: empty list, zero value, boundary input

Design quality — FAIL if any:
- Duplicates an existing component/hook/util that the audit surfaced (or that obviously exists) instead of reusing it
- Single component mixes 2+ responsibilities (data fetching + presentation + business logic) where extraction is trivial
- New abstraction introduced with only one caller and no near-term second use ("premature abstraction")
- Props drilling 3+ levels where context, composition, or colocation is the standard fix
- Magic values (numbers, strings, role names) inlined where a named constant or enum is the project pattern
- Logic that belongs in a pure function is embedded inside a component body, blocking testability

Design quality — PASS notes (do not fail):
- Three similar lines is acceptable; do not demand abstraction for hypothetical reuse
- Style-only or naming preferences are not failures

---

## #failure-patterns

> Reviewer or test-runner appends entries here whenever the AI makes a repeatable mistake.
> Format: `- [YYYY-MM-DD] [category:correctness|react-perf|design|scope] [pattern description] - [specific prohibition rule]`
>
> The `[category:*]` tag mirrors reviewer's four categories. Use it so future entries cluster by failure mode and so design patterns accumulate alongside correctness/perf ones.

- [2026-04-23] [category:react-perf] Missing useEffect cleanup causes memory leaks - subscriptions/timers/listeners must return a cleanup function
- [2026-04-23] [category:react-perf] Using array index as React key - use a stable unique id; index keys allowed only for static, never-reordered lists
- [2026-04-23] [category:react-perf] Expensive useState initial value computed every render - use lazy initializer `useState(() => init())` for costly setup
- [2026-04-23] [category:correctness] Unclear Next.js "use client" boundary - declare `"use client"` only on the component that actually needs hooks/browser APIs; do not push it upward
- [2026-04-23] [category:correctness] Unhandled errors in async event handlers - wrap in `try/catch` and surface to UI (toast/error state)
