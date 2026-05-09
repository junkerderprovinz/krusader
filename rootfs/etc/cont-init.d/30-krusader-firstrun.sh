#!/usr/bin/with-contenv bash
# -----------------------------------------------------------------------------
# 30-krusader-firstrun
# -----------------------------------------------------------------------------
# Laeuft VOR KasmVNC/Krusader-Start. Drei klar getrennte Phasen:
#
#   A) USER-GESCHUETZT (nur First-Run, "copy if missing"):
#      Konfigurationen, die der User editieren koennen muss
#      -> krusaderrc, katerc, useractions.xml
#
#   B) IMMER FRISCH (jeder Start, "copy & overwrite"):
#      Theme-Infrastruktur, die wir komplett kontrollieren wollen
#      -> kdeglobals, color-schemes/*, qt5ct/qt6ct, autostart
#      Wenn der User selbst Theme-Tweaks macht, ueberlebt das via
#      eigene Files in ~/.config/krusaderrc[Colors] oder eigenen
#      qt5ct-Override-Files.
#
#   C) ENV-DRIVEN APPLY (jeder Start):
#      KRUSADER_LANG / KRUSADER_THEME aus dem Unraid-Template anwenden.
# -----------------------------------------------------------------------------
set -e

CONFIG_HOME="/config/.config"
LOCAL_SHARE="/config/.local/share"
KDEDEFAULTS="/config/.config/kdedefaults"
COLOR_SCHEMES="/config/.local/share/color-schemes"
DEFAULTS="/defaults"
LOCK="/config/.krusader-firstrun.done"

mkdir -p "${CONFIG_HOME}" \
         "${LOCAL_SHARE}/krusader" \
         "${KDEDEFAULTS}" \
         "${COLOR_SCHEMES}" \
         "${CONFIG_HOME}/qt5ct" \
         "${CONFIG_HOME}/qt6ct"

log() { echo "[krusader-firstrun] $*"; }

copy_if_missing() {
    local src="$1" dst="$2"
    if [[ ! -e "${dst}" ]]; then
        cp -a "${src}" "${dst}"
        log "Default angelegt: ${dst}"
    fi
}

copy_force() {
    local src="$1" dst="$2"
    if [[ -e "${src}" ]]; then
        cp -af "${src}" "${dst}"
        log "Theme-File aktualisiert: ${dst}"
    fi
}

# -- A) User-geschuetzt: nur beim allerersten Start ---------------------------
if [[ ! -f "${LOCK}" ]]; then
    log "First-run – seeding user-editable defaults..."
    copy_if_missing "${DEFAULTS}/krusaderrc"      "${CONFIG_HOME}/krusaderrc"
    copy_if_missing "${DEFAULTS}/katerc"          "${CONFIG_HOME}/katerc"
    copy_if_missing "${DEFAULTS}/useractions.xml" "${LOCAL_SHARE}/krusader/useractions.xml"
    touch "${LOCK}"
    log "First-run seeding done."
fi

# -- B) Theme-Infrastruktur: JEDER Start, immer frisch ------------------------
# Diese Files sind die Lifeline fuer Dark-Mode. Wenn wir sie nicht ueber-
# schreiben, klebt der User auf dem ersten kaputten Stand. User-Anpassungen
# am Theme gehen ueber den Unraid-Template-Switch KRUSADER_THEME, nicht
# ueber Direkt-Edits an diesen Files.
log "Theme-Infrastruktur (re)deploy..."
copy_force "${DEFAULTS}/kdeglobals" "${CONFIG_HOME}/kdeglobals"
copy_force "${DEFAULTS}/kdeglobals" "${KDEDEFAULTS}/kdeglobals"

if [[ -f "${DEFAULTS}/color-schemes/BreezeDark.colors" ]]; then
    copy_force "${DEFAULTS}/color-schemes/BreezeDark.colors" \
               "${COLOR_SCHEMES}/BreezeDark.colors"
fi

