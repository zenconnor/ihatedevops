#!/bin/sh
# E2E: with the skill installed in a scratch project, a headless Claude Code
# run asked for a Dockerfile should follow the practices (Chainguard image,
# multi-stage/non-root). A control run without the skill is reported for
# comparison but not asserted (baseline behavior varies).
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
fails=0

echo "e2e_skill_effect:"

if ! command -v claude >/dev/null 2>&1; then
  echo "  SKIP: claude CLI not found on PATH"
  echo "e2e_skill_effect: PASS (skipped)"
  exit 0
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
PROMPT="Write a Dockerfile for a small Node.js (Express) web server. Reply with just the Dockerfile."

# --- run with the skill installed at project level ---
mkdir -p "$WORK/with-skill/.claude/skills"
cp -R "$ROOT/skills/devops-best-practices" "$WORK/with-skill/.claude/skills/"
echo "  running claude with skill (this can take a minute)..."
OUT_SKILL=$(cd "$WORK/with-skill" && claude -p "$PROMPT" --max-turns 8 2>/dev/null)
echo "$OUT_SKILL" > "$WORK/with-skill-output.txt"

if echo "$OUT_SKILL" | grep -q "cgr.dev/chainguard"; then
  echo "  ok: with skill, Dockerfile uses Chainguard image"
else
  echo "  FAIL: with skill, no cgr.dev/chainguard in output"
  fails=$((fails + 1))
fi
if echo "$OUT_SKILL" | grep -qiE "AS build|COPY --from|nonroot|USER "; then
  echo "  ok: with skill, multi-stage and/or non-root present"
else
  echo "  FAIL: with skill, no multi-stage/non-root signals"
  fails=$((fails + 1))
fi

# --- control run without the skill (informational only) ---
mkdir -p "$WORK/no-skill"
echo "  running control without skill..."
OUT_PLAIN=$(cd "$WORK/no-skill" && claude -p "$PROMPT" --max-turns 8 2>/dev/null)
if echo "$OUT_PLAIN" | grep -q "cgr.dev/chainguard"; then
  echo "  note: control ALSO used Chainguard (skill effect not isolated this run)"
else
  echo "  note: control did not use Chainguard — skill changed the output"
fi

if [ "$fails" -eq 0 ]; then
  echo "e2e_skill_effect: PASS"
else
  echo "  (with-skill output saved during run; inspect by re-running manually)"
  echo "e2e_skill_effect: FAIL ($fails)"
fi
exit "$fails"
