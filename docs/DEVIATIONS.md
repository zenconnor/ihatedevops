# Deviations from the plan

Plan: [superpowers/plans/2026-07-21-ihatedevops.md](superpowers/plans/2026-07-21-ihatedevops.md)

1. **Execution mode:** Plan offers subagent-driven vs. inline execution as a
   user choice; session ran autonomously, so tasks were executed inline, with
   the research task (Task 1) delegated to a subagent as planned.
2. **Top-10 reconciliation (Task 1 Step 2):** Research returned 12 candidates
   that matched the provisional 10 in substance. Differences folded in rather
   than restructuring the list: OIDC federation stayed merged into practice 5
   (research ranked it standalone), `.dockerignore` stayed merged into
   practice 2, and two research details were added to the skill —
   `RUN --mount=type=secret` for build-time secrets (practice 5) and
   "tag published images with the git SHA, never only `:latest`" (practice 3).
3. **Shared stylesheet:** Plan implied per-page inline CSS ("Inline CSS/JS
   only"); implementation uses one shared `site/style.css` (relative link,
   still zero external dependencies) to avoid triplicating ~150 lines across
   the three pages. The self-containment test guards the actual requirement
   (no external assets).
4. **License (post-ship, user request):** Plan and initial release used MIT;
   switched to GPL-3.0 on 2026-07-21 to keep derivatives open source while
   preserving the owner's ability to dual-license commercially.
5. **Site test regex:** The planned "no external assets" check used a negative
   lookahead unsupported by `grep -E`; rewritten to match external
   `script src` / `link href` / `img src` attributes instead.
