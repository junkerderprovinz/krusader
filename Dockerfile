# syntax=docker/dockerfile:1.6
#
# Krusader for Unraid – community edition (KasmVNC)
# -------------------------------------------------
# Built on the LinuxServer KasmVNC base image, which provides a modern,
# hardware-accelerated, web-native Linux desktop. Far smoother and more
# responsive than the legacy noVNC stack used by jlesage / binhex / ich777.
#
# Features added on top of the base image:
#   * Krusader (twin-pane file manager)
#   * Kate (KDE editor) – also wired up as Krusader's default editor
#   * Full archive support including RAR (unrar), 7z, ARJ, ACE, LHA …
#   * Pre-configured Breeze Dark theme (Krusader, Kate, KDE)
#   * Right-click "Extract RAR here", "Open with Kate", "Open Konsole here"
#   * Selectable UI language via KRUSADER_LANG (de, en, fr, es, it, …)
#   * KDE i18n language packs for every selectable language
#
# Repository:  https://github.com/junkerderprovinz/krusader
# License:     MIT (this wrapper)  –  Krusader upstream is GPL-3.0
#
ARG BASE_TAG=ubuntunoble

FROM ghcr.io/linuxserver/baseimage-kasmvnc:${BASE_TAG}

LABEL maintainer="junkerderprovinz"
LABEL org.opencontainers.image.title="krusader"
LABEL org.opencontainers.image.description="Krusader für Unraid mit KasmVNC, Dark Mode, Kate-Editor, RAR-Support und Multi-Language-UI"
LABEL org.opencontainers.image.source="https://github.com/junkerderprovinz/krusader"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.vendor="junkerderprovinz"

# Title shown in browser tab / KasmVNC top bar
ENV TITLE="Krusader"

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
        krusader kate konsole ark \
        # Theme / Icons
        breeze breeze-icon-theme kde-style-breeze \
        # Archiv-Tools (wichtig für Krusader)
        unrar p7zip-full p7zip-rar \
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
        # KDE-Color-Schemes (BreezeDark.colors) NATIV — qt5ct kann diese
        # KDE-Files nicht parsen (Format-Mismatch) und liefert eine leere
        # weisse Default-Palette zurueck. Genau dieser Fehler hat zuvor
        # zur hellen UI mit Linien-Optik gefuehrt.
        plasma-integration kde-config-gtk-style \
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
    fc-cache -f -v >/dev/null 2>&1 || true

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
# Das LinuxServer-Baseimage benutzt s6-overlay v3. Init-Scripts unter
# /etc/cont-init.d/ werden in alphabetischer Reihenfolge VOR den Services
# ausgeführt – ideal für unser First-Run-Setup.
COPY rootfs/ /

# Berechtigungen für init-scripts
RUN chmod +x /usr/local/bin/krusader-*.sh \
             /etc/s6-overlay/s6-rc.d/init-krusader/run \
             /defaults/autostart

# ---------------------------------------------------------------------------
# Standard-ENV (durch Unraid-Template überschreibbar)
# ---------------------------------------------------------------------------
# KRUSADER_LANG  – UI-Sprache: ISO-Code (de, en, fr, …) oder "system"
# KRUSADER_THEME – dark | light
# CUSTOM_PORT    – HTTP-Port  (KasmVNC-Standard 3000)
# CUSTOM_HTTPS_PORT – HTTPS-Port (KasmVNC-Standard 3001)
ENV KRUSADER_LANG=de \
    KRUSADER_THEME=dark \
    LANG=de_DE.UTF-8 \
    LANGUAGE=de_DE:de:en \
    LC_ALL=de_DE.UTF-8 \
    QT_QPA_PLATFORMTHEME=qt5ct \
    QT_STYLE_OVERRIDE=Breeze

# Ports werden vom Baseimage freigegeben (3000/HTTP, 3001/HTTPS).
# Der Entrypoint kommt vom Baseimage – KasmVNC wird automatisch gestartet
# und führt /defaults/autostart aus (siehe rootfs/defaults/autostart).
