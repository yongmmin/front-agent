#!/bin/bash
# session-start.sh
# 세션 시작 시 knowledge/index.md를 로드하고 컨텍스트를 출력한다.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KNOWLEDGE_INDEX="$PLUGIN_DIR/knowledge/index.md"

# knowledge/index.md 존재 확인
if [ ! -f "$KNOWLEDGE_INDEX" ]; then
  echo "⚠️  knowledge/index.md not found. Run /setup to initialize."
  exit 0
fi

# 줄 수 체크 (300줄 초과 경고)
LINE_COUNT=$(wc -l < "$KNOWLEDGE_INDEX")
if [ "$LINE_COUNT" -gt 300 ]; then
  echo "⚠️  knowledge/index.md exceeds 300 lines ($LINE_COUNT lines). Split into domain files."
fi

# 지식 베이스 로드
echo "=== Frontend Co-Pilot: Knowledge Loaded ==="
echo "📚 knowledge/index.md ($LINE_COUNT lines)"
echo ""
cat "$KNOWLEDGE_INDEX"
echo ""
echo "=== End Knowledge ==="
