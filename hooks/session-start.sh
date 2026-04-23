#!/bin/bash
# session-start.sh
# Load only compact summary data at session start. Full project knowledge is on-demand.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KNOWLEDGE_INDEX="$PLUGIN_DIR/knowledge/index.md"
WISDOM_DIR="$HOME/.front-agent/wisdom"
WISDOM_SUMMARY="$WISDOM_DIR/summary.md"
MAX_WISDOM_LINES=10

# Cache TTL cleanup: remove PostToolUse debounce/output files older than 1 hour.
# Silent & best-effort — never block session start.
CACHE_DIR="$PLUGIN_DIR/.fe-copilot-cache"
if [ -d "$CACHE_DIR" ]; then
  find "$CACHE_DIR" -type f -mmin +60 -delete 2>/dev/null || true
fi

if [ -f "$WISDOM_SUMMARY" ]; then
  LINE_COUNT=$(wc -l < "$WISDOM_SUMMARY")
  if [ "$LINE_COUNT" -gt 20 ]; then
    echo "Warning: wisdom/summary.md exceeds 20 lines ($LINE_COUNT). Trim old entries."
  fi
  echo "=== Wisdom Summary ==="
  head -n "$MAX_WISDOM_LINES" "$WISDOM_SUMMARY"
  echo "=== End Wisdom Summary ==="
  echo ""
fi

if [ ! -f "$KNOWLEDGE_INDEX" ]; then
  echo "Project knowledge is not initialized yet. It will be created on first use."
  exit 0
fi

LINE_COUNT=$(wc -l < "$KNOWLEDGE_INDEX")
if [ "$LINE_COUNT" -gt 300 ]; then
  echo "Warning: knowledge/index.md exceeds 300 lines ($LINE_COUNT). Split it into domain files."
fi

echo "=== Project Knowledge Summary ==="
echo "- Source: knowledge/index.md ($LINE_COUNT lines)"
grep -E '^- \*\*(Stack|Git|Design)\*\*:' "$KNOWLEDGE_INDEX" | head -n 3
echo "- Details: load on demand through search-knowledge"
echo "=== End Project Knowledge Summary ==="
