# syntax=docker/dockerfile:1.6
#
# Krusader for Unraid – community edition
# ----------------------------------------
# Baut auf dem bewährten binhex/arch-krusader Image auf und ergänzt:
#   * Kate als vorkonfigurierter externer Editor
#   * Volle Archiv-Unterstützung inkl. RAR (unrar) und 7z (p7zip)
#   * Vorkonfigurierter Dark-Mode (Breeze Dark) für Krusader, Kate und KDE
#   * Krusader-UserActions u.a. für „Mit unrar entpacken" per Rechtsklick
#   * Locale-Pakete und konfigurierbare UI-Sprache (Default: Deutsch)
#
# Repository:    https://github.com/<dein-github-user>/krusader-unraid
# Lizenz:        GPL-3.0 (folgt der Upstream-Lizenz von binhex/arch-krusader)
#
FROM binhex/arch-krusader:latest

LABEL org.opencontainers.image.title="krusader-unraid"
LABEL org.opencontainers.image.description="Krusader für Unraid mit Dark Mode, Kate-Editor, RAR-Support und deutscher Lokalisierung"
LABEL org.opencontainers.image.source="https://github.com/REPLACE_ME/krusader-unraid"
LABEL org.opencontainers.image.licenses="GPL-3.0"

# ---------------------------------------------------------------------------
# Zusätzliche Pakete installieren
# ---------------------------------------------------------------------------
# - kate, kate-common ............ KDE Editor
# - unrar ........................ RAR entpacken
# - p7zip ........................ 7z / komprimieren
# - ark .......................... Archiv-Manager (optional, schöne GUI)
# - breeze, breeze-gtk ........... Theme-Engine inkl. Dark Variante
# - kde-cli-tools ................ kdialog & co. (für UserActions)
# - hunspell, hunspell-de, hunspell-en_us ... Rechtschreibung in Kate
# - qt5-translations / kf5 i18n .. Übersetzungen für Krusader/Kate
# - xdg-utils .................... xdg-open für „Öffnen mit"
#
# Hinweis: Das binhex-Base-Image bringt pacman bereits in einem konsistenten
# Zustand mit. Wir machen vor der Installation `pacman -Sy`, weil zwischen
# Base-Build und unserem Build Tage liegen können.
RUN set -eux; \
    pacman -Sy --noconfirm; \
    pacman -S --noconfirm --needed \
        kate \
        unrar \
        p7zip \
        ark \
        breeze \
        breeze-gtk \
        breeze-icons \
        kde-cli-tools \
        hunspell \
        hunspell-de \
        hunspell-en_us \
        xdg-utils \
        sed \
        coreutils; \
    # pacman-Cache aufräumen, hält das Image schlank
    pacman -Scc --noconfirm; \
    rm -rf /var/cache/pacman/pkg/* /var/lib/pacman/sync/*

# ---------------------------------------------------------------------------
# Locales aktivieren (de_DE.UTF-8 + en_US.UTF-8)
# ---------------------------------------------------------------------------
RUN set -eux; \
    sed -i 's/^#\(de_DE\.UTF-8 UTF-8\)/\1/' /etc/locale.gen; \
    sed -i 's/^#\(en_US\.UTF-8 UTF-8\)/\1/' /etc/locale.gen; \
    locale-gen

# ---------------------------------------------------------------------------
# Skeleton-Configs einbinden
# ---------------------------------------------------------------------------
# /defaults/  – Voreinstellungen, die beim ersten Start nach /config kopiert
#               werden, falls dort noch keine Datei existiert. So überschreiben
#               wir niemals User-Anpassungen bei Container-Updates.
# /scripts/   – Helper-Scripts (init-Hook für First-Run-Setup).
COPY rootfs/defaults/ /defaults/
COPY rootfs/scripts/  /usr/local/bin/

RUN chmod +x /usr/local/bin/krusader-firstrun.sh /usr/local/bin/krusader-language.sh

# ---------------------------------------------------------------------------
# binhex-Init-Hook: das Base-Image führt Skripte unter
# /etc/cont-init.d/ NICHT aus (kein s6), aber es ruft beim Start
# /config/home/scripts/*.sh auf, wenn ENABLE_STARTUP_SCRIPTS=yes.
#
# Damit unser Setup IMMER läuft (auch ohne ENABLE_STARTUP_SCRIPTS), klinken
# wir uns vor dem `dbus-run-session -- krusader` Aufruf in /usr/local/bin/start.sh
# ein, indem wir `krusader-firstrun.sh` direkt davor ausführen lassen.
# ---------------------------------------------------------------------------
RUN set -eux; \
    if grep -q 'dbus-run-session -- krusader' /usr/local/bin/start.sh; then \
        sed -i 's|dbus-run-session -- krusader|/usr/local/bin/krusader-firstrun.sh \&\& dbus-run-session -- krusader|' /usr/local/bin/start.sh; \
    else \
        echo "[ERROR] start.sh layout changed – firstrun hook nicht gesetzt!" >&2; \
        exit 1; \
    fi

# ---------------------------------------------------------------------------
# Standard-Umgebungsvariablen (über Unraid-Template überschreibbar)
# ---------------------------------------------------------------------------
# KRUSADER_LANG  – UI-Sprache: de | en | (leer = System)
# KRUSADER_THEME – Theme: dark | light  (Default: dark)
ENV KRUSADER_LANG=de \
    KRUSADER_THEME=dark \
    LANG=de_DE.UTF-8 \
    LANGUAGE=de_DE:de:en

# CMD wird vom Base-Image vererbt (init.sh)
