#!/bin/bash
# extract-constraints.sh
# Usage: extract-constraints.sh <agent-name>
# Prints only the constraints.md sections relevant to the given agent.
# front-agent MUST call this before spawning an agent instead of passing the whole file.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONSTRAINTS="$PLUGIN_DIR/constraints.md"
AGENT="${1:-}"

if [ -z "$AGENT" ]; then
  echo "usage: extract-constraints.sh <agent-name>" >&2
  exit 2
fi

if [ ! -f "$CONSTRAINTS" ]; then
  exit 0
fi

# Section tag → target agents mapping (mirrors the table in constraints.md)
case "$AGENT" in
  developer|ui-builder|api-integrator)
    SECTIONS="code-rules filesystem completion"
    ;;
  test-runner)
    SECTIONS="completion failure-patterns"
    ;;
  reviewer)
    SECTIONS="review failure-patterns"
    ;;
  refactor-architect|component-auditor)
    SECTIONS="code-rules"
    ;;
  *)
    # Unknown agent → emit nothing; caller falls back to general guidance
    exit 0
    ;;
esac

# Extract each section from the first `## #tag` heading to the next `## ` or `---`
extract_section() {
  local tag="$1"
  awk -v tag="## #$tag" '
    BEGIN { printing = 0 }
    $0 == tag { printing = 1; print; next }
    printing && /^## #/ { exit }
    printing { print }
  ' "$CONSTRAINTS"
}

for tag in $SECTIONS; do
  extract_section "$tag"
  echo ""
done
