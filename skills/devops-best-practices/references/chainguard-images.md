# Chainguard image migration reference

Chainguard's free public catalog lives at `cgr.dev/chainguard/<image>`.
Free tier = `:latest` and `:latest-dev` tags only (pin by digest for
reproducibility, per rule 3). Images are Wolfi-based, minimal, non-root,
near-zero CVEs, with signed SBOMs (verifiable via `cosign`).

## Common substitutions

| Instead of | Use |
|---|---|
| `node:*` | `cgr.dev/chainguard/node:latest` |
| `python:*` | `cgr.dev/chainguard/python:latest` |
| `golang:*` | `cgr.dev/chainguard/go:latest-dev` (build) → `cgr.dev/chainguard/static:latest` (run) |
| `openjdk:*`, `eclipse-temurin:*` | `cgr.dev/chainguard/jdk:latest` (build) → `cgr.dev/chainguard/jre:latest` (run) |
| `nginx:*` | `cgr.dev/chainguard/nginx:latest` |
| `postgres:*` | `cgr.dev/chainguard/postgres:latest` |
| `redis:*` | `cgr.dev/chainguard/redis:latest` |
| `alpine:*`, `busybox:*` (shell utility base) | `cgr.dev/chainguard/wolfi-base:latest` |
| `scratch` | `cgr.dev/chainguard/static:latest` (adds CA certs, tzdata, non-root user) |
| `php:*` | `cgr.dev/chainguard/php:latest` |
| `ruby:*` | `cgr.dev/chainguard/ruby:latest` |
| `rust:*` | `cgr.dev/chainguard/rust:latest-dev` (build) → `static` (run) |

## Caveats (check before migrating)

- **No shell, no package manager** in runtime images. `docker exec ... sh`
  won't work; debugging happens via logs or ephemeral debug containers.
  If the Dockerfile has `RUN apt-get/apk` steps, those belong in a
  `-dev`-based build stage, never the final image.
- **`-dev` variants** include a shell (`/bin/sh`), `apk`, and build tooling.
  Use them for build stages; do not ship them as the final image.
- **Non-root by default** (user `nonroot`, uid 65532). Files the app writes
  must be in a directory that user owns; `COPY --chown=nonroot:nonroot` as
  needed. Binding ports <1024 needs capability config, so serve on 8080+.
- **Entrypoints differ** from Docker Hub images (e.g. `python` image drops
  straight into python, not a shell). Check with
  `docker inspect cgr.dev/chainguard/<img>:latest`.
- **Version pinning beyond `latest`** requires a paid plan. In the free
  tier, get reproducibility by pinning the digest:
  `cgr.dev/chainguard/node:latest@sha256:<digest>` and refreshing it in CI.
- If a needed image isn't in the free catalog, the fallback order is:
  official slim/distroless variant (`node:20-slim`,
  `gcr.io/distroless/*`) > full official image. Never random third-party hub
  images.

## Debugging a distroless container

In order of preference:

1. **Build the debug twin** (dual-target Dockerfile from SKILL.md rule 1):
   `docker build --target debug -t app:debug . && docker run -it app:debug sh`
2. **Attach a toolbox without rebuilding:** `docker debug <container>`
   (Docker Desktop) — drops a shell + tools into a running container even
   when the image has none.
3. **Kubernetes:** ephemeral debug container sharing the pod's namespaces:
   `kubectl debug -it <pod> --image=cgr.dev/chainguard/wolfi-base --target=<container>`
4. Last resort for a quick local loop: temporarily swap the final `FROM` to
   the `-dev` variant — fine on a branch, never in the image you publish.

## Verify supply chain (optional but cheap)

```sh
cosign verify cgr.dev/chainguard/node:latest \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  --certificate-identity=https://github.com/chainguard-images/images/.github/workflows/release.yaml@refs/heads/main
```
