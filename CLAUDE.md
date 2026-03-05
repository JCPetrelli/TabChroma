# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**tab-chroma** is a Claude Code hook plugin that changes iTerm2 tab colors, badges, and tab titles based on Claude Code hook events (working, done, attention, permission). It is a pure bash + Python 3 plugin with no build step or dependencies beyond the standard library.

## Locations

- **Source repo:** `~/Documents/Scripts/tab_chroma/` — contains `tab-chroma.sh`, themes, commands, completions, Formula, install/uninstall scripts, and documentation.
- **Installed plugin:** `~/.claude/hooks/tab-chroma/` — the running copy, installed by `install.sh` (copies `tab-chroma.sh`, `themes/`, `completions/`, `VERSION`)
- **Design plan:** `docs/plans/2026-03-04-tab-chroma-plugin-plan.md`

Edit `tab-chroma.sh` in the source repo, then run `bash install.sh` to sync to the installed location. The two copies should stay identical.

## Installation

```bash
# From this repo
bash install.sh

# Or via curl
curl -fsSL https://raw.githubusercontent.com/JCPetrelli/tab_chroma/main/install.sh | bash

# Or via Homebrew
brew tap JCPetrelli/tab-chroma https://github.com/JCPetrelli/tab_chroma
brew install tab-chroma
tab-chroma install
```

## Testing

```bash
# Validate bash syntax
bash -n tab-chroma.sh

# Test a visual state manually (must be run from an actual iTerm2 terminal)
tab-chroma test working
tab-chroma test done
tab-chroma test attention
tab-chroma test permission
tab-chroma reset

# Simulate a hook event (no terminal required — verifies Python logic and state file)
printf '{"hook_event_name":"UserPromptSubmit","cwd":"/tmp/myproject","session_id":"abc123"}' \
  > /tmp/tc_input.json
TERM_PROGRAM=iTerm.app ~/.claude/hooks/tab-chroma/tab-chroma.sh < /tmp/tc_input.json
cat ~/.claude/hooks/tab-chroma/.state.json   # should show last_state: "working"

# Check status
tab-chroma status
```

## Architecture

The plugin is a single bash script (`tab-chroma.sh`) with two entry modes:

**CLI mode** (`tab-chroma <command>`) — argument routing via `route_cli()` → individual `cmd_*` functions.

**Hook mode** (no args, stdin is not a TTY) — `process_hook()` receives JSON from Claude Code on stdin.

### Hook Flow

```
stdin JSON → process_hook()
  1. Terminal check ($TERM_PROGRAM) — exit silently if not iTerm2/apple-terminal
  2. Pause check (.paused file) — drain stdin and exit if paused
  3. ensure_config() — create config.json if missing
  4. Read stdin into $INPUT
  5. Consolidated Python block (single python3 invocation via env vars):
     - Parse event JSON → map to internal state name
     - Load config + .state.json
     - Debounce check (skip if same state within N seconds, except urgent states)
     - Resolve theme (static / random / round-robin rotation, per-session pinning)
     - Output bash variable assignments (ACTION, COLOR_R/G/B, TITLE_TEXT, BADGE_TEXT)
     - Atomically save .state.json
  6. eval the Python output → apply escape sequences to /dev/tty
```

### Key Patterns

**Python-in-bash**: All JSON parsing, config loading, and debouncing logic runs in a **single `python3` invocation** to minimise subprocess overhead. Data is passed in via environment variables (`TAB_CHROMA_INPUT`, `TAB_CHROMA_CONFIG`, `TAB_CHROMA_STATE`, `TAB_CHROMA_THEMES`); outputs are bash variable assignments captured with `eval "$(...)"`.

**`_apply_theme_state`**: Used by CLI commands (`test`, `preview`) only — NOT by `process_hook`. Accepts `theme_file` and `state_name` as positional args via `python3 - "$theme_file" "$state_name" << 'PYEOF'`. Args must be on the **same line** as `python3 -`, before `<< 'PYEOF'`.

**`/dev/tty` writes**: All iTerm2 escape sequences write to `/dev/tty` (not stdout — Claude Code captures hook stdout). Wrapped in `{ printf ...; } 2>/dev/null` to suppress errors when `/dev/tty` is unavailable.

**Hook registration**: Hooks are registered in `~/.claude/settings.json` under the `hooks` key. The installer (`install.sh`) appends to existing catch-all matchers to coexist with other hooks (e.g. peon-ping).

### Event → State Mapping

| Claude Code Hook | Internal State |
|---|---|
| `SessionStart` | `session.start` → resets tab color |
| `UserPromptSubmit` | `working` |
| `PreToolUse` | `working` |
| `PostToolUse` | `working` — recovers from permission state |
| `Stop` | `done` |
| `Notification` | `attention` or `permission` (based on message content) |
| `PermissionRequest` | `permission` |

`permission` and `attention` bypass debouncing and always update immediately.

### Theme Format

Each theme is a directory under `themes/<name>/theme.json`. States with `"action": "reset"` reset the tab to default. Missing states are no-ops.

## Themes (6 bundled)

default, ocean, neon, pastel, solarized, dracula

## Config Files (installed location)

| File | Purpose |
|---|---|
| `config.json` | User config — active theme, feature toggles, debounce, rotation |
| `.state.json` | Runtime state — last state, timestamp, per-session theme pins |
| `.paused` | Presence = paused (touch to pause, rm to resume) |
| `VERSION` | Version string, read with `read -r VERSION < VERSION` |
