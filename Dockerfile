# syntax=docker/dockerfile:1.27@sha256:bde3983e9c939224420ddaf6b784cc30e09b035a4dea01f581230c50809f372e
#
# Krusader for Unraid, community edition, on the LinuxServer Selkies base image
# (successor of their KasmVNC packaging): X11 and openbox streamed to a web
# client over a hybrid VNC/H.264 pipeline.
#
# Added on top of the base image:
#   * Krusader (twin-pane file manager)
#   * Kate (KDE editor), also Krusader's default editor
#   * Kompare (diff viewer), used by Krusader's "Compare by content"
#   * Archive support including RAR (unrar), 7z, ARJ, ACE, LHA
#   * Dark Mode theme for Krusader, Kate and KDE
#   * Right-click "Extract RAR here", "Open with Kate", "Open Konsole here"
#   * UI language via KRUSADER_LANG, with KDE language packs for each choice
#
# Repository:  https://github.com/junkerderprovinz/krusader
# License:     AGPL-3.0-only (this wrapper); Krusader upstream is GPL-3.0
#
# BASE_TAG=dev carries the same Ubuntu resolute series as the pinned
# ubunturesolute tag (Krusader 2.9.0 on KF6, #16), but builds selkies from its
# main branch instead of the frozen lsio pin. That is the only way to get the
# Firefox/Safari clipboard fix for #27 (the real _typeText() path and a native
# paste event instead of the Shift_L retype and the async clipboard workaround)
# without waiting for lsio to port upstream PR #301/#302. The price is that the
# base follows selkies main on every rebuild instead of a reviewed pin bump.
ARG BASE_TAG=dev@sha256:e00907648e3675afff81558667084fc840de46ca2b0a7b4f45e09d89c523379a
# 1 builds Krusader from source with the panel icon tint patches in patches/
# and installs it over the apt package; 0 keeps the plain apt Krusader as an
# emergency fallback.
ARG KRUSADER_SOURCE_BUILD=1
ARG KRUSADER_VERSION=2.9.0
# download.kde.org redirects to arbitrary third-party mirrors, so the tarball
# is hash-pinned; a different KRUSADER_VERSION needs its own hash.
ARG KRUSADER_SHA256=c9b79bfade6cc69fe0e341ecef932fcac8afd9fe94e8cbcfbd729feb54394e04

