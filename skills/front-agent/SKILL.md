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

### Figma 구현
```
component-auditor (haiku)
→ figma-builder (sonnet)
→ pixel-check (sonnet)
→ a11y-check (sonnet)
→ reviewer (opus)
→ git-branch → git-commit → git-pr
```

### UI 구현 (Figma 없음)
```
component-auditor (haiku)
→ style-matcher (sonnet)
→ a11y-check (sonnet)
→ reviewer (opus)
→ git-branch → git-commit → git-pr
```

### 기능 구현
```
component-auditor (haiku)
→ test-writer (sonnet)
→ implementer (sonnet)
→ api-integrator (sonnet) [API 연결 필요 시]
→ test-runner (sonnet)
→ reviewer (opus)
→ git-branch → git-commit → git-pr
```

### 리팩토링
```
refactor-architect (opus) → plan.md 업데이트 → 사용자 재승인
→ component-auditor (haiku)
→ implementer (sonnet)
→ test-runner (sonnet)
→ reviewer (opus)
→ git-branch(refactor/) → git-commit → git-pr
```

### 코드 리뷰
```
reviewer (opus) → 결과 출력
```

---

## 완료 후

- `save-knowledge`로 이번 작업에서 배운 내용 저장
- PR URL 출력

---

## Constraints

- setup은 자동으로 처리한다. 사용자에게 `/setup`을 요구하지 않는다.
- plan.md 없이 구현을 시작하지 않는다.
- 사용자 승인 없이 실행 단계로 넘어가지 않는다.
- 테스트 없이 완료를 선언하지 않는다.
