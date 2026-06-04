#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
# print-banner.sh <container-name> <subtitle>
# Einheitlicher Init-Log-Banner für alle Junker-der-Provinz-Container.
# Layout: ASCII-Banner, dann ZWEI Leerzeilen, dann Titel + Untertitel,
# abgeschlossen mit einer Trennlinie.
# ─────────────────────────────────────────────────────────────────

CONTAINER="${1:-Container}"
SUBTITLE="${2:-}"
BANNER_FILE="/usr/local/share/banner.txt"
SEP="$(printf '─%.0s' $(seq 1 67))"

echo ""
if [ -f "${BANNER_FILE}" ]; then
    cat "${BANNER_FILE}"
else
    echo "  Junker der Provinz"
fi
# Zwei Leerzeilen zwischen ASCII und dem unteren Text.
echo ""
echo ""
printf '  %s\n' "${CONTAINER}"
[ -n "${SUBTITLE}" ] && printf '  %s\n' "${SUBTITLE}"
echo "  ${SEP}"
echo ""
