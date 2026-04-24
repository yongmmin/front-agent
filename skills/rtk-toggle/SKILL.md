---
name: rtk-toggle
description: Toggle or inspect the rtk token-filter mode used by /front-agent for the current session. Plugin-scoped; no global hook.
---

# Skill: rtk-toggle

**Trigger**: `/rtk [mode]`
**Purpose**: Let the user choose whether this plugin's internal Bash calls (tsc, eslint, git, gh, test runners, grep/find/ls) pipe through `rtk` for token compression.

---

## Modes

| Mode | Behavior |
|------|----------|
| `off` | Raw commands. Default. |
| `standard` | `rtk` applied to git/gh/tsc/eslint/test/grep/find/ls. |
| `aggressive` | Same as `standard` plus `-u` (ultra-compact) flag. |
| `git-only` | `rtk` applied only to git/gh commands; everything else raw. |

---

## Trigger Routes

1. **Explicit arg**: `/rtk standard`, `/rtk off`, etc. — write the mode and report.
2. **No arg**: launch the AskUserQuestion picker UI and let the user choose.
3. **Status query**: `/rtk status` — print the currently resolved mode without changing it.

---

## Resolution Order (read by `hooks/rtk-wrap.sh`)

1. `FE_COPILOT_RTK` env var — hard override, never touched by this skill.
2. `.fe-copilot-cache/rtk-session.flag` — written by this skill and by `/front-agent`.
3. Default: `off`.

---

## Implementation

### When user provides a mode argument

```bash
bash hooks/rtk-wrap.sh --set <mode>
```

Valid modes: `off | standard | aggressive | git-only`. Reject others with a one-line error.

### When user runs `/rtk status`

```bash
bash hooks/rtk-wrap.sh --mode
```

Report the returned value. If `FE_COPILOT_RTK` is set, mention that the env var is overriding the flag file.

### When user runs `/rtk` with no arg

Use the `AskUserQuestion` tool with one question, 4 options (off / standard / aggressive / git-only). After the user answers, persist with `bash hooks/rtk-wrap.sh --set <answer>`.

---

## Output

Single compact line:

```
rtk mode: standard (session flag written)
```

No prose, no emojis, no explanation of how rtk works internally.

---

## Guarantees

- This skill never installs or uninstalls rtk globally.
- It only writes `.fe-copilot-cache/rtk-session.flag` scoped to this plugin directory.
- If rtk is not installed, the mode still writes, but `rtk-wrap.sh` will silently fall back to raw commands at runtime.
