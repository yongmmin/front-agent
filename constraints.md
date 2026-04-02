# Global Constraints

> **온디맨드 로딩 원칙**: 이 파일 전체를 모든 에이전트에 주지 않는다.
> 각 에이전트는 자신의 역할에 해당하는 섹션 태그만 받는다.
> 
> | 섹션 태그 | 로드 대상 에이전트 |
> |----------|-----------------|
> | `#code-rules` | developer, ui-builder, api-integrator |
> | `#filesystem` | developer, ui-builder, api-integrator |
> | `#completion` | developer, ui-builder, api-integrator, test-runner |
> | `#review` | reviewer |
> | `#failure-patterns` | reviewer, test-runner |
>
> **GC 규칙**: 이 파일이 50줄을 초과하면 `#failure-patterns` 섹션에서
> 90일 이상 된 항목을 삭제하고, 유사 규칙은 하나로 병합한다.

---

## #code-rules

- 새 라이브러리/패키지 도입 금지 — 기존 package.json에 있는 것만 사용
- 외부 API 직접 호출 금지 — 프로젝트 내부 래퍼/서비스 레이어 통해서만
- `any` 타입 사용 금지 — 모든 변수/함수에 명시적 TypeScript 타입 필수
- inline style 금지 — Tailwind 클래스 또는 CSS 모듈 사용
- `console.log` 프로덕션 코드에 남기지 않기
- YAGNI: 명시적으로 요청된 것만 구현. 추측 기능 추가 금지

---

## #filesystem

- `src/` — 읽기·쓰기 가능
- `config/`, `.env*` — 읽기만 가능, 수정 금지
- `node_modules/` — 접근 금지
- 요청 범위 외 기존 작동 코드 수정 금지

---

## #completion

- 테스트 실행 결과 없이 완료 선언 금지
- harness_loop MAX_ATTEMPTS(3회) 초과 시 완료 선언 금지 → GitHub 이슈 생성 후 보고
- 코드만 출력. 설명·요약·"여기서 X를 했습니다" 서술 금지

---

## #review

- reviewer PASS 없이 git-commit 진행 금지
- FAIL 판정 시 반복 가능한 패턴이면 `#failure-patterns` 섹션에 규칙 추가
- 일회성 실수(오타, 특수 상황)는 패턴으로 기록하지 않음

---

## #failure-patterns

> AI가 실수할 때마다 reviewer 또는 test-runner가 여기에 자동 추가.
> 형식: `- [YYYY-MM-DD] [패턴 설명] — [구체적 금지 규칙]`

_아직 기록된 실패 패턴 없음._
