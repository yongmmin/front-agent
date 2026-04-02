<div align="center">

# Frontend Co-Pilot

**Claude Code 플러그인 — 7개 에이전트, 14개 온디맨드 스킬, Plan-First 워크플로우**

[![Agents](https://img.shields.io/badge/agents-7-green.svg)](#에이전트-agents)
[![Skills](https://img.shields.io/badge/skills-14-orange.svg)](#내부-에이전트-도구)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](LICENSE)
[![Stack](https://img.shields.io/badge/stack-React%20%2F%20Next.js-61DAFB.svg)](#호환-스택)

*오케스트레이터가 전문 에이전트에게 위임하고, 세션 간 지식을 축적하는 React/Next.js 개발 자동화 플러그인*

</div>

---

## 사용법 — 명령어 하나

```
/front-agent [자연어 요청]
```

```
/front-agent 로그인 폼 만들어줘
/front-agent https://figma.com/design/xxx 이 화면 구현해줘
/front-agent 결제 기능 추가해줘
/front-agent 이 코드 리팩토링해줘
/front-agent 코드 리뷰해줘
```

이게 전부다. setup, plan, execute를 따로 입력할 필요 없다.

---

## 필수 도구 (Prerequisites)

| 도구 | 필요성 | 비고 |
|------|--------|------|
| **Claude Code** | 필수 | Anthropic 공식 CLI |
| **Node.js** | 필수 | React/Next.js 프로젝트 실행 |
| **gh CLI** | 필수 | Git 자동화 (브랜치, 커밋, PR, 이슈) |
| **[Figma MCP](https://github.com/anthropics/claude-code/tree/main/packages/mcp-server-figma)** | Figma 구현 시 | Claude Code MCP 설정에서 구성 |

```bash
# gh CLI 설치 및 인증
brew install gh && gh auth login
```

---

## 설치 가이드 (Installation)

```bash
# 1. 저장소 클론
git clone https://github.com/yongmmin/front-agent.git ~/claude-plugins/fe-copilot

# 2. 스킬 심볼릭 링크 일괄 설정
cd ~/claude-plugins/fe-copilot
for skill in front-agent plan-feature execute-feature implement-figma match-style tdd \
  code-review a11y-check pixel-check refactor-scan component-audit \
  save-knowledge search-knowledge git-branch git-commit git-pr git-issue setup; do
  ln -sf "$(pwd)/skills/$skill" ~/.claude/skills/$skill
  echo "Use the $skill skill. Arguments: \$ARGUMENTS" > ~/.claude/commands/$skill.md
done
```

> **Note**: 프로젝트를 이동했다면 심볼릭 링크가 깨질 수 있습니다. 위 스크립트를 다시 실행하면 됩니다.

---

## 핵심 원칙 (Core Principles)

1. **Conductor, not Performer** — 오케스트레이터는 직접 코드를 작성하지 않고 전문 에이전트에게 위임합니다.
2. **Evidence before Claims** — "완료"라고 선언하기 전에 반드시 테스트 실행 결과를 확보합니다.
3. **YAGNI** — 명시적으로 요청된 것만 구현합니다. 추측에 의한 기능 추가를 금지합니다.
4. **Reuse First** — UI 작업 전 반드시 `component-auditor`를 실행해 기존 컴포넌트를 재사용합니다.
5. **Token Efficiency** — 작업 복잡도에 맞는 모델을 자동 선택합니다. (`haiku` / `sonnet` / `opus`)

---

## 동작 흐름

```
/front-agent [요청]
       ↓
1. 프로젝트 자동 감지 (Lazy Setup)
2. 인텐트 분류 (ui / figma / feature / refactor / review)
3. UI 작업이면 → "Figma URL 있으신가요?" 질문
4. plan.md 생성 후 사용자 승인 대기
5. 승인 → 에이전트 오케스트레이션 실행
6. 완료 → knowledge/ 저장
```

---

## 에이전트 (Agents)

토큰 사용량 최소화를 위해 유사 역할을 통합했습니다. 에이전트 호출 횟수가 줄면 세션 간 컨텍스트 전달 오버헤드도 줄어듭니다.

| Agent | Model | Role | 통합 내용 |
|-------|-------|------|----------|
| `component-auditor` | haiku | UI 작업 전 재사용 가능 컴포넌트 탐색 | — |
| `developer` | sonnet | 테스트 작성 + 기능 구현 (TDD RED → GREEN) | test-writer + implementer |
| `ui-builder` | sonnet | Figma 또는 기존 스타일 기반 UI 구현 + 반응형 | figma-builder + style-matcher |
| `api-integrator` | sonnet | UI-API 연결 + 로딩/에러 상태 처리 | — |
| `test-runner` | sonnet | 테스트 실행, 실패 시 GitHub 이슈 생성 | — |
| `reviewer` | opus | 코드 품질, TypeScript, 보안 리뷰 | — |
| `refactor-architect` | opus | 반복 패턴 탐지, 모듈화 설계안 작성 | — |

---

## 내부 에이전트 도구

사용자는 `/front-agent`만 사용한다. 아래는 front-agent가 내부적으로 자동 호출하는 도구 목록이다.

| 도구 | 역할 | 호출 시점 |
|------|------|----------|
| `search-knowledge` | 관련 패턴/컴포넌트/결정사항 로드 | **모든 워크플로우 Step 0** |
| `tdd` | RED→GREEN→REFACTOR TDD 사이클 전담 | 기능 구현 / 리팩토링 |
| `implement-figma` | Figma → 코드 + 반응형 | Figma 구현 |
| `match-style` | Figma 없이 기존 스타일 매칭 | UI 구현 |
| `pixel-check` | 구현 결과 vs 디자인 비교 | Figma 구현 후 |
| `a11y-check` | 접근성 검사 | UI 구현 후 |
| `code-review` | 코드 품질 리뷰 | 모든 구현 후 |
| `refactor-scan` | 반복 패턴 탐지 | 리팩토링 |
| `component-audit` | 컴포넌트 재사용 감사 | UI/기능 구현 전 |
| `save-knowledge` | 지식 저장 | 작업 완료 후 |
| `git-branch` / `git-commit` / `git-pr` / `git-issue` | Git 자동화 | 구현 완료 후 |

---

## 워크플로우

> **모든 워크플로우 공통**: Step 0으로 `search-knowledge`를 먼저 실행해 관련 패턴/컴포넌트/결정사항을 로드한다.

### Figma 구현

```
search-knowledge → component-auditor → ui-builder (Figma MCP + 반응형)
→ pixel-check → a11y-check → reviewer
→ git-branch → git-commit → git-pr
```

### 기능 구현

```
search-knowledge → component-auditor → tdd (RED→GREEN→REFACTOR)
→ api-integrator → reviewer
→ git-branch → git-commit → git-pr
```

### 디자인 없는 UI

```
search-knowledge → component-auditor → ui-builder (기존 스타일 매칭)
→ a11y-check → reviewer
→ git-branch → git-commit → git-pr
```

### 리팩토링

```
search-knowledge → refactor-architect (패턴 탐지 → plan.md) → 사용자 승인
→ component-auditor → tdd (구현 + 테스트 검증)
→ reviewer → git-branch(refactor/) → git-commit → git-pr
```

---

## 지식 시스템 (Knowledge System)

두 계층으로 분리되어 있습니다.

### 1. 전역 Wisdom Hub — `~/.front-agent/wisdom/`

모든 프로젝트가 공유하는 허브. 설치 시 자동 생성됩니다.

```
~/.front-agent/wisdom/
├── summary.md      ← 세션 시작 시 자동 로드 (20줄 고정)
├── learnings.md    ← 작업에서 얻은 교훈 (온디맨드)
├── decisions.md    ← 설계/아키텍처 결정 사항 (온디맨드)
└── issues.md       ← 알려진 문제, 주의사항 (온디맨드)
```

**핵심 설계: summary.md만 자동 로드**

매 세션 시작 시 `summary.md`(최대 20줄)만 컨텍스트에 주입하고, `learnings/decisions/issues.md`는 필요할 때만 로드합니다. 지식이 쌓여도 토큰 소비가 늘어나지 않습니다.

```
세션 시작
  → summary.md (20줄 고정)    ← 항상 로드
  → knowledge/index.md        ← 프로젝트 컨텍스트

작업 중 필요 시
  → learnings.md / decisions.md / issues.md  ← 온디맨드
```

**장점**
- 프로젝트 A에서 배운 것이 프로젝트 B에서도 자동 참조됨
- summary.md 20줄 고정으로 토큰 소비 일정하게 유지
- 시간이 지날수록 에이전트가 팀 맥락을 더 잘 이해함

**단점**
- summary.md가 20줄 제한이라 모든 지식을 담지 못함 (의도적 트레이드오프)
- 상세 wisdom은 직접 `/search-knowledge`로 조회해야 함

### 2. 프로젝트 Knowledge — `knowledge/`

현재 프로젝트 전용. Git에 포함되어 팀원과 공유 가능.

```
knowledge/
└── index.md    ← 컴포넌트, 패턴, 디자인 규칙 (300줄 제한)
```

- **자동 로드**: 세션 시작 시 `session-start` 훅이 자동 주입
- **수동 저장**: `/save-knowledge`로 학습 내용 저장
- **300줄 규칙**: 초과 시 도메인 서브파일로 분리

---

## Git 자동화 (Git Automation)

| 작업 유형 | 브랜치 패턴 |
|-----------|------------|
| 기능 구현 | `feat/feature-name` |
| 버그 수정 | `fix/bug-name` |
| 리팩토링 | `refactor/target` |
| 재설계 | `redesign/component-name` |
| UI 구현 | `ui/component-name` |

- 커밋: [Conventional Commits](https://www.conventionalcommits.org/) 형식 자동 적용
- PR: 변경 내용 요약과 테스트 플랜 체크리스트 자동 생성
- 테스트 실패: GitHub 이슈 자동 생성

---

## 모델 라우팅

| 모델 | 사용 작업 |
|------|----------|
| `haiku` | 파일 탐색, 검색, component-auditor |
| `sonnet` | 기능 구현, 테스트 작성, UI 구현, API 연결 |
| `opus` | 플랜 작성, 코드 리뷰, 리팩토링 설계, 오케스트레이션 |

---

## 호환 스택

- **React** / **Next.js** (App Router)
- **TypeScript**
- **Tailwind CSS**
- **Vitest** 또는 **Jest** + React Testing Library
- **GitHub** (gh CLI 필요)

---

## 스킬 최적화 기록

### v2 → v3: 스킬 구조 재설계 (18개 → 14개)

#### 삭제된 스킬 (구형 워크플로우 잔재)

| 스킬 | 삭제 이유 |
|------|----------|
| `setup` | `/front-agent` lazy setup이 완전히 대체. 사용자가 직접 호출할 필요 없음 |
| `plan-feature` | `/front-agent`가 plan.md를 직접 생성하는 구조로 변경되어 불필요 |
| `execute-feature` | `/front-agent`가 오케스트레이션 전담으로 변경되어 불필요 |
| `developer` (에이전트) | `tdd` 스킬로 역할 이전. test-writer + implementer 통합이었지만 RED→GREEN→REFACTOR 구조화가 부족했음 |

#### 연결된 스킬 (있었지만 워크플로우에 미연결 상태였음)

| 스킬 | 기존 문제 | 수정 내용 |
|------|----------|----------|
| `tdd` | `developer` 에이전트 내부에서 비구조적으로 TDD를 수행. RED→GREEN→REFACTOR 각 단계 명시 없음 | 기능 구현 / 리팩토링 워크플로우에서 `developer` 대신 `tdd` 스킬 직접 호출로 변경 |
| `search-knowledge` | 워크플로우 어디에도 없어 기존 패턴/컴포넌트/결정사항이 구현 시작 전에 로드되지 않음 | **모든 워크플로우 Step 0**으로 추가. haiku 모델로 최소 토큰 소비 |

#### 최적화 효과

- **tdd 연결**: 기능 구현 시 RED(테스트 작성 → 실패 확인) → GREEN(최소 구현 → 통과) → REFACTOR(코드 정리 → 재검증) 단계가 명시적으로 실행됨. 이전엔 단계 생략 가능성 있었음
- **search-knowledge Step 0**: 구현 전에 이미 존재하는 유사 컴포넌트, 이전 결정사항, 알려진 이슈를 먼저 확보. 중복 구현 방지 + 일관성 향상. haiku 모델 사용으로 토큰 오버헤드 최소화
- **스킬 수 감소**: 18개 → 14개. 각 스킬이 워크플로우에서 명확한 호출 시점을 가짐

---

## 고도화 방향

- [x] **Wisdom Hub** — `~/.front-agent/wisdom/` 전역 지식 허브, summary 20줄 고정으로 토큰 최소화
- [x] **스킬 최적화** — 미연결 스킬(tdd, search-knowledge) 워크플로우 통합, 구형 스킬(setup, plan-feature, execute-feature) 제거
- [ ] **Obsidian 연동** — Wisdom Hub를 Obsidian vault로 교체, 그래프 뷰·wikilink 추적성 확보
- [ ] **Codex CLI 통합** — 독립 adversarial 코드 리뷰로 self-review 편향 제거
- [ ] **Lighthouse CI 연동** — 성능 지표 자동 검사

---

## License

MIT
