#!/bin/sh
# ihatedevops installer — puts the ihatedevops skill into
# ~/.claude/skills/ so Claude Code picks it up in every session.
# Usage: curl -fsSL https://raw.githubusercontent.com/zenconnor/ihatedevops/main/install.sh | sh
set -eu

REPO_TARBALL="https://github.com/zenconnor/ihatedevops/archive/refs/heads/main.tar.gz"
SKILL_NAME="ihatedevops"
DEST="$HOME/.claude/skills/$SKILL_NAME"

# When run from a checkout, the skill dir sits next to this script.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd) || SCRIPT_DIR=""
LOCAL_SRC="$SCRIPT_DIR/skills/$SKILL_NAME"

mkdir -p "$HOME/.claude/skills"
rm -rf "$DEST"

if [ -n "$SCRIPT_DIR" ] && [ -f "$LOCAL_SRC/SKILL.md" ]; then
  cp -R "$LOCAL_SRC" "$DEST"
else
  # Piped from curl: fetch the repo tarball and extract just the skill.
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  curl -fsSL "$REPO_TARBALL" | tar -xz -C "$TMP"
  cp -R "$TMP"/ihatedevops-main/skills/"$SKILL_NAME" "$DEST"
fi

printf '\n  ihatedevops: skill installed to %s\n' "$DEST"
printf '  Next Claude Code session will pick it up automatically.\n'
printf '  Try: "write me a Dockerfile" and enjoy fewer CVEs.\n\n'
