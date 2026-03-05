# TabChroma

iTerm2 visual feedback plugin for [Claude Code](https://claude.ai/code). Changes your tab color, badge, and title based on what Claude is doing - so you can glance at any tab and know its state at a moment's notice.

| State | Default Color | Meaning |
|-------|--------------|---------|
| working | Blue | Claude is processing |
| done | Green | Ready for your input |
| attention | Orange | Needs your attention |
| permission | Red | Awaiting approval |
| session.start | Reset | New session began |

## Requirements

- macOS with [iTerm2](https://iterm2.com)
- [Claude Code](https://claude.ai/code) CLI
- Python 3 (standard library only)
- **zsh** - the installer writes the shell alias and `claude()` wrapper to `~/.zshrc`. bash and fish are not supported by the installer; add the following manually to your shell rc file:

```bash
# Makes `tab-chroma` available as a command
alias tab-chroma='~/.claude/hooks/tab-chroma/tab-chroma.sh'

# Wraps the `claude` command so the tab color resets when you exit Claude Code.
# Claude Code has no SessionEnd hook, so without this the tab stays colored
# after you close the session.
claude() {
  command claude "$@"
  tab-chroma reset > /dev/null 2>&1
}
```

## Installation

### Option 1 - curl (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/JCPetrelli/TabChroma/main/install.sh | bash
```

Reload your shell, then test it:

```bash
tab-chroma test working
```

### Option 2 - Homebrew

```bash
brew tap JCPetrelli/tab-chroma https://github.com/JCPetrelli/TabChroma
brew install tab-chroma
tab-chroma install   # registers Claude Code hooks
```

### Option 3 - Manual

```bash
git clone https://github.com/JCPetrelli/TabChroma.git
cd TabChroma
bash install.sh
```

## Usage

```
tab-chroma <command> [args]

CONTROLS:
  pause                 Disable color changes
  resume                Re-enable color changes
  toggle                Toggle pause state
  status                Show current config and state

THEMES:
  theme list            List installed themes
  theme use <name>      Switch active theme
  theme next            Cycle to next theme
  theme preview [name]  Preview all states (2s each)

FEATURES:
  badge on|off          Toggle iTerm2 badge
  title on|off          Toggle tab title updates
  color on|off          Toggle tab color changes

TESTING:
  test <state>          Manually trigger a state
  reset                 Reset tab to default color

SETUP:
  install               Register Claude Code hooks
  uninstall             Remove hooks and data files
```

## Features

### Badge

The badge is a large watermark text displayed in the background of the iTerm2 terminal window. When enabled, it shows the current project name and state label (e.g. `my-project` / `Working`) - visible at a glance even when the tab is active and you're looking directly at the terminal.

The badge is **off by default**. Enable it with:

```bash
tab-chroma badge on
tab-chroma badge off   # to disable again
```

The badge color tracks the tab color (e.g. blue while working, green when done).

### Title

When enabled, the tab title is updated to show the project name and current state (e.g. `◉ my-project: working`). On by default.

```bash
tab-chroma title on|off
```

### Color

Controls whether the tab background color changes at all. Disabling this leaves all other features (badge, title) unaffected. On by default.

```bash
tab-chroma color on|off
```

## Themes

6 themes are bundled:

| Theme | Working | Done | Attention | Permission | Description |
|-------|:-------:|:----:|:---------:|:----------:|-------------|
| **default** | ![](https://img.shields.io/badge/-%20-0064C8?style=flat-square) | ![](https://img.shields.io/badge/-%20-22B450?style=flat-square) | ![](https://img.shields.io/badge/-%20-FFA028?style=flat-square) | ![](https://img.shields.io/badge/-%20-DC3C28?style=flat-square) | Clean blue/green/orange |
| **ocean** | ![](https://img.shields.io/badge/-%20-0050A0?style=flat-square) | ![](https://img.shields.io/badge/-%20-00B4AA?style=flat-square) | ![](https://img.shields.io/badge/-%20-F0B428?style=flat-square) | ![](https://img.shields.io/badge/-%20-F0503C?style=flat-square) | Calm oceanic palette |
| **neon** | ![](https://img.shields.io/badge/-%20-0096FF?style=flat-square) | ![](https://img.shields.io/badge/-%20-00FF64?style=flat-square) | ![](https://img.shields.io/badge/-%20-FF3296?style=flat-square) | ![](https://img.shields.io/badge/-%20-FF1E1E?style=flat-square) | Vibrant cyberpunk |
| **pastel** | ![](https://img.shields.io/badge/-%20-82AADC?style=flat-square) | ![](https://img.shields.io/badge/-%20-82C896?style=flat-square) | ![](https://img.shields.io/badge/-%20-F0B48C?style=flat-square) | ![](https://img.shields.io/badge/-%20-DC8C8C?style=flat-square) | Gentle, easy on the eyes |
| **solarized** | ![](https://img.shields.io/badge/-%20-268BD2?style=flat-square) | ![](https://img.shields.io/badge/-%20-859900?style=flat-square) | ![](https://img.shields.io/badge/-%20-B58900?style=flat-square) | ![](https://img.shields.io/badge/-%20-DC322F?style=flat-square) | Classic Solarized |
| **dracula** | ![](https://img.shields.io/badge/-%20-BD93F9?style=flat-square) | ![](https://img.shields.io/badge/-%20-50FA7B?style=flat-square) | ![](https://img.shields.io/badge/-%20-FFB86C?style=flat-square) | ![](https://img.shields.io/badge/-%20-FF5555?style=flat-square) | Dracula editor colors |

```bash
tab-chroma theme list
tab-chroma theme use dracula
tab-chroma theme preview ocean
```

### Theme Rotation

Automatically cycle themes across sessions:

```bash
# Edit ~/.claude/hooks/tab-chroma/config.json
{
  "theme_rotation": ["default", "ocean", "dracula"],
  "theme_rotation_mode": "round-robin"   // or "random"
}
```

## Custom Themes

Create a directory under `~/.claude/hooks/tab-chroma/themes/<name>/` with a `theme.json`:

```json
{
  "schema_version": "1.0",
  "name": "mytheme",
  "display_name": "My Theme",
  "description": "Custom color scheme",
  "states": {
    "session.start": { "action": "reset", "label": "Session started" },
    "working":    { "r": 0,   "g": 100, "b": 200, "label": "Working" },
    "done":       { "r": 34,  "g": 180, "b": 80,  "label": "Done" },
    "attention":  { "r": 255, "g": 160, "b": 40,  "label": "Attention" },
    "permission": { "r": 220, "g": 60,  "b": 40,  "label": "Permission" }
  }
}
```

## Configuration

`~/.claude/hooks/tab-chroma/config.json`:

```json
{
  "active_theme": "default",
  "enabled": true,
  "features": {
    "tab_color": true,
    "badge": false,
    "title": true
  },
  "debounce_seconds": 2,
  "theme_rotation": [],
  "theme_rotation_mode": "off"
}
```

## How It Works

tab-chroma registers itself as a Claude Code hook for these events:

| Hook | State |
|------|-------|
| `SessionStart` | session.start - resets tab color |
| `UserPromptSubmit` | working |
| `PreToolUse` | working |
| `PostToolUse` | working - recovers from permission state |
| `Stop` | done |
| `Notification` | attention or permission (based on message) |
| `PermissionRequest` | permission |

### Debouncing

If the same state fires more than once within `debounce_seconds` (default: 2s), subsequent updates are skipped. A typical Claude turn with many tool uses would otherwise send dozens of identical escape sequences, causing unnecessary overhead and visual noise. Debouncing means only the first transition to a state triggers a visual update - subsequent identical events within the window are no-ops.

`permission` and `attention` bypass debouncing entirely and always update immediately, since you never want to miss them.

### Permission recovery

When Claude needs to use a restricted tool, `PermissionRequest` fires and the tab turns red. Once you approve and the tool runs, `PostToolUse` fires and the tab returns to working (blue) automatically - you don't need to do anything.

### Implementation notes

All escape sequences write to `/dev/tty` (not stdout) so Claude Code's hook runner isn't affected. JSON parsing, debouncing, and theme resolution all run in a single `python3` invocation per hook event to minimize subprocess overhead.

## Uninstalling

**curl / manual install:**
```bash
tab-chroma uninstall
```

**Homebrew install:**
```bash
tab-chroma uninstall
brew uninstall tab-chroma
brew untap JCPetrelli/tab-chroma
```

## License

MIT - see [LICENSE](LICENSE)
