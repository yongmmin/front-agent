---
name: front-agent
description: Single entry point for all frontend tasks. Natural language → auto plan → execute.
---

# Skill: front-agent

**Trigger**: `/front-agent [자연어 요청]`
**Purpose**: 하나의 명령으로 setup → 인텐트 감지 → Figma URL 확인 → plan → 실행까지 자동 처리.

---

## 전체 흐름

```
/front-agent "로그인 폼 만들어줘"
       ↓
1. 프로젝트 자동 감지 (lazy setup)
2. 인텐트 분류
3. UI 작업이면 → "Figma URL 있으신가요?" 질문
4. plan.md 생성 후 사용자 승인 대기
5. 승인 → 에이전트 오케스트레이션 실행
```

---

## Step 1: 프로젝트 자동 감지 (Lazy Setup)

`knowledge/index.md`가 없으면 자동으로 setup을 실행한다. 사용자에게 `/setup`을 요구하지 않는다.

```
- package.json 읽기 → 스택 감지 (Next.js, React, TypeScript, Tailwind 등)
- knowledge/ 디렉토리 초기화
- component-auditor (haiku) 실행 → knowledge/components.md 생성
- gh auth status, git remote -v 확인
```

setup이 이미 완료된 경우 이 단계를 건너뛴다.

---

## Step 2: 인텐트 분류

요청 내용을 분석해 아래 중 하나로 분류한다:

| 인텐트 | 키워드 예시 | 워크플로우 |
|--------|------------|-----------|
| `figma` | figma.com URL 포함 | Figma 구현 |
| `ui` | 만들어줘, 폼, 버튼, 페이지, 화면, 컴포넌트 | UI 구현 (Figma URL 질문) |
| `feature` | 기능, 추가, 연결, API, 로직 | 기능 구현 |
| `refactor` | 리팩토링, 정리, 개선, 중복 | 리팩토링 |
| `review` | 리뷰, 검토, 확인해줘 | 코드 리뷰 |

---

## Step 3: Figma URL 확인 (UI/Figma 인텐트일 때만)

인텐트가 `ui` 또는 `figma`이고, 요청에 figma.com URL이 없으면:

> "Figma URL이 있으신가요? 있으면 붙여넣어 주세요. 없으면 '없어요'라고 하시면 기존 스타일에 맞춰 구현합니다."

- URL 받은 경우 → `figma` 워크플로우
- "없어요" / URL 없는 경우 → `ui` 워크플로우 (style-matcher 사용)

---

## Step 4: plan.md 생성 및 승인

분류된 인텐트에 맞는 plan.md를 생성한다.

```markdown
# Plan: [작업명]

## 목표
[무엇을 왜 만드는지]

## 인텐트
[figma / ui / feature / refactor]

## Figma
[URL 또는 "없음 — 기존 스타일 매칭"]

## 재사용 가능 컴포넌트
- [component] ([파일]) — [활용 방식]

## 영향 파일
- [경로] — [변경 내용]

## 실행 단계
- Step 1: [에이전트] — [작업]
- ...

## 브랜치
[feat|ui|fix|refactor]/[작업명]

## 커밋 단위
- [type]: [설명]
```

plan.md 생성 후:
> "plan.md를 확인해주세요. 진행할까요?"

사용자가 승인("응", "ㅇㅇ", "진행해", "ok", "yes" 등)하면 Step 5로 이동한다.

---

## Step 5: 워크플로우별 에이전트 실행

> **CRITICAL**: 오케스트레이터(나)는 절대 직접 코드를 작성하거나 파일을 수정하지 않는다.
> 모든 구현은 반드시 `Agent` 툴로 서브에이전트를 spawn해서 처리한다.
> Write/Edit 툴은 오직 plan.md 작성에만 허용된다.

각 에이전트를 호출할 때는 해당 에이전트 파일(`agents/*.md`) 내용을 프롬프트에 포함하고,
현재까지의 컨텍스트(plan.md 내용, 이전 에이전트 결과)를 함께 전달한다.

> **모든 워크플로우 공통 Step 0**: `search-knowledge (haiku)` — 관련 패턴/컴포넌트/결정사항 먼저 로드

### Figma 구현
```
0. Skill(search-knowledge, model=haiku)  — 관련 지식 로드
1. Agent(component-auditor, model=haiku) — 재사용 컴포넌트 탐색
2. Agent(ui-builder, model=sonnet)       — Figma MCP로 디자인 구현 + 반응형
3. Agent(ui-builder, model=sonnet)       — pixel-check: 디자인 vs 구현 비교
4. Agent(ui-builder, model=sonnet)       — a11y-check: 접근성 검사
5. Agent(reviewer, model=opus)           — 코드 리뷰
6. Agent(git-branch → git-commit → git-pr)
```

### UI 구현 (Figma 없음)
```
0. Skill(search-knowledge, model=haiku)  — 관련 지식 로드
1. Agent(component-auditor, model=haiku) — 재사용 컴포넌트 탐색
2. Agent(ui-builder, model=sonnet)       — 기존 스타일 매칭 후 구현
3. Agent(ui-builder, model=sonnet)       — a11y-check: 접근성 검사
4. Agent(reviewer, model=opus)           — 코드 리뷰
5. Agent(git-branch → git-commit → git-pr)
```

### 기능 구현
```
0. Skill(search-knowledge, model=haiku)  — 관련 지식 로드
1. Agent(component-auditor, model=haiku) — 재사용 컴포넌트 탐색
2. Skill(tdd, model=sonnet)              — RED→GREEN→REFACTOR TDD 사이클 전담
3. Agent(api-integrator, model=sonnet)   — API 연결 (필요 시)
4. Agent(reviewer, model=opus)           — 코드 리뷰
5. Agent(git-branch → git-commit → git-pr)
```

### 리팩토링
```
0. Skill(search-knowledge, model=haiku)  — 관련 지식 로드
1. Agent(refactor-architect, model=opus) — 패턴 탐지 → plan.md 업데이트
2. 사용자 재승인 대기
3. Agent(component-auditor, model=haiku) — 재사용 컴포넌트 확인
4. Skill(tdd, model=sonnet)              — 리팩토링 구현 + 테스트 검증
5. Agent(reviewer, model=opus)           — 코드 리뷰
6. Agent(git-branch(refactor/) → git-commit → git-pr)
```

### 코드 리뷰
```
1. Agent(reviewer, model=opus) → 결과 출력
```

---

## 완료 후

- `save-knowledge`로 이번 작업에서 배운 내용 저장
- PR URL 출력

---

## Constraints

- **오케스트레이터는 절대 직접 코드를 작성하지 않는다. 위반 시 즉시 중단.**
- plan.md 작성 외에 Write/Edit 툴을 사용하지 않는다.
- 각 에이전트 호출 시 agents/*.md 내용과 현재 컨텍스트를 프롬프트에 포함한다.
- setup은 자동으로 처리한다. 사용자에게 `/setup`을 요구하지 않는다.
- plan.md 없이 구현을 시작하지 않는다.
- 사용자 승인 없이 실행 단계로 넘어가지 않는다.
- 테스트 없이 완료를 선언하지 않는다.
