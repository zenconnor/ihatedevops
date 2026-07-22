#!/bin/sh
# Unit tests: scripts/build.sh injects GA_ID, or strips GA when unset.
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

echo "unit_build:"
GA_ID=G-TESTID123 sh "$ROOT/scripts/build.sh" >/dev/null
for p in index privacy terms 404; do
  check "$p.html: GA_ID injected exactly once" sh -c "[ \$(grep -c 'gtag/js?id=G-TESTID123' '$ROOT/dist/$p.html') -eq 1 ]"
done
check "no placeholder left after inject" sh -c "! grep -rq '__GA_ID__' '$ROOT/dist'"

unset GA_ID
sh "$ROOT/scripts/build.sh" >/dev/null
check "GA block stripped from pages when GA_ID unset" sh -c "! grep -q 'googletagmanager' '$ROOT'/dist/*.html"
check "page content intact after strip" sh -c "grep -q 'gh-star' '$ROOT/dist/index.html' && grep -q '</head>' '$ROOT/dist/index.html'"

rm -rf "$ROOT/dist"
[ "$fails" -eq 0 ] && echo "unit_build: PASS" || echo "unit_build: FAIL ($fails)"
exit "$fails"
