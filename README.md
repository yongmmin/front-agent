<div align="center">

# Frontend Co-Pilot

**Claude Code 플러그인 — 7개 에이전트, 18개 온디맨드 스킬, Plan-First 워크플로우**

[![Agents](https://img.shields.io/badge/agents-7-green.svg)](#에이전트-agents)
[![Skills](https://img.shields.io/badge/skills-18-orange.svg)](#내부-에이전트-도구)
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

| 도구 | 역할 |
|------|------|
| `plan-feature` | 구현 플랜 생성 |
| `execute-feature` | 승인된 플랜 실행 |
| `implement-figma` | Figma → 코드 + 반응형 |
| `match-style` | Figma 없이 기존 스타일 매칭 |
| `pixel-check` | 구현 결과 vs 디자인 비교 |
| `tdd` | TDD 사이클: RED → GREEN → REFACTOR |
| `code-review` | 코드 품질 리뷰 |
| `a11y-check` | 접근성 검사 |
| `refactor-scan` | 반복 패턴 탐지 |
| `component-audit` | 컴포넌트 재사용 감사 |
| `save-knowledge` / `search-knowledge` | 지식 저장 및 검색 |
| `git-branch` / `git-commit` / `git-pr` / `git-issue` | Git 자동화 |
| `setup` | 프로젝트 초기화 (Lazy — 자동 실행) |

---

## 워크플로우

### Figma 구현

```
component-auditor → ui-builder (Figma MCP + 반응형) → pixel-check → a11y-check → reviewer
→ git-branch → git-commit → git-pr
```

### 기능 구현

```
component-auditor → developer (테스트 + 구현) → api-integrator → test-runner → reviewer
→ git-branch → git-commit → git-pr
```

### 디자인 없는 UI

```
component-auditor → ui-builder (기존 스타일 매칭) → a11y-check → reviewer
→ git-branch → git-commit → git-pr
```

### 리팩토링

```
refactor-architect (패턴 탐지 → plan.md) → 사용자 승인
→ component-auditor → implementer → test-runner → reviewer
→ git-branch → git-commit → git-pr
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

## 성과 — 직접 구현 vs 플러그인 구현 비교

로그인 페이지를 플러그인 없이 직접 구현한 버전과, `/front-agent`로 생성한 버전을 비교했다.

### 접근성 (a11y-check 에이전트 효과)

| 항목 | 직접 구현 | 플러그인 구현 |
|------|-----------|-------------|
| 탭 버튼 | 속성 없음 | `aria-selected` |
| 역할 버튼 (학생/교사) | 속성 없음 | `aria-pressed` |
| 비밀번호 토글 | 속성 없음 | `aria-label="비밀번호 보기/숨기기"` |
| 체크박스 패턴 | `<button>` 으로 구현 | `<label htmlFor>` + `<input className="sr-only">` (스크린리더 지원) |
| 키보드 포커스 | 기본 브라우저 스타일 | `focus:ring-2 focus:ring-[#fc7f75]` (브랜드 컬러 포커스 링) |

### UI 디테일

| 항목 | 직접 구현 | 플러그인 구현 |
|------|-----------|-------------|
| 로고 원형 | `border` 테두리만 | `bg-[#fc7f75]` 채워진 원 (Figma 디자인 일치) |
| 체크박스 아이콘 | lucide `<Check />` 컴포넌트 | 커스텀 SVG (픽셀 단위 제어) |

### 요약

직접 구현은 레이아웃·색상은 동일하지만, **접근성 속성이 누락**되고 **시맨틱 HTML 패턴이 불완전**했다.
플러그인은 `a11y-check` 에이전트가 자동으로 ARIA 속성을 추가하고, 스크린리더 대응 체크박스 패턴을 적용했다.
Figma 디자인 토큰(브랜드 컬러 #fc7f75)도 로고·포커스 링에 일관되게 반영됐다.

---

## 고도화 방향

- [x] **Wisdom Hub** — `~/.front-agent/wisdom/` 전역 지식 허브, summary 20줄 고정으로 토큰 최소화
- [ ] **Obsidian 연동** — Wisdom Hub를 Obsidian vault로 교체, 그래프 뷰·wikilink 추적성 확보
- [ ] **Codex CLI 통합** — 독립 adversarial 코드 리뷰로 self-review 편향 제거
- [ ] **Lighthouse CI 연동** — 성능 지표 자동 검사

---

## License

MIT
