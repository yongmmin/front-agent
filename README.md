<div align="center">

# Frontend Co-Pilot

**Claude Code 플러그인 — 7개 에이전트, 17개 스킬, Harness Engineering**

[![Agents](https://img.shields.io/badge/agents-7-green.svg)](#에이전트)
[![Skills](https://img.shields.io/badge/skills-17-orange.svg)](#스킬)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](LICENSE)
[![Stack](https://img.shields.io/badge/stack-React%20%2F%20Next.js-61DAFB.svg)](#호환-스택)

*오케스트레이터가 전문 에이전트에게 위임하고, 세션 간 지식을 축적하는 React/Next.js 개발 자동화 플러그인*

</div>

---

## 사용법

```
/front-agent [자연어 요청]
```

```
/front-agent 로그인 폼 만들어줘
/front-agent https://figma.com/design/xxx 이 화면 구현해줘
/front-agent 결제 기능 추가해줘
/front-agent 이 코드 리팩토링해줘
```

명령어 하나로 끝. setup, plan, execute 따로 입력할 필요 없다.

---

## 필수 도구

| 도구 | 필요성 |
|------|--------|
| **Claude Code** | 필수 |
| **Node.js** | 필수 |
| **gh CLI** | 필수 (`brew install gh && gh auth login`) |
| **Codex CLI** | codex-review 사용 시 (`npm install -g @openai/codex && codex login`) |
| **Figma MCP** | Figma 구현 시 |

---

## 설치

```bash
git clone https://github.com/yongmmin/front-agent.git ~/claude-plugins/fe-copilot
cd ~/claude-plugins/fe-copilot
chmod +x install.sh && ./install.sh
```

`install.sh` automatically:
1. Creates skill symlinks under `~/.claude/skills/`
2. Adds `.env*` deny rules to `~/.claude/settings.json`

---

## ⚠️ 필독: 도구 경계 제거 방법

설치 스크립트가 `~/.claude/settings.json`에 아래 규칙을 자동으로 추가합니다.

| 파일 | 처리 방식 |
|------|----------|
| `.env*` | 수정 금지 — settings.json Deny 규칙으로 하드 차단 |
| `package.json` | 수정 전 사용자 검토 요청 — PreToolUse 훅 경고 |
| `next.config.js` / `tsconfig.json` | 수정 전 사용자 검토 요청 — PreToolUse 훅 경고 |

**이 규칙들을 제거하려면:**

**1. `.env*` 차단 해제** — `~/.claude/settings.json`에서 아래 항목 삭제:
```json
"Write(.env*)",
"Edit(.env*)"
```

**2. PreToolUse 훅 비활성화** — 이 플러그인 저장소의 `hooks/hooks.json`에서 `PreToolUse` 블록 전체 삭제:
```json
"PreToolUse": [...]
```

**3. 스킬 심볼릭 링크 제거** (플러그인 완전 삭제 시):
```bash
for skill in front-agent implement-figma match-style tdd code-review a11y-check \
  pixel-check refactor-scan component-audit save-knowledge search-knowledge \
  codex-review git-branch git-commit git-pr git-issue rtk-toggle; do
  rm -f ~/.claude/skills/$skill
  rm -f ~/.claude/commands/$skill.md
done
```

---

## 핵심 원칙

1. **Conductor** — 오케스트레이터는 직접 코드를 작성하지 않는다. 전문 에이전트에게 위임한다.
2. **Evidence First** — 테스트 실행 결과 없이 완료를 선언하지 않는다.
3. **YAGNI** — 명시적으로 요청된 것만 구현한다. 추측 기능 추가 금지.
4. **On-Demand Context** — 에이전트별 필요한 컨텍스트만 선별해서 전달한다.
5. **Harness over Prompt** — AI가 실수하면 프롬프트가 아니라 시스템(제약, 훅, 루프)을 고친다.

---

## 동작 흐름

```
/front-agent [요청]
  → RTK Mode Gate — 세션 첫 호출 시 UI 선택 (off / standard / aggressive / git-only)
  → Lazy Setup — knowledge/index.md 없으면 자동 초기화 (최초 1회)
  → isAmbiguous 체크 — 모호하면 명확화 질문 (최대 2개)
  → Figma 체크 — ui 인텐트인데 URL 없으면 요청
  → API Spec 체크 — feature 인텐트 + API 키워드 감지 시 명세서 요청 (REST/GraphQL/WebSocket)
  → search-knowledge? (haiku) — 지식 있을 때만 로드
  → component-auditor? (haiku) — UI 작업 시만 실행
  → plan.md 생성 (Design Check 포함) + 사용자 승인
  → [인텐트별 실행: feature / figma / ui / refactor]
  → reviewer (opus) — 코드 품질/TypeScript/보안 리뷰
  → codex-review — OpenAI o3 독립 adversarial 리뷰 (changed_files 기반 scoped diff)
  → git-branch → git-commit → git-pr
  → save-knowledge? — 학습된 내용 있을 때만 저장
```

`?` = 조건부 실행. Skip Rules에 해당하면 건너뜀.

**이중 게이트**: `reviewer` PASS + `codex-review` PASS 모두 통과해야 `git-commit` 진행.
`codex-review` FAIL 시 자동 수정 없음 — Fix(재시도 1회) 또는 Override(기록 후 진행) 중 선택.

### 인텐트별 워크플로우

`||` = 병렬 실행 — 두 에이전트 동시 시작, 둘 다 완료 후 다음 단계 진행.

| 인텐트 | 워크플로우 |
|--------|----------|
| `feature` | `[search-knowledge? \|\| component-auditor?] → developer → test-runner → api-integrator? → [reviewer \|\| codex-review] → git-*` |
| `figma` | `[search-knowledge? \|\| component-auditor] → ui-builder → [pixel-check \|\| a11y-check] → [reviewer \|\| codex-review] → git-*` |
| `ui` | `[search-knowledge? \|\| component-auditor] → ui-builder → a11y-check → [reviewer \|\| codex-review] → git-*` |
| `refactor` | `search-knowledge? → refactor-architect → 사용자 재승인 → component-auditor? → developer → test-runner → [reviewer \|\| codex-review] → git-*` |
| `review` | `reviewer` (plan gate 생략 — fast-path) |

---

## 에이전트

| Agent | Model | Role |
|-------|-------|------|
| `component-auditor` | haiku | 재사용 가능 컴포넌트 탐색 |
| `developer` | opus | TDD 기반 기능 구현 (test-writer + implementer 통합) |
| `ui-builder` | sonnet | Figma 또는 기존 스타일 기반 UI 구현 (figma-builder + style-matcher 통합) |
| `api-integrator` | sonnet | UI-API 연결 + 로딩/에러 상태 처리 |
| `test-runner` | haiku | 테스트 실행 + MAX_ATTEMPTS 초과 시 GitHub 이슈 생성 |
| `reviewer` | opus | 코드 품질, TypeScript, 보안 리뷰 |
| `refactor-architect` | opus | 반복 패턴 탐지 + 리팩토링 설계 |

---

## 스킬

사용자는 `/front-agent`만 사용한다. 나머지는 front-agent가 자동 호출한다.

| 스킬 | 호출 시점 |
|------|----------|
| `search-knowledge` | Step 0 — 지식 있을 때만 (조건부) |
| `component-audit` | UI/기능 구현 전 — 조건부 |
| `tdd` | 사용자가 직접 `/tdd`로 호출 시 — front-agent 내부에서는 `developer`를 직접 사용 |
| `implement-figma` / `match-style` | UI 구현 |
| `pixel-check` | Figma 구현 후 검증 |
| `a11y-check` | UI 구현 후 검증 |
| `code-review` | 모든 구현 후 (`reviewer` 에이전트 실행) |
| `codex-review` | reviewer PASS 후 — OpenAI o3 독립 adversarial 리뷰 |
| `refactor-scan` | 리팩토링 |
| `save-knowledge` | 작업 완료 후 — 조건부 |
| `git-branch` | 구현 완료 후 브랜치 생성 |
| `git-commit` | reviewer + codex-review 이중 게이트 통과 후 |
| `git-pr` | 커밋 후 PR 생성 |
| `git-issue` | harness_loop MAX_ATTEMPTS(3) 초과 시 자동 생성 |
| `rtk-toggle` | `/rtk` — 세션 중 rtk 모드 변경 (off / standard / aggressive / git-only) |

---

## 하네스 엔지니어링 (Harness Engineering)

> "AI가 실수했을 때, 프롬프트를 고치지 마세요. 마구(harness)를 고치세요."

AI의 실수가 구조적으로 반복 불가능하도록 시스템을 바꾸는 기법. v4에서 적용, v5에서 컨텍스트 최적화 확장, v6에서 이중 게이트 추가.

| 구성 요소 | 파일 | 역할 |
|----------|------|------|
| **PostToolUse 훅** | `hooks/post-tool-use.sh` | `.ts/.tsx` 저장 시 tsc + eslint 자동 실행, 에러 요약 출력 |
| **harness_loop** | `skills/front-agent/SKILL.md` | 테스트 실패 → 에러 피드백 → 재시도 (MAX 3회), 초과 시 GitHub 이슈 생성 |
| **isAmbiguous** | `skills/front-agent/SKILL.md` | plan 전 모호한 요청 감지 → 명확화 질문 강제 |
| **constraints.md** | `constraints.md` | 5개 섹션 태그(`#code-rules` 등), 에이전트별 온디맨드 로딩 |
| **Output constraints** | `agents/*.md` | 에이전트 "코드만 출력" 강제, 설명·요약 금지 |
| **실패 → 규칙 루프** | `agents/reviewer.md`, `agents/test-runner.md` | 반복 실패 패턴을 `constraints.md`에 자동 기록 |
| **Skip Rules** | `CLAUDE.md` | 불필요한 에이전트 호출 조건부 스킵 |
| **Compact Handoff** | `CLAUDE.md` | 에이전트 간 전달 컨텍스트를 5-bullet 구조체로 제한 |
| **이중 게이트** | `constraints.md` `#review`, `CLAUDE.md` | `reviewer` PASS + `codex-review` PASS 모두 통과해야 commit 허용 |
| **codex-review** | `skills/codex-review/SKILL.md` | OpenAI o3 독립 adversarial 리뷰 — `changed_files` 기반 scoped diff, git repo 없으면 graceful skip |

### constraints.md 온디맨드 구조

전체를 모든 에이전트에 주입하지 않는다. 에이전트별 필요한 섹션만 선택 전달:

| 에이전트 | 받는 섹션 |
|---------|---------|
| developer / ui-builder / api-integrator | `#code-rules` + `#filesystem` + `#completion` |
| test-runner | `#completion` + `#failure-patterns` |
| reviewer | `#review` + `#failure-patterns` |
| component-auditor | 없음 |

### Skip Rules

불필요한 에이전트 호출을 건너뛰는 조건:

| 스킵 대상 | 조건 |
|----------|------|
| `search-knowledge` | 저장된 지식이 없거나 현재 태스크와 무관 |
| `component-auditor` | `review` 인텐트 또는 `.tsx/.jsx/hooks/styles` 0파일인 `feature` (UI 동반 작업에선 **MANDATORY**) |
| `api-integrator` | UI 데이터 흐름 변경이 없는 경우 |
| `save-knowledge` | 재사용 가능한 패턴/결정/이슈를 학습하지 않은 경우 |

### Compact Handoff 포맷

에이전트 간 전달 시 자유형 산문 대신 구조화된 블록 사용:

```markdown
## Handoff
- changed_files: src/features/cart/Cart.tsx
- reusable_components: Button, Card
- decisions: 기존 ProductCard 레이아웃 유지
- blockers: cart.spec.ts 실패 중
- test_status: failed:npm run test
```

규칙: 최대 5줄, 줄당 1개 항목, 빈 필드 생략.

---

## 지식 시스템

두 계층. 세션이 지나도 토큰 소비가 늘지 않도록 설계됨.

```
~/.front-agent/wisdom/
├── summary.md      ← 세션 시작 시 자동 로드 (20줄 고정)
├── learnings.md    ← 온디맨드
├── decisions.md    ← 온디맨드
└── issues.md       ← 온디맨드

knowledge/
└── index.md        ← 프로젝트 전용, 300줄 제한 (초과 시 도메인 파일로 분리)
```

- `summary.md` 20줄 고정 → 지식이 쌓여도 세션 초기 토큰 일정
- `knowledge/index.md` → Git 포함, 팀원과 공유 가능

---

## 호환 스택

React / Next.js (App Router) · TypeScript · Tailwind CSS · Vitest / Jest · GitHub

---

## 변경 이력

### v6.9.2: failure-patterns 카테고리 + refactor 게이트 누수 차단

reviewer의 4 카테고리(`correctness / react-perf / design / scope`)가 누적 학습 형식까지 일관되게 흐르도록, `#failure-patterns`에 카테고리 태그 도입. 동시에 refactor 흐름에서 plan Design Check 갱신 책임을 architect에 명시해 게이트 누수 차단.

- **`constraints.md #failure-patterns` 형식 확장** — `- [YYYY-MM-DD] [category:correctness|react-perf|design|scope] [pattern] - [rule]`. 기존 5개 시드 항목을 새 형식으로 마이그레이션 (4개 react-perf/correctness 분류). 누적되는 design 패턴이 자동 차단 룰로 진화하는 학습 루프 완성
- **`agents/reviewer.md` 출력 규칙 갱신** — FAIL 시 `#failure-patterns` 추가 시 새 형식 강제. 카테고리 태그 누락은 형식 위반
- **`agents/refactor-architect.md` Design Check 갱신 책임 명시** — workflow 4단계(아키텍처 제안 후) "`plan.md → Design Check` in-place 갱신" 의무화. `Reuse`(새 추상화 + 잔존 기존), `Responsibility`(레이어 split), `Risk`(developer가 회피할 패턴) 갱신 후 사용자 재승인 → developer 핸드오프. constraint에 "Design Check 갱신 없이 핸드오프 금지" 추가
- **토큰 영향 ≈ +5줄** — 기존 항목 형식 변경뿐, agent 컨텍스트 영향 없음

### v6.9.1: 시니어 품질 게이트 도입 (3중 배치)

10년차 시니어 개발자의 코드 품질 직관(재사용 우선, 책임 분리, 추상화 적정성)을 자동 게이트로 명문화. 사전(Plan) → 중간(Audit) → 사후(Review) 3중 게이트가 같은 룰브릭을 공유.

- **`constraints.md #review`에 design quality 룰브릭 추가** — FAIL 6항목(audit이 surface한 컴포넌트/훅/유틸 중복, 단일 컴포넌트 책임 혼합, 호출자 1개뿐인 premature abstraction, props drilling 3+ levels, 매직값 inline, 컴포넌트 본문에 박힌 비순수 로직) + PASS 노트 2항목(3줄 중복은 허용, 스타일/네이밍 선호는 FAIL 아님). reviewer만 수신 — `extract-constraints.sh`가 다른 에이전트에는 전달하지 않음
- **`agents/reviewer.md` 4 카테고리 분리** — `correctness / react-perf / design / scope`로 워크플로 명확화. 출력 Issues에 `[category]` 태그 강제. UI 변경 시 design 카테고리 평가 누락은 verdict 누락으로 간주
- **`skills/front-agent/SKILL.md` plan.md 포맷에 Design Check 섹션 신설** — `Reuse / Responsibility / Risk` 3줄. 사용자가 plan 승인 시점에서 설계 의도를 한 번 거름. 작성 순서: 플랜 작성 시 초기 채움 → component-auditor 결과로 `Reuse` 라인 in-place 갱신 → 구현 agent가 최종 plan 사용 (단일 source of truth)
- **`component-auditor` MANDATORY 강제** — UI 변경(`.tsx/.jsx/hooks/styles`) 동반 작업에선 audit skip 불가. skip 허용은 `review` 인텐트 또는 UI 0파일 `feature`로 한정. `CLAUDE.md` / `skills/front-agent/SKILL.md` 양쪽 일관 반영
- **구현 에이전트가 plan Design Check 직접 읽음** — `developer.md` / `ui-builder.md` / `api-integrator.md` 워크플로 첫 단계에 "Read `plan.md → ## Design Check`" 추가. `Reuse`는 suggestion이 아닌 directive, `Responsibility`는 layer split, `Risk`는 회피 패턴. 일탈 시 한 줄 정당화를 handoff에 기록
- **토큰 영향 ≈ +30줄** — reviewer에만 design 룰 추가 전달, 구현 에이전트는 plan의 한 줄 directive만 읽으므로 컨텍스트 예산 거의 무영향

### v6.8: rtk opt-in 통합 (플러그인 전용 토큰 필터)

Rust 기반 CLI 압축 프록시 [rtk](https://github.com/rtk-ai/rtk)를 플러그인 범위에만 선택적으로 연결. 다른 Claude Code 프로젝트에는 영향 없음.

- **`rtk init -g` 미실행** — 전역 Bash hook을 설치하지 않는다. 사용자가 터미널에서 직접 `git status`를 쳐도 raw 출력 그대로. 다른 프로젝트에서 Claude Code를 써도 동일
- **`hooks/rtk-wrap.sh` 신설** — 플러그인 내부의 git/gh/tsc/eslint/jest/vitest/playwright/find/grep/ls 등 모든 Bash 호출이 반드시 이 래퍼를 경유. 모드에 따라 `rtk <cmd>` 또는 raw를 exec. rtk 미설치여도 graceful fallback
- **UI 기반 모드 선택** — `/front-agent` Request Gate step 0에 `AskUserQuestion` 선택기 추가. 옵션: `off / standard / aggressive / git-only`. 선택은 `.fe-copilot-cache/rtk-session.flag`에 세션 유지
- **`/rtk` 토글 스킬 신설** — 세션 중 언제든 모드 변경 가능 (`/rtk standard`, `/rtk off`, `/rtk status`, 또는 인자 없이 호출 시 UI 팝업)
- **인자/env 오버라이드** — `/front-agent --rtk=aggressive` 또는 `/front-agent --no-rtk`로 UI 생략 가능. `FE_COPILOT_RTK` 환경변수는 최상위 우선순위
- **PostToolUse 적용** — `hooks/post-tool-use.sh`의 `npx tsc`, `npx eslint` 호출을 rtk-wrap 경유로 전환. 모드 on일 때 저장 시마다 tsc/eslint 출력 압축
- **스킬 통합** — `git-branch`, `git-commit`, `git-pr`, `git-issue`, `codex-review`, `component-audit` 및 `test-runner` 에이전트 문서에 래퍼 경유 규칙 명시. 중앙 규칙은 `CLAUDE.md → RTK Wrapping` 섹션

### v6.7: 핫패스 최적화 + developer opus 전환

플러그인이 매 턴/매 저장마다 지불하던 고정 비용을 추가로 깎고, TDD 품질을 올리기 위해 developer를 opus로 승격.

- **#1 훅 JSON 파싱 `python3` → `jq`** — `hooks/post-tool-use.sh`와 `hooks/pre-tool-use.sh`가 `CLAUDE_TOOL_INPUT` 파싱에 `python3 -c`를 쓰던 부분을 `jq -r` 우선 + python3 fallback으로 교체. Python 인터프리터 기동(~80ms)이 `jq`(~5ms)로 줄어들어 Write/Edit마다 발생하던 고정 지연 제거
- **#2 PostToolUse 테스트 파일 스킵** — `*.spec.ts(x)`, `*.test.ts(x)`, `__tests__/`, `__mocks__/` 경로는 tsc + eslint 검증을 건너뜀. 테스트 전용 tsconfig/ESLint 규칙 차이로 생기던 노이즈 제거 + 저장 시 훅 비용 절감
- **#3 `review` 인텐트 Fast-Path** — 순수 리뷰 요청은 `plan.md` 생성과 사용자 승인을 생략하고 `reviewer`로 직행. 리뷰는 변경을 만들지 않으므로 plan gate 마찰을 제거. `skills/front-agent/SKILL.md` Request Gate에 step 6로 명문화
- **#4 `#failure-patterns` 사전 시드** — 기존에는 빈 상태여서 reviewer가 같은 실수를 반복 탐지. 흔한 React/Next.js 안티패턴 5개(useEffect cleanup 누락, index-as-key, 비-lazy useState 초기값, 부정확한 `"use client"` 경계, async 핸들러 에러 무방호) 사전 등록으로 reviewer 초회 통과율 상승
- **#5 `.fe-copilot-cache` TTL 정리** — `hooks/session-start.sh`에 `find -mmin +60 -delete`로 1시간 초과 캐시 파일 자동 삭제. 디바운스/출력 파일이 누적되어 생기는 디렉터리 비대화 방지
- **#6 `developer` 에이전트 opus 승격** — `agents/developer.md` Model `sonnet → opus`. TDD RED→GREEN 품질이 실패 재시도 횟수와 연결되므로 초회 정확도를 끌어올려 harness_loop 재시도 수를 줄이는 방향이 총비용 관점에서 유리. `CLAUDE.md` Model Routing 표도 정합성 반영

### v6.6: 런타임 성능 4종 최적화

온디맨드 로딩 규칙을 유지한 채 플러그인 자체 실행 비용을 감축. 병목 큰 순서로 4개 항목 일괄 반영.

- **#1 PostToolUse tsc 비용 절감** — `hooks/post-tool-use.sh`에 `tsc --incremental` + per-file 3초 디바운스 + `tsc`∥`eslint` 병렬 실행 도입. 파일 저장 1회당 풀 프로젝트 타입체크가 돌던 구조를 incremental + 캐시 기반으로 전환. `hooks.json` PostToolUse timeout 30→60s, `.gitignore`에 `*.tsbuildinfo` / `.fe-copilot-cache/` 추가
- **#2 reviewer ∥ codex-review 병렬 게이트** — 모든 워크플로우(`feature`/`figma`/`ui`/`refactor`)의 `reviewer → codex-review` 순차 체인을 `[reviewer || codex-review]`로 변경. 두 에이전트가 동일한 changed files를 동시에 읽고, 둘 다 PASS일 때만 `git-commit` 진행 (override 규칙 유지)
- **#3 search-knowledge 콜드 비용 제거** — `hooks/knowledge-has-content.sh` 신설. `front-agent`는 skill 호출 전 이 스크립트로 placeholder-only 여부를 판별, 비어 있으면 agent spawn 없이 `No relevant entries found`로 바로 진행. 현재처럼 knowledge가 비어있는 초기 상태에서 haiku 에이전트 기동 비용을 완전히 제거
- **#4 constraints 섹션 추출 메커니즘** — `hooks/extract-constraints.sh <agent-name>` 신설. 규칙은 "태그된 섹션만 전달"이었으나 실 추출 메커니즘이 없어 사실상 전체 파일이 전달되던 문제 해결. agent별 매핑(developer/ui-builder/api-integrator → `#code-rules`+`#filesystem`+`#completion`, reviewer → `#review`+`#failure-patterns`, test-runner → `#completion`+`#failure-patterns`, refactor-architect/component-auditor → `#code-rules`)에 따라 해당 섹션만 stdout으로 반환. `CLAUDE.md` / `skills/front-agent/SKILL.md` / `constraints.md`에 사용 규칙 명문화

### v6.5: 하네스 재검증

- **`test-runner` sonnet → haiku** — Bash 실행 + 결과 요약이 주 역할. haiku로 충분, 토큰 절감
- **`constraints.md #completion` 중복 제거** — `developer.md`에 이미 6개 항목 Test Coverage Checklist 존재. 같은 내용을 두 파일에서 읽는 중복 제거
- **`tdd` 스킬 설명 수정** — front-agent는 내부적으로 `developer`를 직접 호출. `tdd`는 사용자 직접 호출용 standalone 스킬

### v6.4: 병렬 실행

- **`search-knowledge` + `component-auditor` 병렬화** — 둘 다 읽기 전용 탐색으로 독립적. feature/figma/ui 워크플로우에서 동시 실행
- **`pixel-check` + `a11y-check` 병렬화** — Figma 워크플로우에서 ui-builder 완료 후 동시 실행
- Refactor는 `search-knowledge → refactor-architect` 순서 의존성 유지 (변경 없음)
- `||` 표기로 SKILL.md 워크플로우에 병렬 지점 명시

### v6.3: 산출물 품질 강화

- **엣지 케이스 강제** — `constraints.md #completion`에 null/undefined, 빈 배열, 네트워크 실패, 로딩/에러 상태 커버 요구 추가. happy-path 테스트만으로 완료 불가
- **React 성능 안티패턴 FAIL 기준 추가** — `constraints.md #review`: useEffect 의존성 오류, 인라인 객체/함수 prop, React.memo 누락, useMemo 남용, 렌더 경로 블로킹 연산
- **로직 정확도 FAIL 기준 추가** — null/undefined 미가드 접근, async 에러 미처리, 빈 목록/경계값 미처리
- **pixel-check 체크 기준 명시** — spacing(4px grid), typography, 컬러 토큰 사용 여부, 컴포넌트 재사용, 인터랙티브 상태, 반응형 breakpoint
- `agents/reviewer.md` 워크플로우에 React 성능 + 엣지 케이스 검토 명시 (상세 기준은 constraints.md #review 온디맨드)

### v6.2: API Spec Check 추가

- **API Spec Check 단계 신설** — `feature` 인텐트 + API 키워드(`fetch`, `axios`, `GraphQL`, `mutation`, `WebSocket`, `서버`, `백엔드` 등) 감지 시 plan 전에 명세서 요청
- **지원 형식** — Swagger/OpenAPI URL, GraphQL schema, `.md`/`.yaml` 파일, 엔드포인트 직접 입력
- **토큰 최적화** — 명세서는 `api-integrator`에만 온디맨드 전달, 다른 에이전트에 전파 없음
- `CLAUDE.md` Intent Routing + `skills/front-agent/SKILL.md` Request Gate 동시 반영

### v6.1: codex-review 범위 수정 (hot-fix)

- **`changed_files` 기반 scoped diff** — `--uncommitted`/`--base main` 대신 핸드오프의 `changed_files`로 `git diff HEAD -- <files>` 생성 후 codex에 직접 전달. 다른 작업의 미커밋 변경사항 포함 안 함
- **git repo 없음 또는 빈 diff → graceful skip** — 워크플로우 블록 없이 warning만 출력
- **중복 model 섹션 제거** — SKILL.md 구버전 `--base main` 예시 정리

### v5 → v6: Codex Adversarial Review

- **`codex-review` 스킬 추가** — OpenAI Codex CLI(`o3` 모델) 기반 독립 리뷰
- **이중 게이트** — `reviewer` PASS + `codex-review` PASS 모두 통과해야 `git-commit` 진행
- **FAIL 시 유저 판단 위임** — 자동 수정 없음. Fix(재시도 1회) or Override(기록 후 진행) 선택
- **컨텍스트 설계** — plan.md Goal + reviewer Notes만 전달, constraints.md/파일 원문 제외
- `constraints.md` `#review` 섹션 + `CLAUDE.md` Runtime Rules에 이중 게이트 명시

### v4 → v5: 런타임 컨텍스트 최적화

- **CLAUDE.md 경량화** — 267줄 → 95줄. 워크플로우 반복 제거, 런타임 가드레일만 유지. 매 turn 토큰 절감
- **Skip Rules 추가** — `search-knowledge`, `component-auditor`, `api-integrator`, `save-knowledge` 조건부 스킵
- **Compact Handoff 포맷** — 에이전트 간 자유형 prose 대신 5-bullet 구조체 강제
- **런타임/문서 분리** — `README.md`는 실행 중 로드 차단, `SKILL.md`를 canonical spec으로 위임
- **레거시 에이전트 삭제** — `figma-builder`, `style-matcher`, `implementer`, `test-writer`, `orchestrator` 제거
- **PostToolUse 출력 압축** — 긴 tsc/eslint 로그 대신 에러 요약만 출력
- **session-start 훅 최적화** — 전체 knowledge 파일 대신 요약만 로드

### v3 → v4: Harness Engineering 적용

- **PostToolUse 훅** 추가 — 저장 즉시 자동 검증
- **harness_loop** 추가 — 자동 재시도 루프 (MAX 3회)
- **isAmbiguous 체크** 추가 — 모호한 요청 사전 차단
- **constraints.md** 신규 — 5섹션 태그 구조, 온디맨드 로딩, GC 규칙
- **Output constraints** 추가 — 에이전트 불필요 출력 제거
- **실패 → 규칙 루프** 추가 — 실패 패턴 자동 기록

### v2 → v3: 스킬 구조 재설계 (18개 → 14개)

- `setup`, `plan-feature`, `execute-feature` 제거 — `/front-agent` lazy setup으로 대체
- `tdd`, `search-knowledge`를 모든 워크플로우에 명시적으로 연결

---

## 고도화 방향

**완료**
- [x] Wisdom Hub — 전역 지식 허브, summary 20줄 고정
- [x] 스킬 최적화 — 15개로 통합, 워크플로우 연결
- [x] Harness Engineering v4 — PostToolUse, harness_loop, constraints.md 등 6개 구성 요소
- [x] **도구 경계 하드 강제** — .env* 하드 차단 (settings.json Deny) + config 파일 검토 요청 (PreToolUse 훅) + install.sh 자동 적용
- [x] **런타임 컨텍스트 최적화 v5** — CLAUDE.md 경량화, Skip Rules, Compact Handoff, 레거시 에이전트 정리
- [x] **Codex adversarial review v6** — `codex-review` 스킬, reviewer PASS 후 OpenAI o3 독립 검토, changed_files scoped diff
- [x] **런타임 성능 최적화 v6.6** — PostToolUse incremental/디바운스/병렬, reviewer∥codex-review, search-knowledge 콜드 스킵, constraints 섹션 추출 스크립트
- [x] **핫패스 최적화 v6.7** — 훅 `jq` 파싱, PostToolUse 테스트 파일 스킵, review fast-path, failure-patterns 시드, 캐시 TTL 정리, developer opus 승격
- [x] **rtk opt-in 통합 v6.8** — 플러그인 전용 rtk-wrap, AskUserQuestion UI 모드 선택, `/rtk` 토글 스킬, PostToolUse/test-runner/git-* 자동 라우팅 (다른 프로젝트에 무영향)
- [x] **시니어 품질 게이트 v6.9.1** — design 룰브릭(reviewer 4 카테고리), plan.md Design Check 섹션, component-auditor MANDATORY 강제, 구현 에이전트 plan Design Check 직접 참조
- [x] **failure-patterns 카테고리 + refactor 게이트 누수 차단 v6.9.2** — `#failure-patterns` `[category:*]` 태그 도입(기존 5개 시드 마이그레이션), refactor-architect의 plan Design Check in-place 갱신 책임 명시

**예정 (push 단위로 분할)**

순서대로 머지. 각 PR은 단일 관심사, 5~15분 리뷰 가능 범위.

- [ ] **v6.9.3 — 토큰 예산 측정 인프라** (push #2)
  - `hooks/extract-constraints.sh`에 `wc -c` stderr 로깅 추가, 8KB 초과 시 경고
  - `hooks/post-tool-use.sh`도 동일하게 출력 크기 stderr 로깅
  - `Context Budget` 규칙이 글이 아닌 측정값으로 검증됨 — 이후 모든 변경의 토큰 영향 가시화
  - 토큰 영향: 런타임 stderr +1줄. agent 컨텍스트엔 영향 없음
- [ ] **v6.9.4 — Quality Metrics 정량화** (push #3)
  - `agents/reviewer.md` 출력에 메트릭 블록 추가: `new_loc / reused_loc (reuse_ratio) / new_abstractions / design_verdict`
  - 매 커밋마다 시니어 품질 정량 피드백 누적, 트렌드 가시화 → "잘 되고 있는가?"가 감각이 아니라 데이터로 답해짐
  - 시니어 코드의 정의(덜 짠다 / 덜 추상화한다 / 의도 표현)를 측정 가능 지표로 환원
  - 토큰 영향: reviewer 출력 +3줄
- [ ] **v6.9.5 — 1사이클 실측 + false-FAIL 가지치기** (push #4)
  - 실제 작업 한 건(소형 UI 변경 또는 feature) 돌려서 v6.9.1~v6.9.4 게이트가 작동하는지 확인
  - design 룰브릭이 false-FAIL을 내는 항목 식별 → `constraints.md #review`에 완화 노트 누적
  - 측정 결과에 따라 다음 결정 분기:
    - 토큰 예산 초과 시 → reviewer/codex-review 책임 분리 (`reviewer`=correctness+react-perf, `codex-review`=design+scope)
    - 재사용률 낮음 → `knowledge/patterns/*.md` 카탈로그 도입으로 auditor 적중률 향상
    - false-FAIL 다수 → 룰 가지치기 또는 PASS 노트 확장
- [ ] **구조 테스트** — 의존성 규칙을 실제 테스트 코드로 강제 (장기)

---

## License

MIT
