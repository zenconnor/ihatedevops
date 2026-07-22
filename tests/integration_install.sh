#!/bin/sh
# Integration test: install.sh puts the skill into $HOME/.claude/skills/.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
fails=0

check() {
  desc=$1; shift
  if "$@" >/dev/null 2>&1; then
    echo "  ok: $desc"
  else
    echo "  FAIL: $desc"
    fails=$((fails + 1))
  fi
}

echo "integration_install:"
TMP_HOME=$(mktemp -d)
trap 'rm -rf "$TMP_HOME"' EXIT

check "install.sh exists and is executable" test -x "$ROOT/install.sh"
if [ -x "$ROOT/install.sh" ]; then
  HOME="$TMP_HOME" sh "$ROOT/install.sh" >/dev/null 2>&1
  check "install exits 0" test $? -eq 0
  DEST="$TMP_HOME/.claude/skills/ihatedevops"
  check "SKILL.md installed" test -f "$DEST/SKILL.md"
  check "references installed" test -f "$DEST/references/chainguard-images.md"
  # Idempotent re-run
  HOME="$TMP_HOME" sh "$ROOT/install.sh" >/dev/null 2>&1
  check "re-install exits 0 (idempotent)" test $? -eq 0
  check "SKILL.md still present after re-install" test -f "$DEST/SKILL.md"
fi

[ "$fails" -eq 0 ] && echo "integration_install: PASS" || echo "integration_install: FAIL ($fails)"
exit "$fails"
