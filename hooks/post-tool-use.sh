#!/bin/bash
# post-tool-use.sh
# PostToolUse 훅 — Write/Edit 후 자동 typecheck + lint
# Claude Code가 CLAUDE_TOOL_INPUT 환경변수로 tool input JSON을 전달함

# tool input에서 파일 경로 추출
# Write 툴: {"file_path": "..."}, Edit 툴: {"file_path": "..."}
FILE_PATH=$(echo "${CLAUDE_TOOL_INPUT:-{}}" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('file_path', ''))
except:
    print('')
" 2>/dev/null)

# 파일 경로가 없거나 .ts/.tsx가 아니면 스킵
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

if [[ "$FILE_PATH" != *.ts && "$FILE_PATH" != *.tsx ]]; then
  exit 0
fi

# 파일이 실제로 존재하는지 확인
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# 프로젝트 루트 찾기 (package.json이 있는 가장 가까운 부모 디렉토리)
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

ERRORS=""

# TypeScript 타입 체크 (tsconfig.json이 있을 때만)
if [ -f "$PROJECT_ROOT/tsconfig.json" ]; then
  TSC_OUTPUT=$(cd "$PROJECT_ROOT" && npx tsc --noEmit 2>&1)
  TSC_EXIT=$?
  if [ $TSC_EXIT -ne 0 ]; then
    # 변경된 파일 관련 에러만 필터링
    FILENAME=$(basename "$FILE_PATH")
    RELEVANT=$(echo "$TSC_OUTPUT" | grep -A 2 "$FILENAME" | head -20)
    if [ -n "$RELEVANT" ]; then
      ERRORS="${ERRORS}\n[TypeScript Error]\n${RELEVANT}"
    fi
  fi
fi

# ESLint (eslint 설정 파일이 있을 때만)
if [ -f "$PROJECT_ROOT/.eslintrc.json" ] || [ -f "$PROJECT_ROOT/.eslintrc.js" ] || [ -f "$PROJECT_ROOT/eslint.config.js" ] || [ -f "$PROJECT_ROOT/eslint.config.mjs" ]; then
  ESLINT_OUTPUT=$(cd "$PROJECT_ROOT" && npx eslint "$FILE_PATH" 2>&1)
  ESLINT_EXIT=$?
  if [ $ESLINT_EXIT -ne 0 ]; then
    ERRORS="${ERRORS}\n[ESLint Error]\n${ESLINT_OUTPUT}"
  fi
fi

# 에러가 있으면 출력 (Claude가 컨텍스트로 수신)
if [ -n "$ERRORS" ]; then
  echo "⚠️  PostToolUse 자동 검사 실패: $FILE_PATH"
  echo -e "$ERRORS"
  echo ""
  echo "위 에러를 수정해주세요."
  exit 2
fi

exit 0
