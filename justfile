# justfile — Krusader for Unraid (Selkies)
# Recipes mirror the real CI flows (see .github/workflows/ and CLAUDE.md).
# Run `just --list` to see everything. POSIX sh recipes.

set shell := ["sh", "-euc"]

# Local image tag used by build/smoke/run (CI uses krusader:smoke-<arch>).
IMAGE := "krusader:dev"

# Show available recipes.
default:
    @just --list

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

# Build the image for the local arch.
build:
    docker build -t {{IMAGE}} .

# Multi-arch build (amd64 + arm64) — needs buildx.
build-multi:
    docker buildx build --platform linux/amd64,linux/arm64 -t {{IMAGE}} --load .

# Emergency build without the source-built Krusader (plain apt binary).
build-noscr:
    docker build --build-arg KRUSADER_SOURCE_BUILD=0 -t {{IMAGE}} .

# ---------------------------------------------------------------------------
# Smoke / run  (mirrors the CI smoke gate)
# ---------------------------------------------------------------------------

# Assert the patched source-built Krusader landed, then boot and probe the WebUI.
smoke: build
    #!/usr/bin/env sh
    set -eu
    img="{{IMAGE}}"
    echo "== patched-Krusader marker =="
    docker run --rm --entrypoint sh "$img" -c 'test -f /usr/share/krusader/.icontint'
    echo "== boot gate =="
    name=kru-smoke
    docker rm -f "$name" >/dev/null 2>&1 || true
    docker run -d --name "$name" -p 3000:3000 -p 3001:3001 "$img" >/dev/null
    deadline=$((SECONDS + 150))
    while [ "$SECONDS" -lt "$deadline" ]; do
        c=$(curl -k -o /dev/null -s -w '%{http_code}' --max-time 5 https://localhost:3001/ || true)
        if [ -n "$c" ] && [ "$c" != "000" ]; then
            echo "WebUI responded (HTTP $c) after ${SECONDS}s"; docker rm -f "$name" >/dev/null; exit 0
        fi
        [ -n "$(docker ps -q --filter name=$name)" ] || { echo "container exited early:"; docker logs "$name"; docker rm -f "$name" >/dev/null; exit 1; }
        sleep 1
    done
    echo "WebUI did not respond within 150s:"; docker logs "$name"; docker rm -f "$name" >/dev/null; exit 1

# Run the image interactively (WebUI on http://localhost:3000).
run:
    docker run --rm -it -p 3000:3000 -p 3001:3001 \
        -v "$PWD/.dev-config:/config" -v "$PWD:/storage" {{IMAGE}}

# ---------------------------------------------------------------------------
# Lint  (mirrors lint.yml)
# ---------------------------------------------------------------------------

# All lint checks.
lint: hadolint shellcheck xmllint

# Hadolint the Dockerfile (same ignores as CI).
hadolint:
    hadolint --ignore DL3008 --ignore DL3009 --ignore DL3059 --ignore SC2086 Dockerfile

# ShellCheck every shell script shipped in the image.
shellcheck:
    #!/usr/bin/env sh
    set -eu
    scripts=$(find rootfs -type f \( -name '*.sh' -o -name 'run' -o -name 'autostart' -o -name 'krusader-session' \))
    [ -n "$scripts" ] || { echo "no shell scripts found — find pattern broken"; exit 1; }
    echo "$scripts"
    shellcheck -S warning -x -e SC1091 $scripts

# Validate every XML file.
xmllint:
    #!/usr/bin/env sh
    set -eu
    find . -name '*.xml' -not -path './.git/*' | while IFS= read -r f; do
        echo "checking $f"; xmllint --noout "$f"
    done

# ---------------------------------------------------------------------------
# Security
# ---------------------------------------------------------------------------

# Scan the working tree for committed secrets.
secrets:
    gitleaks detect --no-banner --redact

# Scan the built image for HIGH/CRITICAL CVEs (report-only, like CI).
trivy: build
    trivy image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 0 {{IMAGE}}

# ---------------------------------------------------------------------------
# Aggregate + assets
# ---------------------------------------------------------------------------

# Full pre-push check: lint + secrets.
check: lint secrets

# Regenerate the logo/icon assets (Python + cairosvg/PIL).
logo:
    python scripts/build_logo.py

# Regenerate the README banner (Node).
banner:
    node .github/assets/gen-banner.mjs

# Remove the local dev image and smoke container.
clean:
    -docker rm -f kru-smoke 2>/dev/null
    -docker rmi {{IMAGE}} 2>/dev/null
