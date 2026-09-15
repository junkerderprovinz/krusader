#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# krusader-resolution.sh
# -----------------------------------------------------------------------------
# Prints the screen size the X server should be started with, or nothing when
# neither variable is set (then the base image's own default applies).
#
# Why two variables: Unraid renders a template variable as a plain <select> as
# soon as its Default contains a "|" (see CreateDocker.php, addConfig()), so a
# dropdown of presets and a free-text field cannot be the same field. The
# template therefore offers MAX_RES as the preset dropdown and MAX_RES_CUSTOM
# as a free field, and this script decides between them:
#
#   MAX_RES_CUSTOM set and usable  -> that value wins
#   otherwise                      -> MAX_RES as chosen in the dropdown
#
# A malformed custom value is REPORTED AND IGNORED rather than passed on. Xvfb
# takes the screen size as a literal command line argument, so a typo like
# "1920*1080" would stop the X server from starting at all and the container
# would come up with no desktop. Falling back to the dropdown keeps a working
# session and says what happened; the opposite trade (fail hard on a typo)
# turns a five-second mistake into a dead container.
#
# Spellings people actually type are accepted: surrounding spaces, spaces
# around the separator, and a capital X.
# -----------------------------------------------------------------------------
set -u

log() { echo "[krusader-resolution] $*" >&2; }

normalise() {
    # An Unraid dropdown hands over the whole label it shows, so a preset
    # arrives as "3840x2160 (4K, ~93 MB)" and the size has to be read out of
    # it — the same reason krusader-language.sh strips "de = Deutsch" down to
    # "de". Drop everything from the first "(", then strip whitespace and
    # lowercase the separator so a hand-typed " 1920 X 1080 " works too.
    printf '%s' "${1%%(*}" | tr -d '[:space:]' | tr 'X' 'x'
}

# Largest edge either side may have. This is NOT a product decision about how
# big a desktop may be — the full 15360x8640 and more stay available. It only
# catches a digit slip: "15360x86400" is a well-formed WIDTHxHEIGHT that would
# have the X server ask for a 5 GB framebuffer, so the container would be
# OOM-killed on every single boot with nothing in the log pointing at the typo.
# 16384 is the ceiling X drivers and GL implementations conventionally carry,
# and it sits above the base image's own default.
KR_MAX_EDGE=16384

valid() {
    # WIDTHxHEIGHT, 3 to 5 digits each, no leading zero, both edges within
    # KR_MAX_EDGE. Anything else Xvfb could not parse or could not survive.
    [[ "$1" =~ ^([1-9][0-9]{2,4})x([1-9][0-9]{2,4})$ ]] || return 1
    [ "${BASH_REMATCH[1]}" -le "${KR_MAX_EDGE}" ] && [ "${BASH_REMATCH[2]}" -le "${KR_MAX_EDGE}" ]
}

custom="$(normalise "${MAX_RES_CUSTOM:-}")"
preset="$(normalise "${MAX_RES:-}")"

if [ -n "${custom}" ]; then
    if valid "${custom}"; then
        log "using the custom screen size ${custom}"
        printf '%s' "${custom}"
        exit 0
    fi
    log "WARNING: ignoring MAX_RES_CUSTOM='${MAX_RES_CUSTOM:-}'. Expected WIDTHxHEIGHT like 3440x1440, with each side at most ${KR_MAX_EDGE}. Falling back to ${preset:-the image default}."
fi

if [ -n "${preset}" ]; then
    if valid "${preset}"; then
        printf '%s' "${preset}"
        exit 0
    fi
    log "WARNING: ignoring MAX_RES='${MAX_RES:-}'. Expected WIDTHxHEIGHT, with each side at most ${KR_MAX_EDGE}. Falling back to the image default."
fi

exit 0
