#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Behaviour tests for rootfs/usr/local/bin/krusader-resolution.sh
# -----------------------------------------------------------------------------
# The script decides which screen size the X server should get: the free-text
# variable wins over the template dropdown, and anything unusable falls back
# instead of killing the container.
#
# Run: tests/test-krusader-resolution.sh   (or `just test`)
# -----------------------------------------------------------------------------
set -uo pipefail

RES="$(cd "$(dirname "$0")/.." && pwd)/rootfs/usr/local/bin/krusader-resolution.sh"
[ -f "${RES}" ] || { echo "script not found: ${RES}" >&2; exit 1; }

PASS=0
FAIL=0

ok() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
no() { echo "  FAIL: $1 — expected [$2], got [$3]"; FAIL=$((FAIL + 1)); }

# run <custom> <dropdown> -> prints the chosen value (stderr dropped)
run() { MAX_RES_CUSTOM="$1" MAX_RES="$2" bash "${RES}" 2>/dev/null; }
# warns <custom> <dropdown> -> prints stderr only
warns() { { MAX_RES_CUSTOM="$1" MAX_RES="$2" bash "${RES}" >/dev/null; } 2>&1; }

eq() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1" "$2" "$3"; fi; }

echo "== krusader-resolution =="

# 1) No custom value: the dropdown choice is passed through untouched.
eq "keeps the dropdown value when no custom one is set" \
   "15360x8640" "$(run "" "15360x8640")"

# 2) A custom value wins over the dropdown — the whole point of the second field.
eq "a custom value overrides the dropdown" \
   "3440x1440" "$(run "3440x1440" "5120x2880")"

# 3) Garbage must not reach Xvfb: an unusable custom value would stop the X
#    server from starting at all, so fall back to the dropdown instead.
eq "falls back to the dropdown on a malformed custom value" \
   "5120x2880" "$(run "1920*1080" "5120x2880")"
eq "falls back on a value with no height" \
   "5120x2880" "$(run "1920x" "5120x2880")"
eq "falls back on a non-numeric value" \
   "5120x2880" "$(run "big" "5120x2880")"

# 4) A rejected value must say so — a silent fallback would leave the user
#    wondering why their resolution did nothing.
if warns "1920*1080" "5120x2880" | grep -qi 'ignor'; then
    ok "warns when it ignores a malformed custom value"
else
    no "warns when it ignores a malformed custom value" "a warning on stderr" "$(warns "1920*1080" "5120x2880")"
fi

# 5) People type what looks right to them. Accept the obvious spellings
#    rather than rejecting a value that is clearly meant.
eq "accepts spaces around the x" "1920x1080" "$(run " 1920 x 1080 " "5120x2880")"
eq "accepts a capital X" "2560x1440" "$(run "2560X1440" "5120x2880")"

# 6) Nothing set at all: print nothing, so the caller leaves the base image's
#    own default alone.
eq "prints nothing when neither variable is set" "" "$(run "" "")"

# 6b) A malformed value in the DROPDOWN has to be rejected too, not just in the
#     custom field. Whatever this prints is what the caller writes into the X
#     server's environment, so passing garbage through would stop X from
#     starting and leave the user with no desktop at all.
eq "rejects a malformed dropdown value" "" "$(run "" "1920*1080")"
if warns "" "1920*1080" | grep -qi 'ignor'; then
    ok "warns when it ignores a malformed dropdown value"
else
    no "warns when it ignores a malformed dropdown value" "a warning on stderr" "$(warns "" "1920*1080")"
fi

# 6c) Shape is not enough: a digit slip like 86400 instead of 8640 is a
#     well-formed WIDTHxHEIGHT that would make the X server ask for a
#     multi-gigabyte framebuffer and the container die on every boot. The full
#     base size must still pass — this guards against typos, it does not cap
#     what a user may legitimately choose.
eq "accepts the full base screen size" "15360x8640" "$(run "15360x8640" "")"
eq "rejects a size beyond what the X server can do" "3840x2160" "$(run "20000x10000" "3840x2160")"
eq "rejects an absurd square size" "3840x2160" "$(run "99999x99999" "3840x2160")"

# 7) The Unraid dropdown hands over the whole label it displays, so the preset
#    arrives as "3840x2160 (4K, ~93 MB)" and the size has to be read out of it.
#    Without this the container would silently fall back to the base default
#    and a user who picked 1080p would get the full screen instead.
eq "reads the size out of a labelled preset" \
   "3840x2160" "$(run "" "3840x2160 (4K, ~93 MB)")"
eq "reads the size out of the full-resolution preset" \
   "15360x8640" "$(run "" "15360x8640 (full, ~530 MB)")"
eq "a custom value still beats a labelled preset" \
   "6016x3384" "$(run "6016x3384" "1920x1080 (1080p, ~17 MB)")"

echo "---"
echo "${PASS} passed, ${FAIL} failed"
[ "${FAIL}" -eq 0 ]
