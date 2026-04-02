# Global Constraints

> 이 파일은 모든 에이전트 호출 시 반드시 포함(pin)된다.
> AI가 실수할 때마다 새 규칙이 추가되어 점점 정교해진다.

---

## 코드 규칙

- 새 라이브러리/패키지 도입 금지 — 기존 package.json에 있는 것만 사용
- 외부 API 직접 호출 금지 — 반드시 프로젝트 내부 래퍼/서비스 레이어 통해서
- `any` 타입 사용 금지 — 모든 변수/함수에 명시적 TypeScript 타입
- inline style 금지 — Tailwind 클래스 또는 CSS 모듈 사용
- `console.log` 프로덕션 코드에 남기지 않기

## 파일시스템 경계

- `src/` — 읽기·쓰기 가능
- `config/`, `.env*` — 읽기만 가능, 수정 금지
- `node_modules/` — 접근 금지

## 완료 선언 조건

- 테스트 실행 결과 없이 완료 선언 금지
- harness_loop MAX_ATTEMPTS(3회) 초과 시 완료 선언 금지, GitHub 이슈 생성 후 보고
- reviewer PASS 없이 git-commit 진행 금지

## 구현 범위

- YAGNI: 명시적으로 요청된 것만 구현. 추측 기능 추가 금지
- 기존 작동하는 코드 수정 금지 (요청 범위 외)

---

## 자동 추가 규칙 (실패 패턴 기록)

> reviewer FAIL 또는 test-runner 3회 실패 시 여기에 자동 추가됨.

_아직 기록된 실패 패턴 없음._
