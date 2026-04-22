#!/bin/bash
# post-tool-use.sh
# Run compact validation after Write/Edit on TypeScript files.
# Perf: incremental tsc + per-file debounce + tsc||eslint in parallel.

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

# Debounce: skip if same file was validated within DEBOUNCE_SECONDS.
DEBOUNCE_SECONDS=3
CACHE_DIR="$PROJECT_ROOT/.fe-copilot-cache"
mkdir -p "$CACHE_DIR" 2>/dev/null
DEBOUNCE_KEY=$(printf '%s' "$FILE_PATH" | shasum | awk '{print $1}')
DEBOUNCE_FILE="$CACHE_DIR/$DEBOUNCE_KEY.ts"
NOW=$(date +%s)
if [ -f "$DEBOUNCE_FILE" ]; then
  LAST=$(cat "$DEBOUNCE_FILE" 2>/dev/null)
  if [ -n "$LAST" ] && [ "$((NOW - LAST))" -lt "$DEBOUNCE_SECONDS" ]; then
    exit 0
  fi
fi
printf '%s' "$NOW" > "$DEBOUNCE_FILE"

MAX_TSC_LINES=8
MAX_ESLINT_LINES=12
FILENAME=$(basename "$FILE_PATH")
TSC_OUT_FILE="$CACHE_DIR/$DEBOUNCE_KEY.tsc.out"
ESLINT_OUT_FILE="$CACHE_DIR/$DEBOUNCE_KEY.eslint.out"
TSC_RC_FILE="$CACHE_DIR/$DEBOUNCE_KEY.tsc.rc"
ESLINT_RC_FILE="$CACHE_DIR/$DEBOUNCE_KEY.eslint.rc"
: > "$TSC_OUT_FILE" "$ESLINT_OUT_FILE"
echo 0 > "$TSC_RC_FILE"
echo 0 > "$ESLINT_RC_FILE"

compact_block() {
  printf '%s\n' "$1" | sed '/^$/d' | sed '/^--$/d' | head -n "$2"
}

TSC_PID=""
ESLINT_PID=""

if [ -f "$PROJECT_ROOT/tsconfig.json" ]; then
  (
    cd "$PROJECT_ROOT" && \
    npx tsc --noEmit --incremental --pretty false > "$TSC_OUT_FILE" 2>&1
    echo $? > "$TSC_RC_FILE"
  ) &
  TSC_PID=$!
fi

if [ -f "$PROJECT_ROOT/.eslintrc.json" ] || [ -f "$PROJECT_ROOT/.eslintrc.js" ] || [ -f "$PROJECT_ROOT/eslint.config.js" ] || [ -f "$PROJECT_ROOT/eslint.config.mjs" ]; then
  (
    cd "$PROJECT_ROOT" && \
    npx eslint --format unix "$FILE_PATH" > "$ESLINT_OUT_FILE" 2>&1
    echo $? > "$ESLINT_RC_FILE"
  ) &
  ESLINT_PID=$!
fi

[ -n "$TSC_PID" ] && wait "$TSC_PID" 2>/dev/null
[ -n "$ESLINT_PID" ] && wait "$ESLINT_PID" 2>/dev/null

ERRORS=""

if [ -f "$PROJECT_ROOT/tsconfig.json" ]; then
  TSC_EXIT=$(cat "$TSC_RC_FILE" 2>/dev/null || echo 0)
  if [ "$TSC_EXIT" != "0" ]; then
    TSC_OUTPUT=$(cat "$TSC_OUT_FILE")
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
  ESLINT_EXIT=$(cat "$ESLINT_RC_FILE" 2>/dev/null || echo 0)
  if [ "$ESLINT_EXIT" != "0" ]; then
    ESLINT_OUTPUT=$(cat "$ESLINT_OUT_FILE")
    RELEVANT=$(compact_block "$ESLINT_OUTPUT" "$MAX_ESLINT_LINES")
    if [ -n "$RELEVANT" ]; then
      ERRORS="${ERRORS}\n[ESLint Error]\n${RELEVANT}"
    fi
  fi
fi

rm -f "$TSC_OUT_FILE" "$ESLINT_OUT_FILE" "$TSC_RC_FILE" "$ESLINT_RC_FILE" 2>/dev/null

if [ -n "$ERRORS" ]; then
  echo "PostToolUse validation failed: $FILE_PATH"
  echo -e "$ERRORS"
  echo ""
  echo "Fix the errors above, then continue."
  exit 2
fi

exit 0
