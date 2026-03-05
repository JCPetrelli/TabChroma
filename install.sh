#!/bin/bash
# tab-chroma installer
# Works both as a local install (from cloned repo) and via: curl -fsSL <url> | bash

set -e

REPO="JCPetrelli/TabChroma"
INSTALL_DIR="$HOME/.claude/hooks/tab-chroma"

# ─── Detect local vs remote install ───────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-/dev/stdin}")" 2>/dev/null && pwd || echo "")"

if [ -f "$SCRIPT_DIR/tab-chroma.sh" ] && [ -d "$SCRIPT_DIR/themes" ]; then
  # Running from a local clone
  SOURCE_DIR="$SCRIPT_DIR"
  echo "tab-chroma installer (local)"
else
  # Running via curl pipe — download from GitHub
  echo "tab-chroma installer (remote)"
  echo ""

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT

  # Try latest release first, fall back to main branch
  LATEST_URL="https://api.github.com/repos/$REPO/releases/latest"
  TAG=$(curl -fsSL "$LATEST_URL" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['tag_name'])" 2>/dev/null || echo "")

  if [ -n "$TAG" ]; then
    TARBALL="https://github.com/$REPO/archive/refs/tags/$TAG.tar.gz"
    echo "Downloading $TAG..."
  else
    TARBALL="https://github.com/$REPO/archive/refs/heads/main.tar.gz"
    echo "Downloading latest (main branch)..."
  fi

  curl -fsSL "$TARBALL" | tar xz -C "$TMP_DIR" --strip-components=1
  SOURCE_DIR="$TMP_DIR"
fi

VERSION="$(cat "$SOURCE_DIR/VERSION" 2>/dev/null || echo "unknown")"
echo ""
echo "Installing tab-chroma v$VERSION to $INSTALL_DIR..."
echo ""

# ─── Copy files to install dir ────────────────────────────────────────────────

mkdir -p "$INSTALL_DIR"

# Always copy core files; preserve existing config/state
for item in tab-chroma.sh themes completions VERSION; do
  if [ -e "$SOURCE_DIR/$item" ]; then
    cp -r "$SOURCE_DIR/$item" "$INSTALL_DIR/"
  fi
done

# ─── Install Claude slash commands ────────────────────────────────────────────

CLAUDE_COMMANDS_DIR="$HOME/.claude/commands"
if [ -d "$SOURCE_DIR/commands" ]; then
  mkdir -p "$CLAUDE_COMMANDS_DIR"
  cp "$SOURCE_DIR/commands/"*.md "$CLAUDE_COMMANDS_DIR/"
  echo "Installed Claude slash commands to $CLAUDE_COMMANDS_DIR"
fi

chmod +x "$INSTALL_DIR/tab-chroma.sh"

# ─── Delegate to tab-chroma install command ───────────────────────────────────
# Pass SOURCE_DIR as SHARE_DIR so cmd_install finds completions correctly

TAB_CHROMA_SHARE="$INSTALL_DIR" TAB_CHROMA_DATA="$INSTALL_DIR" \
  bash "$INSTALL_DIR/tab-chroma.sh" install