# Builder: patched Krusader from the official KDE source tarball. It uses
# ubuntu:resolute, the same archive as the Selkies base, so the Qt6/KF6 ABI
# matches the runtime libraries, but as a separate base so this expensive layer
# survives the weekly Selkies base bumps in the gha cache and only rebuilds when
# patches/, KRUSADER_VERSION or the ubuntu image digest change.
# The series has to match BASE_TAG's Ubuntu series. If BASE_TAG moves to
# another one (a rollback to noble, say), build with KRUSADER_SOURCE_BUILD=0:
# a resolute binary over another series' runtime would not start, and the CI
# smoke gate checks that the patched binary runs.
FROM ubuntu:resolute@sha256:da6fc2be547864451aa253836dd926da33623312df4a9a243e35dc877c378a78 AS krusader-build
ARG KRUSADER_VERSION
ARG KRUSADER_SHA256
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build extra-cmake-modules gettext \
        curl ca-certificates xz-utils patch \
        libacl1-dev libattr1-dev zlib1g-dev \
        qt6-base-dev qt6-5compat-dev \
        libkf6archive-dev libkf6bookmarks-dev libkf6codecs-dev \
        libkf6colorscheme-dev libkf6completion-dev libkf6config-dev \
        libkf6coreaddons-dev libkf6crash-dev libkf6doctools-dev \
        libkf6globalaccel-dev libkf6guiaddons-dev libkf6i18n-dev \
        libkf6iconthemes-dev libkf6itemviews-dev libkf6kio-dev \
        libkf6notifications-dev libkf6parts-dev libkf6solid-dev \
        libkf6statusnotifieritem-dev libkf6textwidgets-dev libkf6wallet-dev \
        libkf6widgetsaddons-dev libkf6windowsystem-dev libkf6xmlgui-dev; \
    apt-get clean; rm -rf /var/lib/apt/lists/*
RUN set -eux; \
    curl -fsSL -o /tmp/krusader.tar.xz \
        "https://download.kde.org/stable/krusader/${KRUSADER_VERSION}/krusader-${KRUSADER_VERSION}.tar.xz"; \
    printf '%s  %s\n' "${KRUSADER_SHA256}" /tmp/krusader.tar.xz > /tmp/krusader.sha256; \
    sha256sum -c /tmp/krusader.sha256; \
    rm -f /tmp/krusader.sha256; \
    mkdir /src; tar -xJf /tmp/krusader.tar.xz -C /src --strip-components=1; rm -f /tmp/krusader.tar.xz
COPY patches/ /patches/
RUN set -eux; \
    for p in /patches/*.patch; do patch -d /src -p1 < "$p"; done; \
    # KDE_INSTALL_USE_QT_SYS_PATHS puts the krarc KIO worker in the Qt plugin
    # path the runtime searches (CMakeLists warns without it).
    cmake -S /src -B /build -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr -DKDE_INSTALL_USE_QT_SYS_PATHS=true; \
    cmake --build /build; \
    DESTDIR=/staging cmake --install /build; \
    # init-krusader looks for this marker to skip the folder icon bake so
    # KIconLoader can tint, and the CI smoke gate asserts it exists.
    mkdir -p /staging/usr/share/krusader; \
    touch /staging/usr/share/krusader/.icontint

# KRUSADER_SOURCE_BUILD=0 selects an empty staging tree, so the apt krusader stays.
FROM ubuntu:resolute@sha256:da6fc2be547864451aa253836dd926da33623312df4a9a243e35dc877c378a78 AS krusader-artifact-0
RUN mkdir -p /staging
FROM krusader-build AS krusader-artifact-1
# hadolint ignore=DL3006
FROM krusader-artifact-${KRUSADER_SOURCE_BUILD} AS krusader-artifact

# BASE_TAG names a flavor rather than :latest, because the Selkies base makes
# breaking changes between versions.
FROM ghcr.io/linuxserver/baseimage-selkies:${BASE_TAG}

LABEL maintainer="junkerderprovinz"
LABEL org.opencontainers.image.title="krusader"
LABEL org.opencontainers.image.description="Krusader für Unraid mit Selkies-Web-Desktop, Dark Mode, Kate-Editor, RAR-Support und Multi-Language-UI"
LABEL org.opencontainers.image.source="https://github.com/junkerderprovinz/krusader"
LABEL org.opencontainers.image.licenses="AGPL-3.0-only"
LABEL org.opencontainers.image.vendor="junkerderprovinz"

# TITLE feeds the PWA manifest and SELKIES_UI_TITLE the tab and sidebar title
# of the Selkies client; this base needs both.
#
# Selkies turns basic auth on by default with the well-known ubuntu/mypasswd
# credentials, so SELKIES_ENABLE_BASIC_AUTH=false keeps a container without a
# password free of a login. The base's nginx would still turn a set but empty
# PASSWORD into one, which is why init-nologin drops an empty PASSWORD and
# CUSTOM_USER before nginx starts. Selkies listens on localhost only, so a real
# CUSTOM_USER/PASSWORD is enforced by nginx, the one reachable entry point.
ENV TITLE="Krusader" \
    SELKIES_UI_TITLE="Krusader" \
    SELKIES_ENABLE_BASIC_AUTH="false"

# Qt draws a window's contents at the DPI Selkies hands a HiDPI browser but
# keeps the window at its old size, so a laptop streaming in physical pixels
# gets clipped dialogs under tiny window frames. Streaming every browser at its
# CSS size with the DPI fixed at 96 keeps one consistent size on any display.
# HiDPI can still be switched on per browser in the Selkies sidebar.
ENV SELKIES_USE_CSS_SCALING="true" \
    SELKIES_SCALING_DPI="96"

# Phase 1: required packages, the build fails if one is missing. unrar lives in
# Ubuntu's multiverse component, which the sed below enables.
RUN set -eux; \
    sed -i '/^Components:/ s/$/ multiverse universe restricted/' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || true; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        # file manager and editor
        krusader kate konsole ark krename \
        # Diff viewer for "Compare by content". Krusader looks for kdiff3,
        # kompare and xxdiff in that order and disables the action when it
        # finds none. kompare is the lightest (its KF6 deps are already in the
        # image); Krusader picks it up from PATH on first use and records it
        # under krusaderrc [Dependencies] "diff utility", so a user who mounts
        # another differ can point that key elsewhere.
        kompare \
        # theme and icons
        breeze breeze-icon-theme kde-style-breeze \
        # Archive tools. From resolute on the RAR codec for 7zip is 7zip-rar;
        # p7zip-rar is gone and p7zip-full is a transitional package.
        unrar p7zip-full 7zip-rar \
        zip unzip bzip2 lzma xz-utils \
        lhasa arj unace rpm cpio \
        # KDE/Qt runtime
        dbus-x11 kde-cli-tools kdialog keditbookmarks \
        # x11-xkb-utils (setxkbmap) and xkb-data: the Selkies base ships Xvfb with
        # no keymap, so autostart loads a full keymap at session start to bind
        # Shift and keep pasted uppercase from collapsing to lowercase (#27).
        x11-xkb-utils xkb-data \
        # Sonnet's hunspell backend; without it KDE apps report "No speller
        # backends available!".
        sonnet-plugins \
        # plasma-integration provides the 'kde' Qt platform theme plugin
        # (libkdeplatformtheme.so), which reads KDE .colors schemes such as
        # DarkMode.colors. qt5ct cannot parse that format and falls back to a
        # blank white palette.
        plasma-integration kde-config-gtk-style \
        # ksmserver (part of plasma-workspace, ~150 MB) registers as
        # org.kde.ksmserver on D-Bus and sends saveYourself to KMainWindow apps
        # on exit, which persists window geometry and UI state (bugs #1/#2).
        plasma-workspace \
        # fallback theme for Qt apps without the KDE plugin
        qt5ct qt6ct \
        # hunspell; the dictionaries come in phase 2
        hunspell \
        # Without fontconfig and a font cache Qt/KDE apps render text as empty
        # lines. DejaVu and Liberation are the UI defaults, Hack the monospace
        # fallback.
        fontconfig \
        fonts-noto fonts-noto-cjk fonts-noto-color-emoji \
        fonts-dejavu fonts-dejavu-core fonts-dejavu-extra \
        fonts-liberation fonts-liberation2 \
        fonts-hack fonts-freefont-ttf \
        # locale tools
        locales coreutils sed; \
    # some tools look for unarj
    [ -e /usr/bin/unarj ] || ln -s /usr/bin/arj /usr/bin/unarj; \
    # Build the font cache now so the first container start finds the fonts.
    fc-cache -f -v >/dev/null 2>&1 || true; \
    # Phase 2 runs its own apt-get update, so the lists stay out of this layer.
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Patched Krusader over the apt package (see the builder stage). Installing
# over it instead of dpkg -r keeps the apt package providing the runtime
# dependencies (KF6 libs, KIO workers, icons) while the staging tree replaces
# the binary, the krarc KIO worker and the data files. With
# KRUSADER_SOURCE_BUILD=0 the staging tree is empty and this is a no-op.
COPY --from=krusader-artifact /staging/ /

# Phase 2: optional i18n and hunspell packages. Each wanted package is checked
# with apt-cache first and only the ones that exist are installed, so a renamed
# or missing package (Finnish uses voikko instead of hunspell, some languages
# have no KDE translation) does not fail the build.
#
# locale-gen is stubbed out meanwhile: otherwise every language-pack-* package
# runs it over all locales enabled so far, which pushes the build past 50
# minutes. The locales are generated once, further down.
RUN set -eux; \
    if [ -x /usr/sbin/locale-gen ]; then \
        mv /usr/sbin/locale-gen /usr/sbin/locale-gen.real; \
        printf '#!/bin/sh\nexit 0\n' > /usr/sbin/locale-gen; \
        chmod +x /usr/sbin/locale-gen; \
    fi

RUN set -eux; \
    # Phase 1 removed its lists, and lists carried over in the gha layer cache
    # would be stale anyway.
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

# Generate the locales once, one per supported language.
RUN set -eux; \
    if [ -f /usr/sbin/locale-gen.real ]; then \
        mv -f /usr/sbin/locale-gen.real /usr/sbin/locale-gen; \
    fi; \
    # language-pack-* registers every regional variant (de_AT, de_CH, de_LI,
    # ...) under /var/lib/locales/supported.d/, which locale-gen reads on top
    # of /etc/locale.gen. Clearing it keeps the image to the list below.
    rm -f /var/lib/locales/supported.d/*; \
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

COPY rootfs/ /

# The init log banner has one source, .github/assets/banner-raw.txt. CR is
# stripped so figlet output renders whatever the checkout's line endings, and
# the base's own brand banner (init-adduser/branding) is emptied so the log
# shows only the one from print-banner.sh.
COPY .github/assets/banner-raw.txt /usr/local/share/banner-raw.txt
RUN tr -d '\r' < /usr/local/share/banner-raw.txt > /usr/local/share/banner.txt \
    && : > /etc/s6-overlay/s6-rc.d/init-adduser/branding

# Browser tab favicon (#12). Selkies has one branding path,
# /usr/share/selkies/www/icon.png, which the base's init-nginx copies to
# web/favicon.ico and web/icon.png on every start and references from the
# generated manifest.json. The build fails if the path is gone, so a changed
# base layout shows up in CI and the weekly rebuild.
COPY .github/assets/icon.png /usr/local/share/krusader-icon.png
RUN set -eux; \
    dst=/usr/share/selkies/www/icon.png; \
    [ -f "$dst" ] || { echo "ERROR: $dst missing, the selkies base layout changed; update the branding override"; exit 1; }; \
    cp /usr/local/share/krusader-icon.png "$dst"; \
    echo "krusader: branded selkies icon at $dst"

# rootfs/ ships svc-xorg/dependencies.d/init-krusader-res so the screen size is
# settled before Xvfb reads it. If a base bump renamed that service, COPY
# rootfs/ / would create svc-xorg as a service directory without a type file;
# s6-rc-compile would then abort and every container would exit at boot while
# the build stays green. Checking for the base's own type file makes that a
# build error.
RUN set -eux; \
    t=/etc/s6-overlay/s6-rc.d/svc-xorg/type; \
    [ -f "$t" ] || { echo "ERROR: $t missing, the selkies base renamed or dropped svc-xorg; re-point rootfs/etc/s6-overlay/s6-rc.d/svc-xorg/dependencies.d/init-krusader-res at the new service"; exit 1; }; \
    echo "krusader: screen-size oneshot ordered before $(cat "$t") service svc-xorg"

# The status bar's MediaButton uses the system-file-manager icon, while the
# file panel draws a directory as inode-directory, which Breeze ships as a
# symlink to places/<size>/folder.svg. Copying that art (dereferenced with
# cp -L) onto system-file-manager size for size makes the button identical to
# the folder icon in the list. Both breeze-dark and its parent breeze get it,
# because KIconLoader falls back to the parent for any size breeze-dark does
# not ship itself.
RUN set -eux; \
    n=0; \
    for theme in /usr/share/icons/breeze-dark /usr/share/icons/breeze; do \
        [ -d "$theme" ] || continue; \
        store="/usr/local/share/krusader-mediabutton/$(basename "$theme")"; \
        mkdir -p "$store"; \
        # Pristine copies of the panel folder icon, which init-krusader tints
        # to the configured panel foreground and restores when no colour is
        # set.
        pstore="/usr/local/share/krusader-panelfolder/$(basename "$theme")"; \
        mkdir -p "$pstore"; \
        pn=0; \
        for pdir in "$theme"/places/*/; do \
            [ -e "${pdir}folder.svg" ] || continue; \
            cp -L "${pdir}folder.svg" "$pstore/$(basename "$pdir").svg"; \
            pn=$((pn + 1)); \
        done; \
        [ "$pn" -gt 0 ] || { echo "ERROR: no places/*/folder.svg in $theme, the panel folder tint store is empty; breeze layout changed"; exit 1; }; \
        for appdir in "$theme"/apps/*/; do \
            [ -e "${appdir}system-file-manager.svg" ] || continue; \
            sz="$(basename "$appdir")"; \
            src="$theme/mimetypes/$sz/inode-directory.svg"; \
            [ -e "$src" ] || src="$theme/places/$sz/folder.svg"; \
            [ -e "$src" ] || continue; \
            cp -L "$src" "${appdir}system-file-manager.svg"; \
            # pristine copy for init-krusader, which tints the button to the
            # configured status bar foreground on every start
            cp -L "$src" "$store/$sz.svg"; \
            n=$((n + 1)); \
        done; \
        gtk-update-icon-cache -f -t "$theme" 2>/dev/null || true; \
    done; \
    [ "$n" -gt 0 ] || { echo "ERROR: no apps/*/system-file-manager.svg overridden, breeze layout changed"; exit 1; }; \
    echo "krusader: MediaButton icon matched to the panel folder icon ($n file(s)) + pristine store"

