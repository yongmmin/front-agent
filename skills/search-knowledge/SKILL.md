---
name: search-knowledge
description: Search the knowledge base and global wisdom hub for relevant information
---

# Skill: search-knowledge

**Trigger**: `/search-knowledge [query]` or auto-called by agents needing context
**Purpose**: 프로젝트 knowledge/와 전역 wisdom hub(`~/.front-agent/wisdom/`)에서 관련 정보를 검색한다.

---

## 검색 우선순위

1. `~/.front-agent/wisdom/summary.md` — 항상 로드 (20줄, 최소 토큰)
2. `knowledge/index.md` — 프로젝트 컨텍스트
3. 쿼리에 따라 상세 파일 선택 로드:
   - 교훈 관련 → `~/.front-agent/wisdom/learnings.md`
   - 결정 관련 → `~/.front-agent/wisdom/decisions.md`
   - 이슈 관련 → `~/.front-agent/wisdom/issues.md`
   - 컴포넌트 관련 → `knowledge/components.md`
   - 패턴 관련 → `knowledge/patterns.md`
   - 디자인 관련 → `knowledge/design-system.md`

**핵심 원칙**: 필요한 파일만 로드한다. 전체 파일을 한꺼번에 로드하지 않는다.

---

## Output Format

```
## Knowledge Search: "[query]"

### Wisdom (전역)
[summary.md 관련 항목]

### 프로젝트 Knowledge
[knowledge/index.md 관련 항목]

### 상세 (온디맨드 로드)
[관련 상세 파일 발췌]
```

---

## Constraints

- haiku 모델 사용 (읽기 전용, 수정 없음)
- 관련 없는 파일은 로드하지 않는다
- 결과가 없으면 "해당 내용 없음" 명시
