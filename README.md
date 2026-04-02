<div align="center">

# Frontend Co-Pilot

**Claude Code 플러그인 — 7개 에이전트, 14개 스킬, Harness Engineering**

[![Agents](https://img.shields.io/badge/agents-7-green.svg)](#에이전트)
[![Skills](https://img.shields.io/badge/skills-14-orange.svg)](#스킬)
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
  git-branch git-commit git-pr git-issue; do
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
  → isAmbiguous 체크 — 모호하면 명확화 질문 (최대 2개)
  → search-knowledge (haiku) — 관련 패턴/컴포넌트/결정사항 로드
  → component-auditor (haiku) — 재사용 가능 컴포넌트 탐색
  → plan.md 생성 + 사용자 승인
  → [인텐트별 실행: feature / figma / ui / refactor]
  → reviewer (opus) — 코드 품질/TypeScript/보안 리뷰
  → git-branch → git-commit → git-pr
  → save-knowledge
```

---

## 에이전트

| Agent | Model | Role |
|-------|-------|------|
| `component-auditor` | haiku | 재사용 가능 컴포넌트 탐색 |
| `developer` | sonnet | TDD 기반 기능 구현 (test-writer + implementer 통합) |
| `ui-builder` | sonnet | Figma 또는 기존 스타일 기반 UI 구현 (figma-builder + style-matcher 통합) |
| `api-integrator` | sonnet | UI-API 연결 + 로딩/에러 상태 처리 |
| `test-runner` | sonnet | 테스트 실행 + 실패 시 GitHub 이슈 생성 |
| `reviewer` | opus | 코드 품질, TypeScript, 보안 리뷰 |
| `refactor-architect` | opus | 반복 패턴 탐지 + 리팩토링 설계 |

---

## 스킬

사용자는 `/front-agent`만 사용한다. 나머지는 front-agent가 자동 호출한다.

| 스킬 | 호출 시점 |
|------|----------|
| `search-knowledge` | **모든 워크플로우 Step 0** |
| `tdd` | 기능 구현 / 리팩토링 |
| `implement-figma` / `match-style` | UI 구현 |
| `pixel-check` / `a11y-check` | UI 구현 후 검증 |
| `code-review` | 모든 구현 후 |
| `refactor-scan` | 리팩토링 |
| `component-audit` | UI/기능 구현 전 |
| `save-knowledge` | 작업 완료 후 |
| `git-branch` / `git-commit` / `git-pr` / `git-issue` | 구현 완료 후 |

---

## 하네스 엔지니어링 (Harness Engineering)

> "AI가 실수했을 때, 프롬프트를 고치지 마세요. 마구(harness)를 고치세요."

AI의 실수가 구조적으로 반복 불가능하도록 시스템을 바꾸는 기법. v4에서 적용됨.

| 구성 요소 | 파일 | 역할 |
|----------|------|------|
| **PostToolUse 훅** | `hooks/post-tool-use.sh` | `.ts/.tsx` 저장 시 tsc + eslint 자동 실행, 에러 즉시 피드백 |
| **harness_loop** | `skills/front-agent/SKILL.md` | 테스트 실패 → 에러 피드백 → 재시도 (MAX 3회), 초과 시 GitHub 이슈 생성 |
| **isAmbiguous** | `skills/front-agent/SKILL.md` | plan 전 모호한 요청 감지 → 명확화 질문 강제 |
| **constraints.md** | `constraints.md` | 5개 섹션 태그(`#code-rules` 등), 에이전트별 온디맨드 로딩 |
| **Output constraints** | `agents/*.md` | 에이전트 "코드만 출력" 강제, 설명·요약 금지 |
| **실패 → 규칙 루프** | `agents/reviewer.md`, `agents/test-runner.md` | 반복 실패 패턴을 `constraints.md`에 자동 기록 |

### constraints.md 온디맨드 구조

전체를 모든 에이전트에 주입하지 않는다. 에이전트별 필요한 섹션만 선택 전달:

| 에이전트 | 받는 섹션 |
|---------|---------|
| developer / ui-builder / api-integrator | `#code-rules` + `#filesystem` + `#completion` |
| test-runner | `#completion` + `#failure-patterns` |
| reviewer | `#review` + `#failure-patterns` |
| component-auditor | 없음 |

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
- [x] 스킬 최적화 — 14개로 통합, 워크플로우 연결
- [x] Harness Engineering v4 — PostToolUse, harness_loop, constraints.md 등 6개 구성 요소
- [x] **도구 경계 하드 강제** — .env* 하드 차단 (settings.json Deny) + config 파일 검토 요청 (PreToolUse 훅) + install.sh 자동 적용

**예정**
- [ ] **Codex adversarial review** — 다른 AI로 독립 검토, self-review 편향 제거
- [ ] **구조 테스트** — 의존성 규칙을 실제 테스트 코드로 강제
- [ ] **Obsidian 연동** — Wisdom Hub를 Obsidian vault로 교체
- [ ] **Lighthouse CI 연동** — 성능 지표 자동 검사

---

## License

MIT
