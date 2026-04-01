---
name: save-knowledge
description: Save learnings, decisions, and component info to the knowledge base and global wisdom hub
---

# Skill: save-knowledge

**Trigger**: `/save-knowledge [topic]` or auto-called after task completion
**Purpose**: 학습 내용을 프로젝트 knowledge/와 전역 wisdom hub(`~/.front-agent/wisdom/`)에 저장한다.

---

## 저장 위치 결정

| 내용 유형 | 저장 위치 |
|----------|----------|
| 컴포넌트, 패턴, 디자인 규칙 | `knowledge/` (프로젝트 한정) |
| 교훈 (learnings) | `~/.front-agent/wisdom/learnings.md` + summary 갱신 |
| 설계 결정 (decisions) | `~/.front-agent/wisdom/decisions.md` + summary 갱신 |
| 알려진 이슈 (issues) | `~/.front-agent/wisdom/issues.md` + summary 갱신 |

---

## Workflow

1. 저장할 내용의 유형 판단
2. 해당 파일에 항목 추가
3. `~/.front-agent/wisdom/summary.md` 갱신 (20줄 이하 유지)
   - 초과 시 가장 오래된 항목 1개 삭제 후 추가

---

## Entry Format

### Learnings
```
- [날짜] [프로젝트명] 내용
```

### Decisions
```
- [날짜] [프로젝트명] 결정 — 이유
```

### Issues
```
- [날짜] [프로젝트명] 문제 — 해결책 또는 주의사항
```

### summary.md 갱신 포맷
```markdown
# Wisdom Summary
> 20줄 제한.

## Learnings
- [최근 3개만 유지]

## Decisions
- [최근 3개만 유지]

## Issues
- [최근 3개만 유지]
```

---

## 프로젝트 knowledge/ 저장 (컴포넌트/패턴/디자인)

| Type | File |
|------|------|
| 컴포넌트 | `knowledge/components.md` |
| 코드 패턴 | `knowledge/patterns.md` |
| 디자인 규칙 | `knowledge/design-system.md` |

300줄 초과 시 도메인 서브파일로 분리 후 index.md에서 링크.

---

## Constraints

- summary.md는 절대 20줄을 초과하지 않는다
- learnings/decisions/issues.md는 300줄 제한
- 프로젝트명을 항상 항목에 포함해 어느 프로젝트 맥락인지 추적 가능하게 한다
