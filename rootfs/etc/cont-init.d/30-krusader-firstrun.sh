#!/usr/bin/with-contenv bash
# -----------------------------------------------------------------------------
# 30-krusader-firstrun
# -----------------------------------------------------------------------------
# Runs once per container start, BEFORE KasmVNC/Krusader start. Tasks:
#   1. On first run, copy skeleton configs from /defaults/ to /config/.config/
#      and /config/.local/share/krusader/ if they don't exist yet.
#   2. Apply current KRUSADER_LANG and KRUSADER_THEME from ENV (every start),
#      so users can switch via the Unraid template at any time.
#
# We never overwrite user-modified files – everything is "copy if missing"
# plus targeted in-place edits to a couple of well-known keys for the live
# language/theme switch.
# -----------------------------------------------------------------------------
set -e

CONFIG_HOME="/config/.config"
LOCAL_SHARE="/config/.local/share"
DEFAULTS="/defaults"
LOCK="/config/.krusader-firstrun.done"

mkdir -p "${CONFIG_HOME}" "${LOCAL_SHARE}/krusader"

log() { echo "[krusader-firstrun] $*"; }

copy_if_missing() {
    local src="$1" dst="$2"
    if [[ ! -e "${dst}" ]]; then
        cp -a "${src}" "${dst}"
        log "Default angelegt / default created: ${dst}"
    else
        log "Vorhandene Config beibehalten / keeping existing: ${dst}"
    fi
}

# -- 1) First-Run-Setup -------------------------------------------------------
if [[ ! -f "${LOCK}" ]]; then
    log "First-run – seeding default configs..."
    copy_if_missing "${DEFAULTS}/kdeglobals"      "${CONFIG_HOME}/kdeglobals"
    copy_if_missing "${DEFAULTS}/krusaderrc"      "${CONFIG_HOME}/krusaderrc"
    copy_if_missing "${DEFAULTS}/katerc"          "${CONFIG_HOME}/katerc"
    copy_if_missing "${DEFAULTS}/useractions.xml" "${LOCAL_SHARE}/krusader/useractions.xml"
    touch "${LOCK}"
    log "First-run seeding done."
fi

# -- 2) Apply language (idempotent, every boot) -------------------------------
/usr/local/bin/krusader-language.sh "${KRUSADER_LANG:-de}" || log "language hook failed (non-fatal)"

# -- 3) Apply theme -----------------------------------------------------------
case "${KRUSADER_THEME:-dark}" in
    dark)
        if [[ -f "${CONFIG_HOME}/kdeglobals" ]]; then
            sed -i 's/^ColorScheme=.*/ColorScheme=BreezeDark/'                                "${CONFIG_HOME}/kdeglobals" || true
            sed -i 's/^Name=.*/Name=Breeze Dark/'                                             "${CONFIG_HOME}/kdeglobals" || true
            sed -i 's/^LookAndFeelPackage=.*/LookAndFeelPackage=org.kde.breezedark.desktop/'  "${CONFIG_HOME}/kdeglobals" || true
        fi
        ;;
    light)
        if [[ -f "${CONFIG_HOME}/kdeglobals" ]]; then
            sed -i 's/^ColorScheme=.*/ColorScheme=BreezeLight/'                               "${CONFIG_HOME}/kdeglobals" || true
            sed -i 's/^Name=.*/Name=Breeze Light/'                                            "${CONFIG_HOME}/kdeglobals" || true
            sed -i 's/^LookAndFeelPackage=.*/LookAndFeelPackage=org.kde.breeze.desktop/'      "${CONFIG_HOME}/kdeglobals" || true
        fi
        ;;
    *)
        log "Unknown KRUSADER_THEME='${KRUSADER_THEME}', leaving as-is."
        ;;
esac

# -- 4) Permissions -----------------------------------------------------------
# /config gehört üblicherweise dem abby-User (UID/GID via PUID/PGID gemappt).
# Das Baseimage erledigt das später noch einmal – wir setzen hier nur unsere
# Default-Files konsistent.
chown -R abc:abc /config 2>/dev/null || true

log "Setup hook complete – proceeding with KasmVNC/Krusader startup."
exit 0
