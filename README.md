<div align="center">

# Frontend Co-Pilot

**Claude Code 플러그인 — 7개 에이전트, 15개 스킬, Harness Engineering**

[![Agents](https://img.shields.io/badge/agents-7-green.svg)](#에이전트)
[![Skills](https://img.shields.io/badge/skills-15-orange.svg)](#스킬)
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
  codex-review git-branch git-commit git-pr git-issue; do
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
  → Lazy Setup — knowledge/index.md 없으면 자동 초기화 (최초 1회)
  → isAmbiguous 체크 — 모호하면 명확화 질문 (최대 2개)
  → Figma 체크 — ui 인텐트인데 URL 없으면 요청
  → search-knowledge? (haiku) — 지식 있을 때만 로드
  → component-auditor? (haiku) — UI 작업 시만 실행
  → plan.md 생성 + 사용자 승인
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

| 인텐트 | 워크플로우 |
|--------|----------|
| `feature` | `search-knowledge? → component-auditor? → developer → test-runner → api-integrator? → reviewer → codex-review → git-*` |
| `figma` | `search-knowledge? → component-auditor → ui-builder → pixel-check → a11y-check → reviewer → codex-review → git-*` |
| `ui` | `search-knowledge? → component-auditor → ui-builder → a11y-check → reviewer → codex-review → git-*` |
| `refactor` | `search-knowledge? → refactor-architect → 사용자 재승인 → component-auditor? → developer → test-runner → reviewer → codex-review → git-*` |
| `review` | `reviewer` |

---

## 에이전트

| Agent | Model | Role |
|-------|-------|------|
| `component-auditor` | haiku | 재사용 가능 컴포넌트 탐색 |
| `developer` | sonnet | TDD 기반 기능 구현 (test-writer + implementer 통합) |
| `ui-builder` | sonnet | Figma 또는 기존 스타일 기반 UI 구현 (figma-builder + style-matcher 통합) |
| `api-integrator` | sonnet | UI-API 연결 + 로딩/에러 상태 처리 |
| `test-runner` | sonnet | 테스트 실행 + MAX_ATTEMPTS 초과 시 GitHub 이슈 생성 |
| `reviewer` | opus | 코드 품질, TypeScript, 보안 리뷰 |
| `refactor-architect` | opus | 반복 패턴 탐지 + 리팩토링 설계 |

---

## 스킬

사용자는 `/front-agent`만 사용한다. 나머지는 front-agent가 자동 호출한다.

| 스킬 | 호출 시점 |
|------|----------|
| `search-knowledge` | Step 0 — 지식 있을 때만 (조건부) |
| `component-audit` | UI/기능 구현 전 — 조건부 |
| `tdd` | 기능 구현 / 리팩토링 |
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
| `component-auditor` | 리뷰 전용 태스크 또는 UI 변경 없는 순수 API 연결 |
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

**예정**
- [ ] **구조 테스트** — 의존성 규칙을 실제 테스트 코드로 강제

---

## License

MIT
