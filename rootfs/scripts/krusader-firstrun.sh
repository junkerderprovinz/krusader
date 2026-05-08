#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# krusader-firstrun.sh
# -----------------------------------------------------------------------------
# Wird bei jedem Container-Start (vor `dbus-run-session -- krusader`) ausgeführt.
# Aufgaben:
#   1. Beim ALLERSTEN Start: Skeleton-Configs aus /defaults nach /config/home
#      kopieren (Dark Mode, krusaderrc, katerc, useractions.xml).
#   2. Bei jedem Start: Sprache (KRUSADER_LANG) und Theme (KRUSADER_THEME)
#      gemäß ENV anwenden – damit kann der User die Sprache jederzeit
#      über die Unraid-Template-Variable umschalten.
# -----------------------------------------------------------------------------
set -e

CONFIG_HOME="/config/home/.config"
LOCAL_SHARE="/config/home/.local/share"
DEFAULTS="/defaults"
LOCK="/config/home/.krusader-unraid.firstrun.done"

mkdir -p "${CONFIG_HOME}" "${LOCAL_SHARE}/krusader"

log() { echo "[krusader-unraid] $*"; }

# -- 1) First-Run-Setup -------------------------------------------------------
copy_if_missing() {
    local src="$1" dst="$2"
    if [[ ! -e "${dst}" ]]; then
        cp -a "${src}" "${dst}"
        log "Default angelegt: ${dst}"
    else
        log "Vorhandene Config beibehalten: ${dst}"
    fi
}

if [[ ! -f "${LOCK}" ]]; then
    log "First-Run erkannt – lege Default-Configs an…"
    copy_if_missing "${DEFAULTS}/kdeglobals"      "${CONFIG_HOME}/kdeglobals"
    copy_if_missing "${DEFAULTS}/krusaderrc"      "${CONFIG_HOME}/krusaderrc"
    copy_if_missing "${DEFAULTS}/katerc"          "${CONFIG_HOME}/katerc"
    copy_if_missing "${DEFAULTS}/useractions.xml" "${LOCAL_SHARE}/krusader/useractions.xml"
    touch "${LOCK}"
    log "First-Run-Setup abgeschlossen."
else
    log "First-Run bereits erfolgt – überspringe Default-Kopie."
fi

# -- 2) Sprache anwenden (idempotent, bei jedem Start) ------------------------
/usr/local/bin/krusader-language.sh "${KRUSADER_LANG:-de}" || true

# -- 3) Theme nochmal absichern -----------------------------------------------
case "${KRUSADER_THEME:-dark}" in
    dark)
        if [[ -f "${CONFIG_HOME}/kdeglobals" ]]; then
            sed -i 's/^ColorScheme=.*/ColorScheme=BreezeDark/'   "${CONFIG_HOME}/kdeglobals" || true
            sed -i 's/^Name=.*/Name=Breeze Dark/'                "${CONFIG_HOME}/kdeglobals" || true
            sed -i 's/^LookAndFeelPackage=.*/LookAndFeelPackage=org.kde.breezedark.desktop/' "${CONFIG_HOME}/kdeglobals" || true
        fi
        ;;
    light)
        if [[ -f "${CONFIG_HOME}/kdeglobals" ]]; then
            sed -i 's/^ColorScheme=.*/ColorScheme=BreezeLight/'  "${CONFIG_HOME}/kdeglobals" || true
            sed -i 's/^Name=.*/Name=Breeze Light/'               "${CONFIG_HOME}/kdeglobals" || true
            sed -i 's/^LookAndFeelPackage=.*/LookAndFeelPackage=org.kde.breeze.desktop/'      "${CONFIG_HOME}/kdeglobals" || true
        fi
        ;;
    *)
        log "Unbekanntes KRUSADER_THEME='${KRUSADER_THEME}', kein Wechsel."
        ;;
esac

# Permissions korrigieren – binhex-Init setzt diese später nochmal,
# aber so ist der erste Start sauber.
chown -R "${PUID:-99}:${PGID:-100}" /config/home 2>/dev/null || true

log "Setup-Hook fertig, starte Krusader…"
exit 0
