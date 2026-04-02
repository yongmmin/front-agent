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

## Step 1.5: 모호성 체크 (isAmbiguous)

인텐트 분류 전에 요청이 충분히 명확한지 판단한다.
아래 조건 중 하나라도 해당하면 plan 생성 전에 명확화 질문을 한다.

### 모호한 요청 조건
- 대상이 불명확 ("버튼 고쳐줘" — 어떤 버튼?)
- API 스펙 없이 "연결해줘" / "붙여줘"
- 범위가 과도하게 광범위 ("전부", "다", "전체적으로")
- 기술 선택이 모호 ("최적화해줘", "개선해줘" — 무엇을? 성능? 코드 품질?)
- 요구사항이 2개 이상 혼재 (한 번에 너무 많은 것을 요청)

### 명확화 질문 형식
모호한 요청을 받으면 아래 형식으로 되묻고, 답변을 받은 뒤 Step 2로 진행한다.

> "[요청의 어떤 부분]이 명확하지 않습니다. 아래를 알려주시면 바로 진행하겠습니다:
> 1. [구체적 질문 1]
> 2. [구체적 질문 2 (필요 시)]"

**중요**: 질문은 최대 2개까지만. 명확한 요청은 이 단계를 건너뛴다.

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

> **Context Manager 규칙**: 각 에이전트를 spawn할 때 아래를 프롬프트 앞에 포함한다:
> 1. CLAUDE.md의 에이전트별 컨텍스트 선택 표에서 해당 에이전트의 constraints 섹션
> 2. plan.md 내용
> 3. 이전 에이전트의 결과 (있을 경우)
>
> **절대 금지**: constraints.md 전체를 한 번에 포함하지 않는다.
> **절대 금지**: 관련 없는 파일을 컨텍스트에 포함하지 않는다.

각 에이전트를 호출할 때:
1. 해당 에이전트 파일(`agents/*.md`) 내용
2. CLAUDE.md 컨텍스트 선택 표에서 해당 에이전트의 constraints 섹션만 발췌
3. plan.md 내용
4. 이전 에이전트 결과 (있을 경우)
— 이 4가지만 포함한다. 더 넣지 않는다.

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

## harness_loop: 자동 교정 루프

> **이것이 하네스의 심장부다.** 테스트를 통과하기 전까지 에이전트는 완료를 선언할 수 없다.

### 동작 방식

```
MAX_ATTEMPTS = 3
attempt = 0

while attempt < MAX_ATTEMPTS:
  1. 구현 에이전트 실행 (developer / ui-builder)
  2. test-runner로 자동 검증
  
  if 테스트 통과:
    → reviewer 에이전트로 진행
    → 완료
  else:
    attempt++
    에러 메시지를 구현 에이전트에게 피드백
    "다음 에러를 수정해주세요: [에러 내용]"

if attempt >= MAX_ATTEMPTS:
  → git-issue 자동 생성 (제목: [HARNESS FAIL] + 작업명)
  → 사용자에게 보고 후 중단
```

### 에이전트 호출 시 에러 피드백 형식

재시도 시 구현 에이전트에게 전달할 컨텍스트:
```
이전 구현이 다음 에러를 발생시켰습니다 (시도 {attempt}/3):

[에러 내용]

위 에러만 수정하세요. 다른 코드는 건드리지 마세요.
```

### 적용 워크플로우

- **기능 구현**: tdd 에이전트 실행 → test-runner 검증 → 실패 시 재시도
- **UI 구현**: ui-builder 실행 → (테스트 있을 경우) test-runner 검증 → 실패 시 재시도
- **리팩토링**: tdd 실행 → test-runner 검증 → 실패 시 재시도

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
- harness_loop를 건너뛰고 완료를 선언하지 않는다.
- isAmbiguous 체크를 건너뛰지 않는다. 모호한 요청은 반드시 되묻는다.
- MAX_ATTEMPTS(3회) 초과 시 반드시 git-issue를 생성하고 사용자에게 보고한다.