if [[ -f "${DEFAULTS}/qt5ct.conf" ]]; then
    copy_force "${DEFAULTS}/qt5ct.conf" "${CONFIG_HOME}/qt5ct/qt5ct.conf"
    copy_force "${DEFAULTS}/qt5ct.conf" "${CONFIG_HOME}/qt6ct/qt6ct.conf"
fi

# /etc/profile.d-Snippet als zusaetzliche Sicherheitsleine fuer alle
# Login-Shells (Konsole im Krusader, SSH, ...). Der primaere Mechanismus
# bleibt aber /defaults/autostart, das die ENV direkt setzt.
cat > /etc/profile.d/zz-krusader-theme.sh <<'EOF'
# Auto-generated – Krusader Dark-Mode Hardening
export QT_STYLE_OVERRIDE=Breeze
export QT_QPA_PLATFORMTHEME=qt5ct
export KDE_COLOR_SCHEME_PATH="$HOME/.local/share/color-schemes/BreezeDark.colors"
export GTK_THEME=Breeze-Dark
EOF
chmod 0644 /etc/profile.d/zz-krusader-theme.sh

# -- C) Env-driven Apply ------------------------------------------------------

# Sprache (idempotent)
/usr/local/bin/krusader-language.sh "${KRUSADER_LANG:-de}" || log "language hook failed (non-fatal)"

# Theme-Switch dark/light – ueberschreibt die kdeglobals-Werte gezielt.
case "${KRUSADER_THEME:-dark}" in
    dark)
        sed -i 's/^ColorScheme=.*/ColorScheme=BreezeDark/'                                "${CONFIG_HOME}/kdeglobals" || true
        sed -i 's/^Name=.*/Name=Breeze Dark/'                                             "${CONFIG_HOME}/kdeglobals" || true
        sed -i 's/^LookAndFeelPackage=.*/LookAndFeelPackage=org.kde.breezedark.desktop/'  "${CONFIG_HOME}/kdeglobals" || true
        # auch in krusaderrc[Colors]
        sed -i 's/^ColorScheme=.*/ColorScheme=BreezeDark/' "${CONFIG_HOME}/krusaderrc" || true
        # qt5ct ColorScheme-Pfad erzwingen
        sed -i "s|^color_scheme_path=.*|color_scheme_path=/config/.local/share/color-schemes/BreezeDark.colors|" "${CONFIG_HOME}/qt5ct/qt5ct.conf" 2>/dev/null || true
        sed -i "s|^color_scheme_path=.*|color_scheme_path=/config/.local/share/color-schemes/BreezeDark.colors|" "${CONFIG_HOME}/qt6ct/qt6ct.conf" 2>/dev/null || true
        log "Theme: dark angewendet."
        ;;
    light)
        sed -i 's/^ColorScheme=.*/ColorScheme=BreezeLight/'                               "${CONFIG_HOME}/kdeglobals" || true
        sed -i 's/^Name=.*/Name=Breeze Light/'                                            "${CONFIG_HOME}/kdeglobals" || true
        sed -i 's/^LookAndFeelPackage=.*/LookAndFeelPackage=org.kde.breeze.desktop/'      "${CONFIG_HOME}/kdeglobals" || true
        sed -i 's/^ColorScheme=.*/ColorScheme=BreezeLight/' "${CONFIG_HOME}/krusaderrc" || true
        sed -i "s|^color_scheme_path=.*|color_scheme_path=/usr/share/color-schemes/BreezeLight.colors|" "${CONFIG_HOME}/qt5ct/qt5ct.conf" 2>/dev/null || true
        sed -i "s|^color_scheme_path=.*|color_scheme_path=/usr/share/color-schemes/BreezeLight.colors|" "${CONFIG_HOME}/qt6ct/qt6ct.conf" 2>/dev/null || true
        log "Theme: light angewendet."
        ;;
    *)
        log "Unbekanntes KRUSADER_THEME='${KRUSADER_THEME}', kein Switch."
        ;;
esac

# Permissions
chown -R abc:abc /config 2>/dev/null || true

log "Setup-Hook fertig – proceeding with KasmVNC/Krusader startup."
exit 0
