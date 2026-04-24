#!/bin/bash
# rtk-wrap.sh — Plugin-scoped rtk command wrapper.
#
# Goal: let /front-agent opt into rtk per session without affecting any
# other Claude Code project on the machine (no global hook installed).
#
# Resolution order for the mode:
#   1. FE_COPILOT_RTK env var — hard override
#        off | standard | aggressive | git-only
#   2. .fe-copilot-cache/rtk-session.flag — set by /front-agent UI or /rtk
#   3. default: off
#
# Usage:
#   bash hooks/rtk-wrap.sh <command> [args...]
#     - Decides whether to prefix with `rtk` based on mode + command kind.
#     - Always execs the command; falls back to raw if rtk missing or off.
#
#   bash hooks/rtk-wrap.sh --mode
#     - Prints the resolved mode string (off/standard/aggressive/git-only).
#
#   bash hooks/rtk-wrap.sh --set <mode>
#     - Writes the mode to the session flag file.
#
#   bash hooks/rtk-wrap.sh --clear
#     - Removes the session flag file.

set -e

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="$PLUGIN_DIR/.fe-copilot-cache"
FLAG_FILE="$CACHE_DIR/rtk-session.flag"

resolve_mode() {
  if [ -n "${FE_COPILOT_RTK:-}" ]; then
    printf '%s\n' "$FE_COPILOT_RTK"
    return
  fi
  if [ -f "$FLAG_FILE" ]; then
    local val
    val=$(head -n 1 "$FLAG_FILE" 2>/dev/null | tr -d '[:space:]')
    if [ -n "$val" ]; then
      printf '%s\n' "$val"
      return
    fi
  fi
  printf 'off\n'
}

# Category lookup for the first arg of the underlying command.
# Maps a command binary to an rtk subcommand category, or empty if rtk has no
# handler (in which case we still run raw).
rtk_handles() {
  local cmd="$1"
  case "$cmd" in
    git|gh)                   echo "git" ;;
    tsc|eslint|biome|prettier|ruff|rubocop|golangci-lint|next) echo "lint" ;;
    jest|vitest|playwright|pytest|rspec|rake)                  echo "test" ;;
    cargo|go)                                                  echo "build" ;;
    ls|tree|cat|read|find|grep|rg|diff|json|docker|kubectl|aws|curl|wget|log|env|deps)
                              echo "other" ;;
    *)                        echo "" ;;
  esac
}

should_prefix() {
  local mode="$1" category="$2"
  [ -z "$category" ] && return 1
  case "$mode" in
    off)         return 1 ;;
    git-only)    [ "$category" = "git" ] ;;
    standard|aggressive) return 0 ;;
    *)           return 1 ;;
  esac
}

case "${1:-}" in
  --mode)
    resolve_mode
    exit 0
    ;;
  --set)
    shift
    mkdir -p "$CACHE_DIR"
    printf '%s\n' "${1:-off}" > "$FLAG_FILE"
    exit 0
    ;;
  --clear)
    rm -f "$FLAG_FILE"
    exit 0
    ;;
  "")
    echo "usage: rtk-wrap.sh <command> [args...] | --mode | --set <mode> | --clear" >&2
    exit 2
    ;;
esac

MODE=$(resolve_mode)
CMD="$1"; shift
CATEGORY=$(rtk_handles "$CMD")

# Strip npx prefix when deciding category (npx tsc → tsc category)
if [ "$CMD" = "npx" ] && [ -n "${1:-}" ]; then
  CATEGORY=$(rtk_handles "$1")
fi

if should_prefix "$MODE" "$CATEGORY" && command -v rtk >/dev/null 2>&1; then
  EXTRA=""
  if [ "$MODE" = "aggressive" ]; then
    EXTRA="-u"
  fi
  if [ "$CMD" = "npx" ]; then
    shift_cmd="$1"; shift
    exec rtk $EXTRA "$shift_cmd" "$@"
  else
    exec rtk $EXTRA "$CMD" "$@"
  fi
fi

exec "$CMD" "$@"
