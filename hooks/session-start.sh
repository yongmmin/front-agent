#!/bin/bash
# session-start.sh
# 세션 시작 시 wisdom summary(최대 20줄)만 로드. 상세 파일은 온디맨드.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KNOWLEDGE_INDEX="$PLUGIN_DIR/knowledge/index.md"
WISDOM_DIR="$HOME/.front-agent/wisdom"
WISDOM_SUMMARY="$WISDOM_DIR/summary.md"

# 1. 전역 wisdom summary 로드 (토큰 최소화 — 20줄 제한)
if [ -f "$WISDOM_SUMMARY" ]; then
  LINE_COUNT=$(wc -l < "$WISDOM_SUMMARY")
  if [ "$LINE_COUNT" -gt 20 ]; then
    echo "⚠️  wisdom/summary.md가 20줄을 초과합니다 ($LINE_COUNT줄). 오래된 항목을 정리하세요."
  fi
  echo "=== Wisdom (요약) ==="
  head -20 "$WISDOM_SUMMARY"
  echo "=== End Wisdom ==="
  echo ""
fi

# 2. 프로젝트 knowledge/index.md 로드
if [ ! -f "$KNOWLEDGE_INDEX" ]; then
  echo "⚠️  knowledge/index.md 없음. 첫 요청 시 자동 초기화됩니다."
  exit 0
fi

LINE_COUNT=$(wc -l < "$KNOWLEDGE_INDEX")
if [ "$LINE_COUNT" -gt 300 ]; then
  echo "⚠️  knowledge/index.md가 300줄을 초과합니다 ($LINE_COUNT줄). 도메인 파일로 분리하세요."
fi

echo "=== 프로젝트 Knowledge ==="
echo "📚 knowledge/index.md ($LINE_COUNT줄)"
echo ""
cat "$KNOWLEDGE_INDEX"
echo ""
echo "=== End Knowledge ==="
echo ""
echo "💡 상세 wisdom: ~/.front-agent/wisdom/learnings.md | decisions.md | issues.md"
