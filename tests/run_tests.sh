#!/bin/sh
# Test runner. Usage: tests/run_tests.sh [--e2e]
set -u
DIR=$(cd "$(dirname "$0")" && pwd)
total=0; failed=0

run() {
  name=$1
  total=$((total + 1))
  if sh "$DIR/$name"; then :; else failed=$((failed + 1)); fi
  echo ""
}

run unit_skill.sh
run unit_site.sh
run unit_build.sh
run integration_install.sh
if [ "${1:-}" = "--e2e" ]; then
  run e2e_skill_effect.sh
fi

if [ "$failed" -eq 0 ]; then
  echo "ALL PASS ($total suites)"
else
  echo "FAILED: $failed of $total suites"
fi
exit "$failed"
