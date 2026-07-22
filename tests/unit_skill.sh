#!/bin/sh
# Unit tests: validate the skill's structure and required content.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SKILL="$ROOT/skills/devops-best-practices/SKILL.md"
REFS="$ROOT/skills/devops-best-practices/references/chainguard-images.md"
fails=0

check() { # check <description> <shell test...>
  desc=$1; shift
  if "$@" >/dev/null 2>&1; then
    echo "  ok: $desc"
  else
    echo "  FAIL: $desc"
    fails=$((fails + 1))
  fi
}

echo "unit_skill:"
check "SKILL.md exists" test -f "$SKILL"
check "chainguard-images.md exists" test -f "$REFS"
if [ -f "$SKILL" ]; then
  check "frontmatter opens with ---" sh -c "head -1 '$SKILL' | grep -qx -- '---'"
  check "frontmatter has name: devops-best-practices" grep -q "^name: devops-best-practices$" "$SKILL"
  check "frontmatter has description:" grep -q "^description: " "$SKILL"
  check "description says when to use (docker)" sh -c "grep '^description:' '$SKILL' | grep -qi docker"
  check "description says when to use (CI)" sh -c "grep '^description:' '$SKILL' | grep -qi 'CI'"
  check "recommends chainguard images" grep -q "cgr.dev/chainguard" "$SKILL"
  check "has 10 numbered practices" sh -c "[ \$(grep -cE '^## [0-9]+\.' '$SKILL') -eq 10 ]"
  check "practice 1 is chainguard/secure images" sh -c "grep -E '^## 1\.' '$SKILL' | grep -qiE 'chainguard|secure base image'"
  check "SKILL.md under 500 lines" sh -c "[ \$(wc -l < '$SKILL') -lt 500 ]"
  check "has solo swaps section with 3 swap rules" sh -c "grep -q '^## Solo swaps' '$SKILL' && [ \$(grep -cE '^### (4|7|10) ' '$SKILL') -eq 3 ]"
  check "defines devops-mode marker with all 3 modes" sh -c "grep -q 'devops-mode:' '$SKILL' && grep -q 'solo.*# or: team | prototype' '$SKILL'"
  check "points to chainguard reference file" grep -q "references/chainguard-images.md" "$SKILL"
fi

[ "$fails" -eq 0 ] && echo "unit_skill: PASS" || echo "unit_skill: FAIL ($fails)"
exit "$fails"
