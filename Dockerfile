# syntax=docker/dockerfile:1.25
#
# Krusader for Unraid – community edition (Selkies)
# --------------------------------------------------
# Built on the LinuxServer Selkies base image (successor of their EOL KasmVNC
# packaging): X11 + openbox as before, streamed via a hybrid VNC/H.264 pipeline
# with a modern web client. Far smoother than the legacy noVNC stacks.
#
# Features added on top of the base image:
#   * Krusader (twin-pane file manager)
#   * Kate (KDE editor) – also wired up as Krusader's default editor
#   * Full archive support including RAR (unrar), 7z, ARJ, ACE, LHA …
#   * Pre-configured Dark Mode theme (Krusader, Kate, KDE)
#   * Right-click "Extract RAR here", "Open with Kate", "Open Konsole here"
#   * Selectable UI language via KRUSADER_LANG (de, en, fr, es, it, …)
#   * KDE i18n language packs for every selectable language
#
# Repository:  https://github.com/junkerderprovinz/krusader
# License:     MIT (this wrapper)  –  Krusader upstream is GPL-3.0
#
# ubunturesolute (26.04) statt noble: liefert Krusader 2.9.0 (KF6), das den
# Statusbar-Persistenz-Bug aus Issue #16 doppelt fixt (Zustand wird ~1 s nach
# dem Umschalten via KXmlGui-AutoSave gespeichert; zusaetzlich speichert der
# SIGTERM-Handler seit 2.9.0 die Session bei docker stop). noble = 2.8.1 = Bug.
ARG BASE_TAG=ubunturesolute

# Flavor tag deliberately pinned (never :latest) — the Selkies base makes
# breaking changes between versions by design; bump BASE_TAG consciously.
FROM ghcr.io/linuxserver/baseimage-selkies:${BASE_TAG}

LABEL maintainer="junkerderprovinz"
LABEL org.opencontainers.image.title="krusader"
LABEL org.opencontainers.image.description="Krusader für Unraid mit Selkies-Web-Desktop, Dark Mode, Kate-Editor, RAR-Support und Multi-Language-UI"
LABEL org.opencontainers.image.source="https://github.com/junkerderprovinz/krusader"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.vendor="junkerderprovinz"

# TITLE feeds the PWA manifest; SELKIES_UI_TITLE is the visible tab/sidebar
# title of the Selkies web client — both must be set on this base.
#
# SELKIES_ENABLE_BASIC_AUTH=false: Selkies' server enables basic auth by DEFAULT
# with the well-known default credentials (ubuntu / mypasswd), which would pop a
# login on a container that never set a password — worse, an insecure default
# one. The KasmVNC base required no login unless CUSTOM_USER/PASSWORD were set,
# so we keep that: no login by default. The base's nginx would still turn a
# merely-SET (even empty) PASSWORD into a login, so the init-nologin oneshot
# drops an empty PASSWORD/CUSTOM_USER before nginx starts. Selkies binds to
# localhost only, so when a user DOES set a real CUSTOM_USER/PASSWORD the base's
# nginx enforces HTTP-basic-auth on the proxy (the single reachable entry
# point), exactly as before.
ENV TITLE="Krusader" \
    SELKIES_UI_TITLE="Krusader" \
    SELKIES_ENABLE_BASIC_AUTH="false"

