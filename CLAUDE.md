# CLAUDE.md — Krusader for Unraid (Selkies)

Guide for working in this repo. Owner: `junkerderprovinz`. Public repo.

## What this is

An **own-image container** repo: Krusader (KDE twin-pane file manager) packaged
on top of `ghcr.io/linuxserver/baseimage-selkies`, streamed to the browser via
Selkies, with Dark Mode, Kate editor, full archive/RAR support and 33 UI
languages. There is **no Go, no Node app, no Python service** — the deliverable
is the Docker image. `scripts/build_logo.py` and `.github/assets/gen-banner.mjs`
are one-off asset generators, not part of the runtime.

## Layout

- `Dockerfile` — multi-stage build. A `krusader-build` builder stage compiles
  Krusader 2.9.0 from the KDE source tarball (hash-pinned) with the panel
  icon-tint patches in `patches/`, then installs it over the apt package in the
  final Selkies stage. `KRUSADER_SOURCE_BUILD=1` (default) enables the source
  build; `=0` falls back to plain apt Krusader.
- `patches/` — quilt-style `.patch` files applied to the Krusader source
  (`0001-panel-icon-tint`, `0002-container-version-marker`). LF-only.
- `rootfs/` — everything shipped into the image (LF-only, see `.gitattributes`):
  - `rootfs/etc/s6-overlay/s6-rc.d/` — s6-overlay v3 init: `init-krusader`
    (seeds `/config` from `/defaults` on first run, sets theme/locale),
    `init-nologin`, `init-nginx`, `svc-krusader-ready`.
  - `rootfs/usr/local/bin/` — `krusader-language.sh`, `krusader-session`,
    `print-banner.sh`.
  - `rootfs/defaults/` — seed configs (krusaderrc, kdeglobals, katerc,
    DarkMode color scheme, openbox, autostart, startwm.sh, useractions).
- `.github/workflows/` — `build.yml`, `lint.yml`, `release.yml`,
  `registry-cleanup.yml`.
- `.github/release-notes/<tag>.md` — per-release notes consumed by `release.yml`.
- `.github/assets/` — banner/icon sources + generators.
- `docs/PUBLISHING.md` — internal CA-listing checklist (not user-facing).
- `README.md`, `TROUBLESHOOTING.md`, `NOTICE`, `LICENSE` (MIT wrapper; Krusader
  upstream is GPL-3.0).

Note: the Unraid Community Applications **template XML lives in the central
`unraid-apps` feed repo, not here.**

## Build / test / lint / release commands

A `justfile` wraps the real flows — `just --list` to see them. The underlying
commands:

```sh
# Build (local arch) — mirrors CI's smoke image
docker build -t krusader:dev .

# Multi-arch build (needs buildx)
docker buildx build --platform linux/amd64,linux/arm64 -t krusader:dev --load .

# Smoke gate (what CI asserts): patched-binary marker + WebUI boot
docker run --rm --entrypoint sh krusader:dev -c 'test -f /usr/share/krusader/.icontint'
docker run -d --name kru -p 3000:3000 -p 3001:3001 krusader:dev
# then curl -k https://localhost:3001/  (any non-000 HTTP status = up)

# Lint (matches lint.yml)
hadolint --ignore DL3008 --ignore DL3009 --ignore DL3059 --ignore SC2086 Dockerfile
shellcheck -S warning -x -e SC1091 <rootfs shell scripts>   # *.sh, run, autostart, krusader-session
xmllint --noout <every *.xml>

# Secrets scan
gitleaks detect --no-banner
```

There is **no `gofmt`/`go test`** (no Go) and no `npm test` (no app frontend).

### Release procedure

- Versioning: **3-digit SemVer**, tag `vX.Y.Z`.
- `release.yml` fires on a pushed `v*.*.*` tag: it uses
  `.github/release-notes/<tag>.md` as the release body if present, else
  auto-generates. **Release title = the version only** (`vX.Y.Z`), no repo-name
  heading, no link lists — the notes file IS the full changelog.
- **NEVER tag or create a release without explicit approval.** Bumping content
  is fine; cutting the version is a gated, approval-only step.
- `sync-repo` before tagging: `git fetch origin && git pull --rebase origin main`.

## CI gates

- **build.yml** — one NATIVE build job per arch (amd64 on `ubuntu-latest`,
  arm64 on `ubuntu-24.04-arm`). Each job: builds `krusader:smoke-<arch>` with
  `load: true`, runs the **smoke gate** (asserts the `.icontint` marker AND that
  the patched binary reports the `icontint` version marker, then boots the
  container and waits for the Selkies WebUI), runs a **non-blocking Trivy CVE
  scan** (`krusader:smoke-<arch>`, HIGH/CRITICAL, `ignore-unfixed`, `exit-code:
  "0"`; SARIF → Security tab, category `trivy-<arch>`), then pushes **by digest**.
  A `merge` job assembles the multi-arch manifest with `buildx imagetools
  create` for all tags (GHCR + Docker Hub mirror when `DOCKERHUB_USERNAME` is
  set) and syncs the README to Docker Hub.
- **lint.yml** — hadolint (Dockerfile), shellcheck (rootfs scripts),
  xmllint (all XML). Runs on push + PR.
- **registry-cleanup.yml** — prunes old GHCR versions.

Because the build is **push-by-digest + `imagetools` manifest merge** (native
matrix), SBOM/provenance are **NOT** attached on `build-push-action` (digest
mode needs different handling than a plain build-push); only Trivy is wired in.

## Repo-specific gotchas

- **LF is mandatory** for `rootfs/**`, `*.sh`, `patches/*.patch`, and the banner
  raw text (`.gitattributes`). A CRLF checkout breaks shebangs / figlet / patch
  apply. Strip CR (`sed -i 's/\r$//'`) on any new shell/rootfs/workflow file.
- **Builder ABI coupling**: the `krusader-build` stage must use the SAME Ubuntu
  series as `BASE_TAG` (both `resolute`). Changing `BASE_TAG` to another series
  requires `KRUSADER_SOURCE_BUILD=0`, or the binary won't start — the CI smoke
  gate catches this.
- **Krusader tarball is hash-pinned** (`KRUSADER_SHA256`); bumping
  `KRUSADER_VERSION` requires updating the hash too.
- **hadolint ignores** are intentional: `DL3008`/`DL3009`/`SC2086` (see the
  comments in `lint.yml`) — package versions move with Ubuntu, apt lists are
  cleaned once per phase, and the package wishlist relies on word splitting.
- **No default login** by design: `SELKIES_ENABLE_BASIC_AUTH=false` +
  `init-nologin` drop the base's default credentials; a real
  `CUSTOM_USER`/`PASSWORD` re-enables nginx basic auth.
- **Boot env stays language-neutral** (`LANG=C.UTF-8`); `KRUSADER_LANG` drives
  the UI via kdeglobals `[Translations]`. Do not hardcode a regional `LANG`/
  `LC_ALL` (that caused issue #21).

## Conventions

- Repo content (code, comments, README, commit messages) in **English**;
  chat/vault in German.
- **No AI/assistant attribution** anywhere (commits, files, notes).
- Keep the README, `TROUBLESHOOTING.md` and the `unraid-apps` template entry in
  sync with any behaviour change.
