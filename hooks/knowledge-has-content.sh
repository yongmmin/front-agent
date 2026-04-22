#!/bin/bash
# knowledge-has-content.sh
# Exit 0 if knowledge/* contains any real content beyond placeholders.
# Exit 1 if only placeholders or empty. front-agent uses this to skip
# spawning search-knowledge agent when nothing would be found.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KNOWLEDGE_DIR="$PLUGIN_DIR/knowledge"

if [ ! -d "$KNOWLEDGE_DIR" ]; then
  exit 1
fi

# Also check global wisdom summary (search-knowledge reads this first)
WISDOM_SUMMARY="$HOME/.front-agent/wisdom/summary.md"

# Placeholder patterns that indicate "no real content yet"
PLACEHOLDER_RE='(_No .* yet\.?_|_아직 기록된 내용 없음\.?_|_none_|_none —_)'

has_real_content() {
  local file="$1"
  [ ! -f "$file" ] && return 1
  # Strip frontmatter-ish headers, blockquotes, empty lines, placeholders, tables-with-dashes
  # If anything substantive remains, it's real content.
  local remaining
  remaining=$(grep -vE '^\s*(#|>|\||---|$)' "$file" \
    | grep -vE "$PLACEHOLDER_RE" \
    | grep -vE '^\s*-\s*(_none_|—)' \
    | sed '/^[[:space:]]*$/d')
  [ -n "$remaining" ]
}

# Check each candidate file; first hit wins
for f in \
  "$WISDOM_SUMMARY" \
  "$KNOWLEDGE_DIR/index.md" \
  "$KNOWLEDGE_DIR/components.md" \
  "$KNOWLEDGE_DIR/patterns.md" \
  "$KNOWLEDGE_DIR/design-system.md" \
  "$HOME/.front-agent/wisdom/learnings.md" \
  "$HOME/.front-agent/wisdom/decisions.md" \
  "$HOME/.front-agent/wisdom/issues.md"
do
  if has_real_content "$f"; then
    exit 0
  fi
done

exit 1
