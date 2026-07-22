# ihatedevops Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a Claude Code skill that injects 10 atomic DevOps best practices into any session, plus a terminal-aesthetic landing page for ihatedevops.com with install one-liner, privacy policy, and terms — all tested and committed to main.

**Architecture:** A static no-build website (`site/`) and a self-contained Claude Code skill (`skill/ihatedevops/SKILL.md`) installed via a POSIX `install.sh` that copies the skill into `~/.claude/skills/`. Tests are plain shell scripts (unit = skill/site structure validation, integration = install into a temp HOME, e2e = headless `claude -p` run checking the skill actually changes Dockerfile output).

**Tech Stack:** Plain HTML/CSS/JS (no framework, no build), POSIX sh, Claude Code skill format (SKILL.md with YAML frontmatter).

## Global Constraints

- Repo: github.com/zenconnor/ihatedevops, commit directly to `main` (user-authorized).
- Install must work on macOS with only `curl` + `sh` (primary audience: Mac users).
- Skill must follow Claude Code skill format: dir `ihatedevops/`, `SKILL.md` with `name` + `description` frontmatter; description must state when to trigger.
- Chainguard secure-images practice MUST be practice #1.
- Website: calm terminal aesthetic, copy-to-clipboard install command, links to GitHub repo, privacy policy, terms of use. Self-contained (no CDN dependencies).
- Least-work-necessary principle: no build tooling, no test framework deps, smallest file set that works.

## File Structure

```
README.md                          — what/why/install
LICENSE                            — MIT
install.sh                         — copies skill into ~/.claude/skills/ (curl-pipeable)
skill/ihatedevops/
  SKILL.md                         — frontmatter + the 10 atomic practices
  references/chainguard-images.md  — image substitution table + caveats
site/
  index.html                       — terminal landing page w/ copy button
  privacy.html                     — simple privacy policy
  terms.html                       — simple terms of use
tests/
  run_tests.sh                     — runs unit + integration (+ e2e with --e2e)
  unit_skill.sh                    — validates skill structure/content
  unit_site.sh                     — validates site pages
  integration_install.sh           — installs into temp HOME, verifies layout
  e2e_skill_effect.sh              — headless claude run; skill changes output
docs/superpowers/plans/2026-07-21-ihatedevops.md  — this plan
docs/DEVIATIONS.md                 — how implementation deviated from plan
```

---

### Task 1: Research top-10 atomic practices (subagent)

**Files:** none (feeds Task 2 content)

- [x] **Step 1:** Dispatch general-purpose subagent with WebSearch to rank 12 candidate atomic practices (Chainguard mandatory, near top). Done — running in background.
- [x] **Step 2 (done):** On completion, select top 10 and reconcile with the provisional list in Task 2. Document any changes in docs/DEVIATIONS.md.