# ---------------------------------------------------------------------------
# Pakete installieren
# ---------------------------------------------------------------------------
# Krusader + Kate + Theme + Archive-Tools + i18n-Pakete für alle wichtigen
# Sprachen, die wir später im Unraid-Template als Dropdown anbieten.
#
# Hinweis:
#   * `unrar` lebt im "multiverse" Repo (Ubuntu) bzw. "non-free" (Debian).
#     Das Baseimage basiert auf Ubuntu Noble (24.04) – multiverse muss
#     aktiviert werden.
#   * KDE-i18n: in Ubuntu paketiert als `kde-l10n-<code>` (Legacy)
#     bzw. heutzutage als individuelle Pakete:
#       - `language-pack-kde-<code>`     für KDE-Übersetzungen
#       - `language-pack-<code>`         für allgemeine Locale-Daten
#     Wir installieren beide Schichten.
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# Phase 1: Pflichtpakete (Build bricht ab, wenn etwas fehlt)
# ---------------------------------------------------------------------------
RUN set -eux; \
    # multiverse + universe + restricted aktivieren
    sed -i '/^Components:/ s/$/ multiverse universe restricted/' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || true; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        # File-Manager + Editor
        krusader kate konsole ark krename \
        # Theme / Icons
        breeze breeze-icon-theme kde-style-breeze \
        # Archiv-Tools (wichtig für Krusader)
        # p7zip-rar existiert ab resolute nicht mehr — der RAR-Codec fuers
        # neue 7zip heisst dort 7zip-rar (p7zip-full bleibt als Uebergangspaket).
        unrar p7zip-full 7zip-rar \
        zip unzip bzip2 lzma xz-utils \
        lhasa arj unace rpm cpio \
        # KDE/Qt Runtime essentials
        dbus-x11 kde-cli-tools kdialog keditbookmarks \
        # Sonnet-Hunspell-Plugin: macht KDE-Apps (Kate, KMail, ...) die
        # Hunspell-Woerterbuecher als Spell-Backend zugaenglich. Ohne dieses
        # Plugin meckert Sonnet "No speller backends available!".
        sonnet-plugins \
        # Qt-Theme-Bridge fuer KDE-Apps:
        # plasma-integration liefert das offizielle 'kde' Qt-Platformtheme-
        # Plugin (libkdeplatformtheme.so). Damit liest Krusader/Kate die
        # KDE-Color-Schemes (DarkMode.colors) NATIV — qt5ct kann diese
        # KDE-Files nicht parsen (Format-Mismatch) und liefert eine leere
        # weisse Default-Palette zurueck. Genau dieser Fehler hat zuvor
        # zur hellen UI mit Linien-Optik gefuehrt.
        plasma-integration kde-config-gtk-style \
        # KDE Session Manager — ksmserver persistiert Fenstergeometrie und
        # UI-Zustand (Bugs #1/#2). Ist Teil von plasma-workspace (~150 MB).
        # ksmserver registriert sich als org.kde.ksmserver auf dem D-Bus und
        # sendet saveYourself an alle KMainWindow-Apps beim Beenden.
        plasma-workspace \
        # qt5ct/qt6ct trotzdem als Fallback fuer Nicht-KDE-Qt-Apps
        qt5ct qt6ct \
        # Hunspell + Fonts (ohne Sprach-Wörterbücher – die kommen in Phase 2)
        hunspell \
        # WICHTIG: fontconfig + Standard-Fonts. Ohne fontconfig + fc-cache
        # rendern Qt/KDE-Apps Text als leere Striche (Glyphen-Lookup
        # schlägt fehl). Plus fonts-dejavu/liberation als robuste Defaults
        # für UI-Render, fonts-hack als Monospace-Fallback.
        fontconfig \
        fonts-noto fonts-noto-cjk fonts-noto-color-emoji \
        fonts-dejavu fonts-dejavu-core fonts-dejavu-extra \
        fonts-liberation fonts-liberation2 \
        fonts-hack fonts-freefont-ttf \
        # Locale-Werkzeuge
        locales coreutils sed; \
    # arj-Symlink (manche Tools erwarten "unarj")
    [ -e /usr/bin/unarj ] || ln -s /usr/bin/arj /usr/bin/unarj; \
    # Font-Cache JETZT aufbauen, damit Qt/KDE die Fonts beim ersten
    # Container-Start sofort findet. Sonst rendert Krusader die Texte
    # als leere Linien.
    fc-cache -f -v >/dev/null 2>&1 || true; \
    # apt-Listen nicht in den Layer backen — Phase 2 macht ihr eigenes
    # apt-get update (frische Listen statt stale Layer-Cache).
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Phase 2: Optionale i18n + Hunspell-Pakete (Build läuft weiter, wenn ein
# einzelnes Paket nicht existiert / umbenannt wurde – z.B. Finnisch nutzt
# voikko statt hunspell, manche Sprachen haben keine KDE-Translation).
# ---------------------------------------------------------------------------
# Wir filtern die Wunschliste mit `apt-cache search` und installieren nur
# das, was tatsächlich existiert. So sind wir robust gegen Renamings in
# zukünftigen Ubuntu-Releases.
# ---------------------------------------------------------------------------
# Trick: locale-gen per dpkg-trigger ausschalten, sonst ruft jedes der
# folgenden language-pack-* Pakete locale-gen ueber ALLE bisher aktivierten
# Locales auf (quadratische Explosion → 50min+ Build-Zeit). Wir generieren
# die Locales spaeter EINMAL gezielt.
RUN set -eux; \
    # locale-gen-Hook neutralisieren
    if [ -x /usr/sbin/locale-gen ]; then \
        mv /usr/sbin/locale-gen /usr/sbin/locale-gen.real; \
        printf '#!/bin/sh\nexit 0\n' > /usr/sbin/locale-gen; \
        chmod +x /usr/sbin/locale-gen; \
    fi

RUN set -eux; \
    # Eigenes apt-get update: Phase 1 raeumt seine Listen weg, und mit dem
    # gha-Layer-Cache waeren mitgeschleppte Listen ohnehin veraltet (stale).
    apt-get update; \
    WANT=" \
        hunspell-de-de hunspell-en-us hunspell-en-gb \
        hunspell-fr hunspell-es hunspell-it \
        hunspell-pt-pt hunspell-pt-br \
        hunspell-nl hunspell-da hunspell-sv hunspell-no \
        hunspell-pl hunspell-cs hunspell-sk hunspell-hu \
        hunspell-ro hunspell-hr hunspell-bg \
        hunspell-uk hunspell-ru \
        hunspell-tr hunspell-he hunspell-ar \
        language-pack-de language-pack-kde-de \
        language-pack-en language-pack-kde-en \
        language-pack-fr language-pack-kde-fr \
        language-pack-es language-pack-kde-es \
        language-pack-it language-pack-kde-it \
        language-pack-pt language-pack-kde-pt \
        language-pack-nl language-pack-kde-nl \
        language-pack-da language-pack-kde-da \
        language-pack-sv language-pack-kde-sv \
        language-pack-nb language-pack-kde-nb \
        language-pack-fi language-pack-kde-fi \
        language-pack-is language-pack-kde-is \
        language-pack-ga language-pack-kde-ga \
        language-pack-ca language-pack-kde-ca \
        language-pack-eu language-pack-kde-eu \
        language-pack-pl language-pack-kde-pl \
        language-pack-cs language-pack-kde-cs \
        language-pack-sk language-pack-kde-sk \
        language-pack-hu language-pack-kde-hu \
        language-pack-ro language-pack-kde-ro \
        language-pack-sl language-pack-kde-sl \
        language-pack-hr language-pack-kde-hr \
        language-pack-sr language-pack-kde-sr \
        language-pack-bg language-pack-kde-bg \
        language-pack-uk language-pack-kde-uk \
        language-pack-ru language-pack-kde-ru \
        language-pack-el language-pack-kde-el \
        language-pack-tr language-pack-kde-tr \
        language-pack-he language-pack-kde-he \
        language-pack-ar language-pack-kde-ar \
        language-pack-ja language-pack-kde-ja \
        language-pack-ko language-pack-kde-ko \
        language-pack-zh-hans language-pack-kde-zh-hans \
        language-pack-zh-hant language-pack-kde-zh-hant \
    "; \
    AVAIL=""; \
    for P in $WANT; do \
        if apt-cache show "$P" >/dev/null 2>&1; then \
            AVAIL="$AVAIL $P"; \
        else \
            echo "[i18n] skipping unavailable package: $P"; \
        fi; \
    done; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $AVAIL; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ---------------------------------------------------------------------------
# Locales generieren (EINMAL, gezielt fuer unsere 35 Locales)
# ---------------------------------------------------------------------------
RUN set -eux; \
    # locale-gen-Hook reaktivieren
    if [ -f /usr/sbin/locale-gen.real ]; then \
        mv -f /usr/sbin/locale-gen.real /usr/sbin/locale-gen; \
    fi; \
    # Ubuntus language-pack-* Pakete registrieren unter
    # /var/lib/locales/supported.d/ ALLE Regionalvarianten (de_AT, de_CH,
    # de_LI, ...), und locale-gen liest diese Dateien ZUSAETZLICH zu
    # /etc/locale.gen. Leeren, damit wirklich nur die kuratierte Liste
    # unten generiert wird — eine Locale pro Sprache haelt das Image schlank.
    rm -f /var/lib/locales/supported.d/*; \
    # /etc/locale.gen frisch schreiben — nur unsere gewuenschten Locales
    : > /etc/locale.gen; \
    for L in \
        de_DE en_US en_GB fr_FR es_ES it_IT pt_PT pt_BR \
        nl_NL da_DK sv_SE nb_NO fi_FI is_IS ga_IE ca_ES eu_ES \
        pl_PL cs_CZ sk_SK hu_HU ro_RO sl_SI hr_HR sr_RS bg_BG \
        uk_UA ru_RU el_GR tr_TR he_IL ar_SA \
        ja_JP ko_KR zh_CN zh_TW; do \
      echo "${L}.UTF-8 UTF-8" >> /etc/locale.gen; \
    done; \
    locale-gen

# ---------------------------------------------------------------------------
# Skeleton-Configs + s6-overlay init scripts
# ---------------------------------------------------------------------------
# Das LinuxServer-Baseimage benutzt s6-overlay v3. Init-Scripts liegen unter
# /etc/s6-overlay/s6-rc.d/ und werden vor den Services ausgeführt.
COPY rootfs/ /

# Init-Log-Banner: single source at .github/assets/banner-raw.txt (CR stripped
# so the figlet renders cleanly regardless of the editor's line endings).
COPY .github/assets/banner-raw.txt /usr/local/share/banner-raw.txt
# Strip CR so figlet renders cleanly, AND empty the LinuxServer base's OWN brand
# banner (init-adduser/branding) so the log shows only our print-banner.sh banner
# instead of a messy double banner (this is why the init banner looked "incomplete").
RUN tr -d '\r' < /usr/local/share/banner-raw.txt > /usr/local/share/banner.txt \
    && : > /etc/s6-overlay/s6-rc.d/init-adduser/branding

# ---------------------------------------------------------------------------
# Browser-tab favicon / branding (issue #12, radically simpler on Selkies)
# ---------------------------------------------------------------------------
# Selkies has ONE branding path: /usr/share/selkies/www/icon.png. The base's
# init-nginx copies it on every container start to web/favicon.ico, web/icon.png
# and references it from the generated manifest.json — no more multi-path
# kclient surgery. The build fails loudly if the path is gone (base layout
# changed), so CI / the weekly rebuild surfaces the regression.
COPY .github/assets/icon.png /usr/local/share/krusader-icon.png
RUN set -eux; \
    dst=/usr/share/selkies/www/icon.png; \
    [ -f "$dst" ] || { echo "ERROR: $dst missing — selkies base layout changed, update the branding override"; exit 1; }; \
    cp /usr/local/share/krusader-icon.png "$dst"; \
    echo "krusader: branded selkies icon at $dst"

# ---------------------------------------------------------------------------
# MediaButton icon = the SAME icon the panel shows for a directory
# ---------------------------------------------------------------------------
# Krusader's status-bar "show available devices" button (MediaButton) uses the
# "system-file-manager" icon. The file panel renders a directory from its
# mimetype: inode/directory -> icon name "inode-directory", which Breeze ships
# as a symlink to places/<size>/folder.svg. We stamp that exact art (symlink
# dereferenced with cp -L) onto system-file-manager SIZE-FOR-SIZE, so the button
# is byte-identical to the folder icon in the file list at every size — instead
# of the old approach that copied one arbitrary file onto all sizes. Done in
# both breeze-dark and its parent breeze, because KIconLoader falls back to the
# parent for any size breeze-dark does not itself ship (otherwise the
# un-overridden parent icon would win and the button would look unchanged).
RUN set -eux; \
    n=0; \
    for theme in /usr/share/icons/breeze-dark /usr/share/icons/breeze; do \
        [ -d "$theme" ] || continue; \
        for appdir in "$theme"/apps/*/; do \
            [ -e "${appdir}system-file-manager.svg" ] || continue; \
            sz="$(basename "$appdir")"; \
            src="$theme/mimetypes/$sz/inode-directory.svg"; \
            [ -e "$src" ] || src="$theme/places/$sz/folder.svg"; \
            [ -e "$src" ] || continue; \
            cp -L "$src" "${appdir}system-file-manager.svg"; \
            n=$((n + 1)); \
        done; \
        gtk-update-icon-cache -f -t "$theme" 2>/dev/null || true; \
    done; \
    [ "$n" -gt 0 ] || { echo "ERROR: no apps/*/system-file-manager.svg overridden — breeze layout changed"; exit 1; }; \
    echo "krusader: MediaButton icon matched to the panel folder icon ($n file(s))"

# Berechtigungen für init-scripts
RUN chmod +x /usr/local/bin/krusader-*.sh \
             /usr/local/bin/krusader-session \
             /usr/local/bin/print-banner.sh \
             /etc/s6-overlay/s6-rc.d/init-krusader/run \
             /etc/s6-overlay/s6-rc.d/init-nologin/run \
             /etc/s6-overlay/s6-rc.d/svc-krusader-ready/run \
             /defaults/autostart \
             /defaults/startwm.sh

# ---------------------------------------------------------------------------
# Standard-ENV (durch Unraid-Template überschreibbar)
# ---------------------------------------------------------------------------
# KRUSADER_LANG  – UI-Sprache: ISO-Code (de, en, fr, …) oder "system"
# KRUSADER_THEME – dark | light
# CUSTOM_PORT    – HTTP-Port  (Selkies-Standard 3000)
# CUSTOM_HTTPS_PORT – HTTPS-Port (Selkies-Standard 3001)
# Locale: keep the boot env LANGUAGE-NEUTRAL (C.UTF-8) and let KRUSADER_LANG drive
# the UI language via krusader-language.sh (kdeglobals [Translations] + a matching
# LANG/LANGUAGE pushed into the s6 env). We must NOT hardcode a German LANG/
# LANGUAGE/LC_ALL here: the Selkies base's init-selkies-config derives
# LANGUAGE=${LC_ALL%.UTF-8} + LANG=${LC_ALL} into the container env whenever LC_ALL
# is set, and KDE gives that LANGUAGE env priority over kdeglobals [Translations].
# With a German LC_ALL baked in, a user who set KRUSADER_LANG=en still got a German
# UI (issue #21), because the base's German LANGUAGE env overrode the correct
# kdeglobals we write. C.UTF-8 leaves no language in the env, so kdeglobals wins.
ENV KRUSADER_LANG=de \
    KRUSADER_THEME=dark \
    LANG=C.UTF-8 \
    QT_QPA_PLATFORMTHEME=qt5ct \
    QT_STYLE_OVERRIDE=Breeze

# Ports werden vom Baseimage freigegeben (3000/HTTP, 3001/HTTPS).
# Der Entrypoint kommt vom Baseimage – Selkies wird automatisch gestartet
# und führt /defaults/autostart aus (siehe rootfs/defaults/autostart).

# ---------------------------------------------------------------------------
# Healthcheck: WebUI (Selkies/nginx) antwortet auf dem HTTPS-Port.
# curl kommt aus dem Baseimage (baseimage-ubuntu installiert es im Runtime-
# Layer). Jeder HTTP-Statuscode zaehlt als "up" — nur "000" (keine Antwort /
# Verbindung verweigert) markiert den Container als unhealthy.
# ---------------------------------------------------------------------------
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD c=$(curl -ks -o /dev/null -w '%{http_code}' --max-time 5 https://127.0.0.1:${CUSTOM_HTTPS_PORT:-3001}/); [ "$c" != "000" ] || exit 1
