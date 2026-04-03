#!/bin/bash
# post-tool-use.sh
# Run compact validation after Write/Edit on TypeScript files.

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

if [[ "$FILE_PATH" != *.ts && "$FILE_PATH" != *.tsx ]]; then
  exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

PROJECT_ROOT=$(dirname "$FILE_PATH")
while [ "$PROJECT_ROOT" != "/" ]; do
  if [ -f "$PROJECT_ROOT/package.json" ]; then
    break
  fi
  PROJECT_ROOT=$(dirname "$PROJECT_ROOT")
done

if [ ! -f "$PROJECT_ROOT/package.json" ]; then
  exit 0
fi

MAX_TSC_LINES=8
MAX_ESLINT_LINES=12
ERRORS=""
FILENAME=$(basename "$FILE_PATH")

compact_block() {
  printf '%s\n' "$1" | sed '/^$/d' | sed '/^--$/d' | head -n "$2"
}

if [ -f "$PROJECT_ROOT/tsconfig.json" ]; then
  TSC_OUTPUT=$(cd "$PROJECT_ROOT" && npx tsc --noEmit --pretty false 2>&1)
  TSC_EXIT=$?
  if [ $TSC_EXIT -ne 0 ]; then
    RELEVANT=$(printf '%s\n' "$TSC_OUTPUT" | grep -F "$FILENAME" -A 1 | head -n $((MAX_TSC_LINES * 2)))
    if [ -z "$RELEVANT" ]; then
      RELEVANT=$(printf '%s\n' "$TSC_OUTPUT" | head -n "$MAX_TSC_LINES")
    fi
    RELEVANT=$(compact_block "$RELEVANT" "$MAX_TSC_LINES")
    if [ -n "$RELEVANT" ]; then
      ERRORS="${ERRORS}\n[TypeScript Error]\n${RELEVANT}"
    fi
  fi
fi

if [ -f "$PROJECT_ROOT/.eslintrc.json" ] || [ -f "$PROJECT_ROOT/.eslintrc.js" ] || [ -f "$PROJECT_ROOT/eslint.config.js" ] || [ -f "$PROJECT_ROOT/eslint.config.mjs" ]; then
  ESLINT_OUTPUT=$(cd "$PROJECT_ROOT" && npx eslint --format unix "$FILE_PATH" 2>&1)
  ESLINT_EXIT=$?
  if [ $ESLINT_EXIT -ne 0 ]; then
    RELEVANT=$(compact_block "$ESLINT_OUTPUT" "$MAX_ESLINT_LINES")
    if [ -n "$RELEVANT" ]; then
      ERRORS="${ERRORS}\n[ESLint Error]\n${RELEVANT}"
    fi
  fi
fi

if [ -n "$ERRORS" ]; then
  echo "PostToolUse validation failed: $FILE_PATH"
  echo -e "$ERRORS"
  echo ""
  echo "Fix the errors above, then continue."
  exit 2
fi

exit 0