**Provisional top 10 (to be confirmed by research):**
1. Default to Chainguard secure base images (cgr.dev/chainguard/*) in Dockerfiles/CI.
2. Multi-stage Docker builds + non-root USER.
3. Pin dependencies: lockfiles committed, base images by digest, GitHub Actions by commit SHA.
4. Least-privilege CI tokens (explicit `permissions:` block in workflows).
5. Never put secrets in code, images, or logs; prefer OIDC/secret managers over long-lived keys.
6. Every service ships a health endpoint; every deploy is rollback-ready.
7. Plan-before-apply for infra-as-code; never hand-edit live infra.
8. Structured (JSON) logging with levels; no printf-debugging in prod paths.
9. Fail fast in CI: lint/typecheck before build, build before test, cache aggressively.
10. Small, frequent, reversible releases over big-bang deploys.

### Task 2: The skill

**Files:**
- Create: `skill/ihatedevops/SKILL.md`
- Create: `skill/ihatedevops/references/chainguard-images.md`
- Test: `tests/unit_skill.sh`

**Interfaces:**
- Produces: skill dir consumed verbatim by `install.sh` (Task 3) and validated by `tests/unit_skill.sh` (Task 5).
- SKILL.md frontmatter: `name: ihatedevops`, `description:` beginning "Use when" and mentioning Docker, CI/CD, deploy, infra.

- [x] **Step 1:** Write `tests/unit_skill.sh` asserting: SKILL.md exists; frontmatter has `name:` and `description:`; description contains trigger words (docker, ci); body contains `cgr.dev/chainguard`; ≥10 numbered practices; file < 500 lines; references/chainguard-images.md exists.
- [x] **Step 2:** Run it. Expected: FAIL (files missing).
- [x] **Step 3:** Write SKILL.md — frontmatter, "when to apply" table, the 10 practices each as: rule ("when X do Y"), why (one line), before/after snippet where useful. Write references/chainguard-images.md with common image mappings (node, python, go, nginx, jdk, postgres...), -dev variant guidance, no-shell caveats, multi-stage pattern.
- [x] **Step 4:** Run `tests/unit_skill.sh`. Expected: PASS.
- [x] **Step 5:** Commit: `feat: add ihatedevops Claude Code skill`

### Task 3: install.sh

**Files:**
- Create: `install.sh`
- Test: `tests/integration_install.sh`

**Interfaces:**
- Consumes: `skill/ihatedevops/` layout from Task 2.
- Produces: `~/.claude/skills/ihatedevops/` install; honors `$HOME`; curl-pipeable (`curl -fsSL <raw url> | sh`) by cloning via git archive/tarball from GitHub when run outside the repo, or copying locally when run inside it.

- [x] **Step 1:** Write `tests/integration_install.sh`: run install.sh with `HOME=$(mktemp -d)` from repo checkout; assert SKILL.md + references land in `$HOME/.claude/skills/ihatedevops/`; re-run to confirm idempotent (overwrite, exit 0).
- [x] **Step 2:** Run it. Expected: FAIL (install.sh missing).
- [x] **Step 3:** Write install.sh (POSIX sh, `set -eu`): detect local checkout (skill dir next to script) → cp -R; else download tarball `https://github.com/zenconnor/ihatedevops/archive/refs/heads/main.tar.gz` and extract the skill dir. Print friendly success message.
- [x] **Step 4:** Run integration test. Expected: PASS (local path; tarball path exercised only if network + repo pushed — skip gracefully with a note).
- [x] **Step 5:** Commit: `feat: add curl-pipeable install script`

### Task 4: Website

**Files:**
- Create: `site/index.html`, `site/privacy.html`, `site/terms.html`
- Test: `tests/unit_site.sh`

**Interfaces:**
- Consumes: install one-liner string (Task 3): `curl -fsSL https://raw.githubusercontent.com/zenconnor/ihatedevops/main/install.sh | sh`
- Produces: static pages deployable as-is (GitHub Pages compatible).

- [x] **Step 1:** Write `tests/unit_site.sh` asserting: three pages exist; index contains the install one-liner, a copy button/clipboard JS, link to github.com/zenconnor/ihatedevops, links to privacy.html and terms.html; no external `http` asset references (self-contained); privacy/terms contain minimal required statements.
- [x] **Step 2:** Run it. Expected: FAIL.
- [x] **Step 3:** Build index.html: dark calm terminal window (macOS traffic-light dots, monospace, muted greens/grays, subtle typing cursor), hero = fake terminal session showing the skill in action, prominent `$ curl ... | sh` block with copy button (navigator.clipboard + fallback), sections: what it is, the 10 practices list, GitHub link, footer with privacy/terms. Inline CSS/JS only. privacy.html/terms.html: same shell, short plain-language policies (no accounts, no tracking, no cookies; MIT; no warranty).
- [x] **Step 4:** Run `tests/unit_site.sh`. Expected: PASS. Also open in Browser pane to eyeball aesthetics.
- [x] **Step 5:** Commit: `feat: add terminal landing page with privacy + terms`

### Task 5: Test harness + e2e

**Files:**
- Create: `tests/run_tests.sh`, `tests/e2e_skill_effect.sh`

**Interfaces:**
- Consumes: everything above.
- Produces: `tests/run_tests.sh` exits 0 on green; `--e2e` flag runs the claude-CLI test.

- [x] **Step 1:** Write `run_tests.sh` (runs unit_skill, unit_site, integration_install; `--e2e` adds e2e; prints PASS/FAIL summary, nonzero exit on failure).
- [x] **Step 2:** Write `e2e_skill_effect.sh`: with skill installed into a temp project's `.claude/skills/`, run `claude -p "Write a Dockerfile for a small Node.js web server" --max-turns N` in that dir and assert output mentions `cgr.dev/chainguard` and non-root USER; control run without skill for comparison (report, don't hard-fail control). Skip cleanly if `claude` CLI absent.
- [x] **Step 3:** Run full suite including e2e. Expected: PASS (or e2e SKIP with reason, documented).
- [x] **Step 4:** Commit: `test: add test harness and e2e skill-effect test`

### Task 6: README, LICENSE, deviations, ship

**Files:**
- Create: `README.md`, `LICENSE`, `docs/DEVIATIONS.md`

- [x] **Step 1:** README: what it is, install one-liner, the 10 practices, site link, test instructions, license.
- [x] **Step 2:** LICENSE: MIT (zenconnor, 2026).
- [x] **Step 3:** docs/DEVIATIONS.md: record every deviation from this plan (per project rules).
- [x] **Step 4:** Final self-review pass (least-work check: delete anything removable without breaking function). Run full test suite once more. Expected: PASS.
- [x] **Step 5:** Commit + push to main.

## Self-Review

- Spec coverage: landing page w/ privacy+terms+copyable install+GitHub link (Task 4); skill (Task 2); research (Task 1); top-10 incl. Chainguard (Tasks 1–2); unit/integration/e2e tests (Tasks 2,3,5); rules-compliance via plan doc + DEVIATIONS.md (Task 6). ✓
- No placeholders beyond research-pending top-10 note, which Task 1 Step 2 resolves. ✓
- Interface consistency: install path `~/.claude/skills/ihatedevops/`, one-liner URL, skill dir name used identically across Tasks 2–5. ✓
