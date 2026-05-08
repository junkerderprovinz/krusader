#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# krusader-language.sh <de|en|system>
# -----------------------------------------------------------------------------
# Setzt die UI-Sprache für Krusader und Kate über $LANGUAGE bzw. die
# kdeglobals [Translations] Sektion. Wird vom firstrun-Hook aufgerufen.
#
# Hintergrund:
#   * KDE/Krusader respektieren die Standard-Locale-Variablen ($LANG, $LANGUAGE)
#   * Zusätzlich kann in kdeglobals unter [Translations] eine Override-Sprache
#     gesetzt werden – das ist robuster für Apps, die nur die Plasma-Logik
#     verwenden.
# -----------------------------------------------------------------------------
set -e

LANG_CODE="${1:-de}"
CONFIG_HOME="/config/home/.config"
PROFILE_FILE="/config/home/.profile"

log() { echo "[krusader-unraid:lang] $*"; }

mkdir -p "${CONFIG_HOME}"
mkdir -p "$(dirname "${PROFILE_FILE}")"

case "${LANG_CODE}" in
    de|de_DE|de_DE.UTF-8)
        LOCALE="de_DE.UTF-8"
        LANGUAGE_CHAIN="de_DE:de:en"
        TRANSLATION="de"
        ;;
    en|en_US|en_US.UTF-8)
        LOCALE="en_US.UTF-8"
        LANGUAGE_CHAIN="en_US:en"
        TRANSLATION="en_US"
        ;;
    system|"")
        LOCALE=""
        LANGUAGE_CHAIN=""
        TRANSLATION=""
        ;;
    *)
        # beliebiger anderer ISO-Code (z.B. fr, es, it)
        LOCALE="${LANG_CODE}.UTF-8"
        LANGUAGE_CHAIN="${LANG_CODE}:en"
        TRANSLATION="${LANG_CODE}"
        ;;
esac

if [[ -z "${LOCALE}" ]]; then
    log "KRUSADER_LANG=system – keine explizite Sprache erzwungen."
    # Override aus kdeglobals entfernen
    if [[ -f "${CONFIG_HOME}/kdeglobals" ]]; then
        sed -i '/^\[Translations\]/,/^\[/{/^Language=/d}' "${CONFIG_HOME}/kdeglobals" || true
    fi
    rm -f "${PROFILE_FILE}.krusader-lang"
    exit 0
fi

log "Aktiviere Sprache: ${LOCALE}"

# 1) Profile schreiben (für interaktive Shells / dbus-launch picks LANG aus env auf)
cat > "${PROFILE_FILE}.krusader-lang" <<EOF
export LANG=${LOCALE}
export LANGUAGE=${LANGUAGE_CHAIN}
export LC_ALL=${LOCALE}
EOF

# 2) Override in kdeglobals
if [[ -f "${CONFIG_HOME}/kdeglobals" ]]; then
    if grep -q '^\[Translations\]' "${CONFIG_HOME}/kdeglobals"; then
        # vorhandenen Eintrag aktualisieren oder ergänzen
        sed -i '/^\[Translations\]/,/^\[/{/^Language=/d}' "${CONFIG_HOME}/kdeglobals"
        sed -i "/^\[Translations\]/a Language=${TRANSLATION}" "${CONFIG_HOME}/kdeglobals"
    else
        printf "\n[Translations]\nLanguage=%s\n" "${TRANSLATION}" >> "${CONFIG_HOME}/kdeglobals"
    fi
else
    cat > "${CONFIG_HOME}/kdeglobals" <<EOF
[Translations]
Language=${TRANSLATION}
EOF
fi

# 3) System-weite ENV exportieren (greift für Krusader-Prozess)
export LANG="${LOCALE}"
export LANGUAGE="${LANGUAGE_CHAIN}"
export LC_ALL="${LOCALE}"

log "Sprache gesetzt – LANG=${LOCALE}, LANGUAGE=${LANGUAGE_CHAIN}"
exit 0
