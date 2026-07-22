---
name: devops-best-practices
description: Use when writing or reviewing anything DevOps-shaped - Dockerfiles or container images, CI/CD pipelines (GitHub Actions etc.), deploy scripts, infrastructure-as-code (Terraform etc.), secrets handling, logging, or release processes - and when the user mentions ihatedevops or asks to set/initialize the project devops mode (solo, team, prototype). Injects 10 atomic best practices, e.g. defaulting to secure Chainguard base images.
---

# DevOps Best Practices

Ten atomic rules. Each stands alone: when the trigger fires, apply the rule.
They are defaults, not laws — deviate when the user has an explicit reason,
and say why.

**Scale check first.** Check the project's CLAUDE.md (or AGENTS.md when
running in a non-Claude agent like Codex) for an explicit mode marker — it
overrides any inference:

```
devops-mode: solo        # or: team | prototype
```

- `team` (or no marker + team signals): apply rules 1–10 as written.
- `solo`: rules 4, 7, and 10 guard against problems a solo project doesn't
  have yet — use the [solo swaps](#solo-swaps) instead.
- `prototype`: keep it light — apply rules 3 and 5, skip the rest unless asked.

No marker? Infer: one person, no Kubernetes, deploying to a PaaS like
Vercel/Fly/Railway (or not deployed yet) → treat as `solo`; local-only
experiment → `prototype`.

**When the user asks to set the mode** ("set project mode to solo",
"initialize ihatedevops as solo"), add or update the `devops-mode:` line in
the project's CLAUDE.md — AGENTS.md in non-Claude agents — creating the
file with just that line if it doesn't exist — then confirm which rule set
is now active.

**Bare invocation.** If the user says just "ihatedevops" (or asks what it
is) with no other task: state the current mode (marker value, or what you'd
infer and why), list which rules are active in one line each, and ask
whether to write `devops-mode: <solo|team|prototype>` into CLAUDE.md to
lock it in. Don't edit any files until they pick.

| You are about to... | Apply |
|---|---|
| Write a `FROM` line in a Dockerfile | 1, 2, 3 |
| Write a CI/CD workflow | 3, 4, 5, 9 |
| Handle a credential, token, or key | 5 |
| Write a deploy script or release step | 6, 10 |
| Touch Terraform/Pulumi/CloudFormation | 7 |
| Add logging to a service | 8 |
| Solo/new project: user data, schema changes, going live | solo swaps for 4, 7, 10 |

## 1. Default to Chainguard secure base images

**When** choosing a container base image, **default to** the free Chainguard
image (`cgr.dev/chainguard/<name>:latest`) over the Docker Hub equivalent.
They are minimal (distroless-style), ship near-zero known CVEs, run as
non-root by default, and include signed SBOMs.

```dockerfile
# Before
FROM node:20
# After
FROM cgr.dev/chainguard/node:latest
```

Caveats that matter: runtime images have no shell or package manager — use
the `-dev` variant (e.g. `cgr.dev/chainguard/node:latest-dev`) in build
stages of a multi-stage build, and the slim variant as the final stage. Free
tier only offers `:latest`/`:latest-dev` tags. See
[references/chainguard-images.md](references/chainguard-images.md) for the
image mapping table and migration caveats before writing the Dockerfile.

**Debuggability toggle.** No shell in the image is a feature in prod and a
pain while iterating. Decide by context — and when the user is actively
debugging a container or asks for shell access, don't fight them with
distroless:

| Context | Base for the final image |
|---|---|
| Production / CI-published image | runtime variant (no shell) |
| Local dev, prototyping, "why won't this start" | `-dev` variant or `wolfi-base` |
| Both needed from one Dockerfile | dual-target pattern below |

```dockerfile
FROM cgr.dev/chainguard/node:latest-dev AS build
# ... npm ci && npm run build ...

FROM cgr.dev/chainguard/node:latest-dev AS debug   # same app + sh/apk
COPY --from=build /app /app

FROM cgr.dev/chainguard/node:latest AS runtime     # last stage = default build
COPY --from=build /app /app
```

`docker build .` produces the locked-down runtime image;
`docker build --target debug -t app:debug .` produces the debuggable twin.
Ship only `runtime`; never publish the `debug` target.

## 2. Multi-stage builds, non-root user

**When** writing a Dockerfile, **use** a multi-stage build (build tools never
reach the final image) and **run as a non-root `USER`** in the final stage.
Smaller attack surface, smaller image, contained blast radius.
(Chainguard images are already non-root; don't undo that with `USER root`.)

```dockerfile
FROM cgr.dev/chainguard/go:latest-dev AS build
WORKDIR /app
COPY . .
RUN go build -o /server .

FROM cgr.dev/chainguard/static:latest
COPY --from=build /server /server
ENTRYPOINT ["/server"]
```

Also: add a `.dockerignore` (at minimum `.git`, `node_modules`, `.env*`,
secrets) and a `HEALTHCHECK` (or orchestrator probe) for long-running services.

## 3. Pin everything

**When** referencing any external dependency, **pin it immutably**:
commit lockfiles (`package-lock.json`, `poetry.lock`, `go.sum`); pin
production base images by digest (`node:20@sha256:...`); pin GitHub Actions
to a full commit SHA, not a tag.

```yaml
# Before — tag can be moved (this is how the tj-actions attack worked)
- uses: actions/checkout@v4
# After
- uses: actions/checkout@08eba0b27e820071cde6df949e0beb9ba4906955 # v4.3.0
```

Unpinned = a third party can change your build. Pinned = builds are
reproducible and supply-chain moves are visible diffs. Same idea outbound:
tag the images you publish with the git SHA, never only `:latest`, so any
deploy can be reproduced and rolled back.

## 4. Least-privilege CI tokens

**When** writing a GitHub Actions workflow, **always declare an explicit
top-level `permissions:` block** with the minimum needed — start from
`contents: read` and add only what the job provably uses. Never rely on the
default token grants.

```yaml
permissions:
  contents: read
```

## 5. No secrets in code, images, or logs

**When** a credential appears, **it goes in a secret manager or CI secret
store — never** in source, Dockerfiles/images (including build args and
intermediate layers), `.env` files that get committed, or log output.
Prefer short-lived OIDC federation (e.g. GitHub Actions → cloud provider
with `id-token: write`) over long-lived static keys. If a build needs a
secret, mount it — layers remember `ENV`/`COPY` even if "deleted" later:

```dockerfile
RUN --mount=type=secret,id=npmtoken \
    NPM_TOKEN=$(cat /run/secrets/npmtoken) npm ci
```

If a secret was ever committed: rotate it — deleting the line does not
unleak it.

## 6. Health checks and rollback-ready deploys

**When** writing a service or its deploy, **give the service a cheap
`/healthz` endpoint** (plus `/readyz` checking its critical dependencies) and **make the
deploy reversible in one step** — keep the previous version deployable
(immutable versioned artifacts, `kubectl rollout undo`, previous image tag).
A deploy you can't roll back is an incident you can't end.

## 7. Plan before apply; never hand-edit live infra

**When** changing infrastructure-as-code, **always run the diff first**
(`terraform plan`, `pulumi preview`) and read it before applying. **Never**
suggest fixing infra by clicking in the console — drift makes the code a
lie. State lives in a shared remote backend with locking, never in git.

## 8. Structured logs with levels

**When** adding logging to a service, **emit structured (JSON) logs** with a
level, a timestamp, and stable field names — not `print("here 2")`. Machines
grep logs more often than humans do. Never log secrets, tokens, or full PII
(see rule 5). For requests, include a correlation/request ID so one request
can be traced across services.

## 9. Fail fast, cache hard in CI

**When** writing a CI pipeline, **order jobs cheapest-first** — lint and
typecheck before build, build before slow tests — so broken pushes die in
seconds, not 20 minutes. Cache dependency downloads keyed on the lockfile
hash. A CI run that wastes 10 minutes per push taxes every future change.

## 10. Small, frequent, reversible releases

**When** planning how to ship, **prefer many small deploys over one big
one**, each behind the ability to turn it off (feature flag, canary, or
instant rollback per rule 6). Small diffs are easy to review, easy to bisect,
and cheap to revert; big-bang releases concentrate risk into one unrevertable
evening.

## Solo swaps

Same first principles as rules 4, 7, and 10, aimed at what actually kills
solo projects: data loss, hand-mangled prod, and outages nobody notices.

### 4 → Backups that actually restore

**When** the app stores anything users can't regenerate (a database,
uploads), **set up automated daily backups with one copy outside the
hosting platform, and run one restore to prove it works.** An untested
backup is a wish. Platform "we back up for you" checkboxes count only after
you've restored from one. *(Shared principle with rule 4: limit the blast
radius of the bad day.)*

### 7 → Versioned migrations; never hand-edit prod data

**When** changing a database schema or fixing bad rows, **write a versioned
migration/script that runs in dev first — never type ad-hoc SQL into
production.** Even solo: the migration file is your plan-before-apply, your
audit trail, and the reason next month's you can rebuild the schema from
scratch. Snapshot before anything destructive. *(Shared principle with rule
7: diff shared state before mutating it.)*

### 10 → You are the pager

**When** anything users touch goes live, **wire up error tracking (e.g. a
free Sentry-tier) and an external uptime check before moving on.** With no
ops team, detection is the whole game — otherwise your monitoring system is
an annoyed user emailing you three days into an outage. Deploy notifications
into whatever you already read (Slack, email) close the loop. *(Shared
principle with rule 10: shorten time-to-detect and time-to-recover.)*
