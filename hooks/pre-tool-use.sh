#!/bin/bash
# pre-tool-use.sh
# PreToolUse hook — warn before modifying review-required config files
# Claude sees this warning and must ask the user for approval before proceeding.

FILE_PATH=$(echo "${CLAUDE_TOOL_INPUT:-{}}" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('file_path', ''))
except:
    print('')
" 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

FILENAME=$(basename "$FILE_PATH")

# Files that require explicit user approval before modification
case "$FILENAME" in
  package.json|next.config.js|next.config.ts|next.config.mjs|tsconfig.json|tsconfig.*.json)
    echo "⚠️  REVIEW REQUIRED: Attempting to modify '$FILENAME'"
    echo ""
    echo "This file requires explicit user approval before modification."
    echo "→ If the user has NOT approved this change: ask them first, then retry."
    echo "→ If the user HAS already approved: proceed."
    exit 0
    ;;
esac

exit 0
