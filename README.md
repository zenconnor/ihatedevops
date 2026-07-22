# ihatedevops

*(tongue in cheek — we don't hate devops. devops is just hard.)*

A [Claude Code](https://claude.com/claude-code) skill that quietly injects **10
atomic DevOps best practices** into every session. Ask for a Dockerfile, get
secure [Chainguard](https://images.chainguard.dev/) base images, a multi-stage
build, and a non-root user — without asking. Ask for a CI pipeline, get
SHA-pinned actions and least-privilege tokens.

**Website:** [ihatedevops.com](https://ihatedevops.com) (source in [`site/`](site/))

## Install (macOS / anything with curl)

```sh
curl -fsSL https://raw.githubusercontent.com/zenconnor/ihatedevops/main/install.sh | sh
```

That copies one folder into `~/.claude/skills/` — nothing else, ever. Your next
Claude Code session picks it up automatically. Uninstall:
`rm -rf ~/.claude/skills/ihatedevops`.

## The 10 practices

1. **Chainguard base images by default** — `cgr.dev/chainguard/*`: minimal, non-root, near-zero CVEs, free
2. **Multi-stage builds, non-root user** — build tools never reach the final image
3. **Pin everything** — lockfiles, image digests, GitHub Actions by commit SHA
4. **Least-privilege CI tokens** — explicit `permissions: contents: read`
5. **No secrets in code, images, or logs** — OIDC over long-lived keys
6. **Health checks + rollback-ready deploys** — `/healthz`, one-step revert
7. **Plan before apply** — read the IaC diff; never hand-edit live infra
8. **Structured logs with levels** — JSON events, not `print("here 2")`
9. **Fail fast, cache hard in CI** — lint before build before test
10. **Small, frequent, reversible releases** — boring deploys are the goal

Full rules with examples: [`skills/ihatedevops/SKILL.md`](skills/ihatedevops/SKILL.md)

## Tests

```sh
tests/run_tests.sh          # unit (skill + site) and integration (installer)
tests/run_tests.sh --e2e    # + end-to-end: headless claude run must apply the practices
```

The e2e test installs the skill into a scratch project, asks a headless
`claude -p` for a Dockerfile, and asserts the output uses Chainguard images and
multi-stage/non-root patterns (with a no-skill control run for comparison).

## License

[GPL-3.0](LICENSE) — © 2026 SentryStack Inc.

Works in OpenAI Codex too (open [Agent Skills](https://agentskills.io) standard):
copy `skills/ihatedevops/` into `~/.agents/skills/`.
