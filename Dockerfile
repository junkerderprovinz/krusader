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
# License:     GPL-3.0
#
ARG BASE_TAG=ubuntunoble

FROM ghcr.io/linuxserver/baseimage-kasmvnc:${BASE_TAG}

LABEL maintainer="junkerderprovinz"
LABEL org.opencontainers.image.title="krusader"
LABEL org.opencontainers.image.description="Krusader für Unraid mit KasmVNC, Dark Mode, Kate-Editor, RAR-Support und Multi-Language-UI"
LABEL org.opencontainers.image.source="https://github.com/junkerderprovinz/krusader"
LABEL org.opencontainers.image.licenses="GPL-3.0"
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
RUN set -eux; \
    # multiverse aktivieren (für unrar, p7zip-rar)
    sed -i '/^Components:/ s/$/ multiverse universe restricted/' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || true; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        # File-Manager + Editor
        krusader \
        kate \
        konsole \
        ark \
        # Theme / Icons
        breeze \
        breeze-icon-theme \
        kde-style-breeze \
        # Tools, die Krusader für Archiv-Operationen aufruft
        unrar \
        p7zip-full \
        p7zip-rar \
        zip unzip \
        bzip2 lzma xz-utils \
        lhasa arj unace \
        rpm cpio \
        # KDE/Qt Runtime essentials
        dbus-x11 \
        kde-cli-tools \
        kdialog \
        keditbookmarks \
        # Spell-checking für Kate
        hunspell \
        hunspell-de-de \
        hunspell-en-us \
        hunspell-fr \
        hunspell-es \
        hunspell-it \
        # Font-Pakete (CJK + Symbole) – damit Filenamen in jeder Sprache lesbar sind
        fonts-noto \
        fonts-noto-cjk \
        fonts-noto-color-emoji \
        # KDE i18n-Pakete für die im Template angebotenen Sprachen
        language-pack-kde-de \
        language-pack-de \
        language-pack-kde-en \
        language-pack-en \
        language-pack-kde-fr \
        language-pack-fr \
        language-pack-kde-es \
        language-pack-es \
        language-pack-kde-it \
        language-pack-it \
        language-pack-kde-nl \
        language-pack-nl \
        language-pack-kde-pl \
        language-pack-pl \
        language-pack-kde-pt \
        language-pack-pt \
        language-pack-kde-ru \
        language-pack-ru \
        language-pack-kde-ja \
        language-pack-ja \
        language-pack-kde-zh-hans \
        language-pack-zh-hans \
        language-pack-kde-tr \
        language-pack-tr \
        language-pack-kde-cs \
        language-pack-cs \
        # Symlink-Helper
        coreutils \
        sed; \
    # arj wird als Binary "arj" installiert, manche Tools erwarten "unarj"
    [ -e /usr/bin/unarj ] || ln -s /usr/bin/arj /usr/bin/unarj; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ---------------------------------------------------------------------------
# Locales generieren
# ---------------------------------------------------------------------------
RUN set -eux; \
    sed -i \
        -e 's/^# *\(de_DE\.UTF-8\)/\1/' \
        -e 's/^# *\(en_US\.UTF-8\)/\1/' \
        -e 's/^# *\(fr_FR\.UTF-8\)/\1/' \
        -e 's/^# *\(es_ES\.UTF-8\)/\1/' \
        -e 's/^# *\(it_IT\.UTF-8\)/\1/' \
        -e 's/^# *\(nl_NL\.UTF-8\)/\1/' \
        -e 's/^# *\(pl_PL\.UTF-8\)/\1/' \
        -e 's/^# *\(pt_PT\.UTF-8\)/\1/' \
        -e 's/^# *\(ru_RU\.UTF-8\)/\1/' \
        -e 's/^# *\(ja_JP\.UTF-8\)/\1/' \
        -e 's/^# *\(zh_CN\.UTF-8\)/\1/' \
        -e 's/^# *\(tr_TR\.UTF-8\)/\1/' \
        -e 's/^# *\(cs_CZ\.UTF-8\)/\1/' \
        /etc/locale.gen; \
    locale-gen

# ---------------------------------------------------------------------------
# Skeleton-Configs + s6-overlay init scripts
# ---------------------------------------------------------------------------
# Das LinuxServer-Baseimage benutzt s6-overlay v3. Init-Scripts unter
# /etc/cont-init.d/ werden in alphabetischer Reihenfolge VOR den Services
# ausgeführt – ideal für unser First-Run-Setup.
COPY rootfs/ /

# Berechtigungen für init-scripts
RUN chmod +x /etc/cont-init.d/*.sh /usr/local/bin/krusader-*.sh

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
    LC_ALL=de_DE.UTF-8

# Ports werden vom Baseimage freigegeben (3000/HTTP, 3001/HTTPS).
# Der Entrypoint kommt vom Baseimage – KasmVNC wird automatisch gestartet
# und führt /defaults/autostart aus (siehe rootfs/defaults/autostart).
