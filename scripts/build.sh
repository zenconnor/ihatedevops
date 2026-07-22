#!/bin/sh
# Cloudflare Pages build: copy site/ to dist/, injecting $GA_ID into the
# Google tag. If GA_ID is unset, the entire GA block is stripped — local
# and un-configured builds ship zero analytics.
# CF settings: build command "sh scripts/build.sh", output directory "dist".
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)

rm -rf "$ROOT/dist"
cp -R "$ROOT/site" "$ROOT/dist"

for f in "$ROOT"/dist/*.html; do
  if [ -n "${GA_ID:-}" ]; then
    sed -i.bak "s/__GA_ID__/${GA_ID}/g" "$f"
  else
    sed -i.bak '/<!-- ga:start/,/<!-- ga:end -->/d' "$f"
  fi
  rm -f "$f.bak"
done

echo "built dist/ (GA: ${GA_ID:-disabled})"