# The scripts are committed without the executable bit.
RUN chmod +x /usr/local/bin/krusader-*.sh \
             /usr/local/bin/krusader-session \
             /usr/local/bin/print-banner.sh \
             /etc/s6-overlay/s6-rc.d/init-krusader-res/run \
             /etc/s6-overlay/s6-rc.d/init-dpi/run \
             /etc/s6-overlay/s6-rc.d/init-krusader/run \
             /etc/s6-overlay/s6-rc.d/init-nologin/run \
             /etc/s6-overlay/s6-rc.d/svc-krusader-ready/run \
             /defaults/autostart \
             /defaults/startwm.sh

# KRUSADER_LANG (an ISO code or "system"), KRUSADER_THEME (dark or light) and
# KEYBOARD_LAYOUT are meant to be set from the Unraid template. The base serves
# HTTP on CUSTOM_PORT (3000) and HTTPS on CUSTOM_HTTPS_PORT (3001).
#
# The boot locale stays language-neutral (C.UTF-8) and KRUSADER_LANG drives the
# UI language through krusader-language.sh (kdeglobals [Translations] plus a
# matching LANG/LANGUAGE in the s6 env). A German LANG/LANGUAGE/LC_ALL here
# would override that: the base's init-selkies-config derives
# LANGUAGE=${LC_ALL%.UTF-8} and LANG=${LC_ALL} whenever LC_ALL is set, and KDE
# gives that LANGUAGE priority over kdeglobals, so a user with KRUSADER_LANG=en
# would get a German UI (#21).
#
# There is no MAX_RES default here. The screen size is the container's biggest
# single memory item: Xvfb allocates the whole framebuffer up front in shared
# memory, about 4 bytes per pixel, whatever the size of the browser window.
# Measured on a live container (Unraid, one client at 2528x1324):
#
#   15360x8640 (base default)  ->  Xvfb RSS 578 MB, container 778 MiB
#   5120x2880                  ->  Xvfb RSS 119 MB, container 252 MiB
#   3840x2160                  ->  Xvfb RSS  93 MB, container 266 MiB
#
# The full range has to stay available, so the choice is the user's: the image
# keeps the base default and the Unraid template offers a preset dropdown
# (MAX_RES) plus a free field (MAX_RES_CUSTOM) that wins. init-krusader-res
# settles the two before svc-xorg starts; krusader-resolution.sh holds the
# rules and tests/test-krusader-resolution.sh pins them.
ENV KRUSADER_LANG=de \
    KRUSADER_THEME=dark \
    KEYBOARD_LAYOUT=us \
    LANG=C.UTF-8 \
    QT_QPA_PLATFORMTHEME=qt5ct \
    QT_STYLE_OVERRIDE=Breeze

# Any HTTP status counts as up; only 000 (no answer, connection refused) marks
# the container unhealthy. curl comes with the base image.
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD ["/bin/sh", "-c", "c=$(curl -ks -o /dev/null -w '%{http_code}' --max-time 5 https://127.0.0.1:${CUSTOM_HTTPS_PORT:-3001}/); [ \"$c\" != \"000\" ] || exit 1"]
