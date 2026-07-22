#!/bin/sh
# Unit tests: validate the static site pages.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SITE="$ROOT/site"
ONELINER="curl -fsSL https://raw.githubusercontent.com/zenconnor/ihatedevops/main/install.sh | sh"
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

echo "unit_site:"
for p in index privacy terms; do
  check "$p.html exists" test -f "$SITE/$p.html"
done
if [ -f "$SITE/index.html" ]; then
  check "index has install one-liner" grep -qF "$ONELINER" "$SITE/index.html"
  check "index has copy-to-clipboard" grep -qi "clipboard" "$SITE/index.html"
  check "index links to github repo" grep -q "github.com/zenconnor/ihatedevops" "$SITE/index.html"
  check "index links privacy" grep -q "privacy.html" "$SITE/index.html"
  check "index links terms" grep -q "terms.html" "$SITE/index.html"
fi
for p in index privacy terms; do
  f="$SITE/$p.html"
  [ -f "$f" ] || continue
  # Self-contained: no external scripts/stylesheets/images (anchor links are
  # fine; Google Analytics is the one deliberate exception).
  check "$p.html has no external assets beyond GA" sh -c "! grep -Eo '<(script[^>]+src|link[^>]+href|img[^>]+src)=\"https?://[^\"]*' '$f' | grep -v googletagmanager.com | grep -v 'rel=\"canonical\"' | grep -q ."
done
if [ -f "$SITE/privacy.html" ]; then
  check "privacy discloses analytics honestly" sh -c "grep -qi 'google analytics' '$SITE/privacy.html' && grep -qi 'no ads' '$SITE/privacy.html'"
fi
if [ -f "$SITE/index.html" ]; then
  check "index has star button with click tracking" sh -c "grep -q 'gh-star' '$SITE/index.html' && grep -q 'github_star_click' '$SITE/index.html'"
  check "index has all 4 install tabs" sh -c "[ \$(grep -c 'data-tab=' '$SITE/index.html') -eq 4 ] && grep -q '/plugin marketplace add' '$SITE/index.html' && grep -q '.agents/skills' '$SITE/index.html'"
  check "index has SEO meta (canonical, og, JSON-LD)" sh -c "grep -q 'rel=\"canonical\"' '$SITE/index.html' && grep -q 'og:title' '$SITE/index.html' && grep -q 'SoftwareApplication' '$SITE/index.html'"
fi
check "sitemap.xml exists and robots points to it" sh -c "test -f '$SITE/sitemap.xml' && grep -q 'sitemap.xml' '$SITE/robots.txt'"
for p in index privacy terms 404; do
  check "$p.html has the Google tag placeholder exactly once" sh -c "[ \$(grep -c 'gtag/js?id=__GA_ID__' '$SITE/$p.html') -eq 1 ]"
done
if [ -f "$SITE/terms.html" ]; then
  check "terms mention no warranty / as is" sh -c "grep -qiE 'as is|no warranty|without warrant' '$SITE/terms.html'"
fi

[ "$fails" -eq 0 ] && echo "unit_site: PASS" || echo "unit_site: FAIL ($fails)"
exit "$fails"
