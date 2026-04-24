#!/bin/bash
# install.sh — Frontend Co-Pilot Plugin Installer
# Sets up skill symlinks and applies tool boundary rules to ~/.claude/settings.json

set -e

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

link_skill() {
  local source="$1"
  local target="$2"

  if [ -L "$target" ] || [ -f "$target" ]; then
    rm -f "$target"
  elif [ -d "$target" ]; then
    echo "  ✗ Refusing to replace directory: $target"
    echo "    Remove it manually if you want this installer to manage this skill path."
    return 1
  fi

  ln -s "$source" "$target"
}

echo "=== Frontend Co-Pilot — Installation ==="
echo ""

# 1. Create skill symlinks
echo "Setting up skill symlinks..."
mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/commands"
for skill in front-agent implement-figma match-style tdd code-review a11y-check \
  pixel-check refactor-scan component-audit save-knowledge search-knowledge \
  git-branch git-commit git-pr git-issue codex-review rtk-toggle; do
  link_skill "$PLUGIN_DIR/skills/$skill" "$CLAUDE_DIR/skills/$skill"
  echo "Use the $skill skill. Arguments: \$ARGUMENTS" > "$CLAUDE_DIR/commands/$skill.md"
  echo "  ✓ $skill"
done

echo ""

# 2. Apply .env* deny rules to ~/.claude/settings.json
echo "Applying tool boundary rules..."

python3 - <<'PYEOF'
import json, os

settings_file = os.path.expanduser("~/.claude/settings.json")
deny_rules = [
    "Write(.env*)",
    "Edit(.env*)"
]

if os.path.exists(settings_file):
    with open(settings_file, "r") as f:
        try:
            settings = json.load(f)
        except json.JSONDecodeError:
            settings = {}
else:
    settings = {}

if "permissions" not in settings:
    settings["permissions"] = {}
if "deny" not in settings["permissions"]:
    settings["permissions"]["deny"] = []

added = []
for rule in deny_rules:
    if rule not in settings["permissions"]["deny"]:
        settings["permissions"]["deny"].append(rule)
        added.append(rule)

with open(settings_file, "w") as f:
    json.dump(settings, f, indent=2)

if added:
    for rule in added:
        print(f"  ✓ Added deny rule: {rule}")
else:
    print("  ✓ Deny rules already present, no changes needed")
PYEOF

echo ""

# 3. Detect rtk binary (optional — plugin-scoped opt-in)
echo "Checking rtk (optional token filter)..."
if command -v rtk >/dev/null 2>&1; then
  RTK_VER=$(rtk --version 2>/dev/null | head -n 1)
  echo "  ✓ rtk detected: $RTK_VER"
  echo "    → /front-agent will ask per-session whether to use rtk."
  echo "    → No global hook is installed; other projects are unaffected."
else
  echo "  • rtk not installed (optional)."
  echo "    Install with: brew install rtk"
  echo "    Or:          curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh"
  echo "    → The plugin works fine without rtk (raw commands are used)."
fi
echo ""
echo "=== Installation Complete ==="
echo ""
echo "Tool boundaries applied:"
echo "  • .env* — BLOCKED (hard deny via settings.json)"
echo "  • package.json, next.config.js, tsconfig.json — WARNING before modification (PreToolUse hook)"
echo ""
echo "rtk integration (opt-in, plugin-scoped only):"
echo "  • /front-agent shows a picker on first use per session."
echo "  • /rtk toggles the mode anytime (off / standard / aggressive / git-only)."
echo "  • FE_COPILOT_RTK env var overrides the session flag."
echo "  • Other Claude Code projects are never affected."
echo ""
echo "To remove these rules, see README.md → '⚠️ 필독: 도구 경계 제거 방법'"
