<p align="center">
  <img src="https://raw.githubusercontent.com/junkerderprovinz/krusader/main/.github/assets/krusader-banner.png" alt="Krusader" width="100%">
</p>

<p align="center">
  <a href="https://github.com/junkerderprovinz/krusader/actions/workflows/build.yml"><img src="https://img.shields.io/github/actions/workflow/status/junkerderprovinz/krusader/build.yml?branch=main&label=Build&style=for-the-badge&logo=githubactions&logoColor=white" alt="Build" height="36"></a>&nbsp;
  <a href="https://github.com/junkerderprovinz/krusader/actions/workflows/lint.yml"><img src="https://img.shields.io/github/actions/workflow/status/junkerderprovinz/krusader/lint.yml?branch=main&label=Lint&style=for-the-badge&logo=githubactions&logoColor=white" alt="Lint" height="36"></a>&nbsp;
  <a href="https://hub.docker.com/r/junkerderprovinz/krusader"><img src="https://img.shields.io/docker/pulls/junkerderprovinz/krusader?style=for-the-badge&logo=docker&logoColor=white&label=Pulls&color=1d99f3" alt="Docker Pulls" height="36"></a>&nbsp;
  <a href="https://hub.docker.com/r/junkerderprovinz/krusader"><img src="https://img.shields.io/docker/image-size/junkerderprovinz/krusader/latest?style=for-the-badge&logo=docker&logoColor=white&label=Size&color=1d99f3" alt="Image Size" height="36"></a>&nbsp;
  <a href="https://github.com/junkerderprovinz/krusader/pkgs/container/krusader"><img src="https://img.shields.io/badge/Arch-amd64%20%7C%20arm64-success?style=for-the-badge&logo=linux&logoColor=white" alt="Arch" height="36"></a>&nbsp;
  <a href="https://github.com/selkies-project/selkies"><img src="https://img.shields.io/badge/Web-Selkies-3daee9?style=for-the-badge&logo=kde&logoColor=white" alt="Selkies" height="36"></a>&nbsp;
  <a href="#5-languages"><img src="https://img.shields.io/badge/Languages-33-3daee9?style=for-the-badge&logo=googletranslate&logoColor=white" alt="Languages" height="36"></a>&nbsp;
  <a href="https://unraid.net"><img src="https://img.shields.io/badge/Unraid-Template-f15a2c?style=for-the-badge&logo=unraid&logoColor=white" alt="Unraid" height="36"></a>&nbsp;
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge&logo=opensourceinitiative&logoColor=white" alt="License" height="36"></a>
</p>

<br>

<p align="center">
A modern, plug-and-play Docker image for <b>Krusader</b> on Unraid. Twin-pane file
management in your browser, powered by Selkies, with Dark Mode, Kate as
external editor, full archive support and 33 UI languages — all configurable
from the Unraid template, no SSH or config-file editing required.
</p>

<br>

<p align="center">
  <a href="https://buymeacoffee.com/junkerderprovinz">
    <img src=".github/assets/button-buy-me-a-coffee.svg" alt="Buy me a coffee" width="220">
  </a>
</p>

<br>

## Table of Contents

1. [Overview](#1-overview)
2. [Screenshots](#2-screenshots)
3. [Quick Start](#3-quick-start)
4. [Configuration](#4-configuration)
5. [Languages](#5-languages)
6. [Right-Click Actions](#6-right-click-actions)
7. [Customisation & Persistence](#7-customisation--persistence)
8. [Building Locally](#8-building-locally)
9. [Updating](#9-updating)
10. [Troubleshooting](#10-troubleshooting)
11. [Architecture](#11-architecture)
12. [Contributing / License](#12-contributing--license)
13. [Support this project](#13-support-this-project)
<br>

## 1. Overview

This image packages [Krusader](https://krusader.org) — KDE's twin-pane file manager — into a self-contained Docker container that runs in any modern web browser. It is built on top of [`linuxserver/baseimage-selkies`](https://github.com/linuxserver/docker-baseimage-selkies), so it benefits from LSIO's actively-maintained Selkies desktop-streaming stack (a hybrid VNC/H.264 pipeline) and weekly security updates, while everything Krusader-specific (theme, archive tools, right-click actions, language packs, default configs) is layered on top in this repo.

What's included beyond bare Krusader:

- **Selkies** instead of noVNC — a hybrid VNC/H.264 pipeline for a smooth 60fps web desktop, real bidirectional browser clipboard, native file upload and download, high-DPI ready
- **Dark Mode** pre-applied to Krusader, Kate and the whole KDE stack; switch to light with one variable
- **Row-aware panel icons** — Krusader is built from source with our icon-tint patch: the file-list icons follow each row's effective text colour (normal, current and marked rows, including custom Konfigurator colours), so icons stay legible on any row highlight
- **Kate** wired up as Krusader's external editor, also Dark Mode, with spell-check
- **krename** — KDE's batch-rename dialog bundled; rename hundreds of files at once using regex, counters, case transforms and metadata patterns
- **Full archive support** — RAR, 7z, ZIP, TAR, GZ, BZ2, XZ, LHA, ARJ, ACE, RPM, CPIO; right-click "Extract RAR here" works out of the box
- **33 UI languages** picked from a dropdown in the Unraid template
- **Update-safe configs** — first-run-only seeding, your customisations in `/config` survive every `docker pull`
- **Multi-arch** — amd64 and arm64

| | **This image** | binhex | jlesage | ich777 |
|---|:---:|:---:|:---:|:---:|
| Web stack | **Selkies** | noVNC | noVNC | noVNC |
| HW-accelerated rendering | ✅ | ❌ | ❌ | ❌ |
| Browser clipboard | ✅ | ⚠️ | ⚠️ | ⚠️ |
| File upload via WebUI | ✅ | ❌ | ❌ | ❌ |
| Dark Mode default | ✅ | ❌ | ❌ | ❌ |
| Kate as editor | ✅ | ❌ | ❌ | ❌ |
| Batch rename (krename) | ✅ | ❌ | ❌ | ❌ |
| RAR right-click | ✅ | ❌ | ❌ | ❌ |
| Language dropdown | ✅ (33) | ❌ | ❌ | ❌ |
| Multi-arch | ✅ amd64 + arm64 | amd64 | ✅ | amd64 |
| Base | LinuxServer | binhex/Arch | jlesage/Alpine | ich777/Debian |

<br>

## 2. Screenshots

<p align="center">
  <img src="https://raw.githubusercontent.com/junkerderprovinz/krusader/main/.github/assets/screenshots/krusader-2.png" alt="Krusader twin-pane main view with Dark Mode theme" width="90%">
  <br><em>Twin-pane file manager — Dark Mode, F-key shortcuts, in-browser via Selkies.</em>
</p>

<br>

<p align="center">
  <img src="https://raw.githubusercontent.com/junkerderprovinz/krusader/main/.github/assets/screenshots/krusader-3.png" alt="Krusader configurator — Colors" width="90%">
  <br><em>Configurator → Colors: full control over panel foreground / background / selection.</em>
</p>

<br>

## 3. Quick Start

### Step 1 — Install the template

On Unraid: **Apps** → search for **Krusader** → click **Install**. The Community Applications
template is published from the
[`unraid-apps`](https://github.com/junkerderprovinz/unraid-apps) feed
(one feed for all of junkerderprovinz's apps).

To load it by hand, pull it into Unraid's user-template folder via the console / SSH:

```bash
mkdir -p /boot/config/plugins/dockerMan/templates-user && \
curl -fsSL -o /boot/config/plugins/dockerMan/templates-user/my-Krusader.xml \
  https://raw.githubusercontent.com/junkerderprovinz/unraid-apps/main/krusader/krusader.xml
```

### Step 2 — Add the container

In the Unraid Web UI: **Docker** tab → **Add Container** → in the **Template** dropdown, pick **Krusader** under *User templates*. All fields are pre-filled.

### Step 3 — Adjust paths and start

The defaults work out of the box, but you may want to tweak:

- **Storage (`/storage`)** — defaults to `/mnt`, which exposes all shares and disks. Restrict to e.g. `/mnt/user` if you want.
- **UI Language** — dropdown, default `de`.
- **Theme** — `dark` or `light`.
- **WebUI Password** — leave empty for LAN-only, set anything for exposure beyond the LAN.

Hit **Apply**. The first start takes 30–60 seconds while the container seeds its config and Selkies generates a self-signed certificate.

### Step 4 — Open the WebUI

`https://<unraid-ip>:3001/` (HTTPS, self-signed — accept the certificate once). **Use HTTPS:** the Selkies web client requires a secure context, so direct browser access must go through the HTTPS port. Port `3000` (HTTP) is **not** a usable direct fallback — opening `http://<unraid-ip>:3000/` shows a *"requires a secure connection (HTTPS)"* error and won't load. It exists for a reverse proxy that terminates TLS in front of the container (the proxy serves HTTPS to the browser and forwards HTTP to `3000`).

> Once Community Applications has accepted this image it will also be installable via **Apps** → search `Krusader`.

<details>
<summary>Plain Docker (no Unraid)</summary>

```bash
docker run -d \
  --name krusader \
  --restart unless-stopped \
  --shm-size=1gb \
  -p 3000:3000 -p 3001:3001 \
  -e PUID=99 -e PGID=100 \
  -e TZ=Europe/Vienna \
  -e KRUSADER_LANG=de \
  -e KRUSADER_THEME=dark \
  -v /mnt/user/appdata/krusader:/config \
  -v /mnt:/storage \
  junkerderprovinz/krusader:latest
```

**`--shm-size=1gb`** is required for smooth KDE rendering. The Unraid template sets it for you.

</details>

<br>

## 4. Configuration

| Variable | Default | Description |
|---|---|---|
| `PUID` | `99` | User ID — Unraid's *nobody* |
| `PGID` | `100` | Group ID — Unraid's *users* |
| `TZ` | `Etc/UTC` | Timezone, e.g. `Europe/Vienna` |
| `KRUSADER_LANG` | `de` | UI language — see [Languages](#5-languages) |
| `KRUSADER_THEME` | `dark` | `dark` (Dark Mode) or `light` (Breeze) |
| `CUSTOM_USER` | *(empty)* | WebUI login username — leave empty with `PASSWORD` for no login |
| `PASSWORD` | *(empty)* | WebUI password — **set this if exposed beyond LAN** |
| `TITLE` | `Krusader` | Browser tab / PWA title (see also `SELKIES_UI_TITLE`) |
| `UMASK` | `022` | File-creation mask |

| Port | Purpose | | Volume | Purpose |
|---|---|---|---|---|
| `3001` | Selkies HTTPS *(self-signed)* — **default WebUI, needed for clipboard** | | `/config` | Persistent KDE / Krusader / Kate configs |
| `3000` | Selkies HTTP *(reverse-proxy only — direct access needs HTTPS)* | | `/storage` | Files to manage — default host `/mnt` |

<br>

## 5. Languages

The Unraid template ships a **dropdown** with **33 UI languages** (German default, plus `system` fallback). Each language has its `language-pack-<code>` and `language-pack-kde-<code>` baked in — switching is instant after a restart.

| Region | Languages |
|---|---|
| **Western Europe** | 🇩🇪 `de` Deutsch · 🇬🇧 `en` English · 🇫🇷 `fr` Français · 🇪🇸 `es` Español · 🇮🇹 `it` Italiano · 🇵🇹 `pt` Português · 🇳🇱 `nl` Nederlands · 🇪🇸 `ca` Català · 🇪🇸 `eu` Euskara · 🇮🇪 `ga` Gaeilge |
| **Northern Europe** | 🇩🇰 `da` Dansk · 🇸🇪 `sv` Svenska · 🇳🇴 `nb` Norsk Bokmål · 🇫🇮 `fi` Suomi · 🇮🇸 `is` Íslenska |
| **Central / Eastern Europe** | 🇵🇱 `pl` Polski · 🇨🇿 `cs` Čeština · 🇸🇰 `sk` Slovenčina · 🇭🇺 `hu` Magyar · 🇷🇴 `ro` Română · 🇸🇮 `sl` Slovenščina · 🇭🇷 `hr` Hrvatski · 🇷🇸 `sr` Српски · 🇧🇬 `bg` Български · 🇺🇦 `uk` Українська · 🇷🇺 `ru` Русский · 🇬🇷 `el` Ελληνικά |
| **Middle East** | 🇹🇷 `tr` Türkçe · 🇮🇱 `he` עברית · 🇸🇦 `ar` العربية |
| **Asia / CJK** | 🇯🇵 `ja` 日本語 · 🇰🇷 `ko` 한국어 · 🇨🇳 `zh` 中文 |
| **Fallback** | `system` — use the container's default locale |

*Default: `de` (Deutsch). Set via `KRUSADER_LANG` or the Unraid dropdown.*

> **How it works:** Unraid renders any `<Default>a|b|c</Default>` value with at least one `|` as a native `<select>` dropdown. The cont-init hook re-applies the language on every start.

<br>

## 6. Right-Click Actions

Krusader's *UserActions* are pre-loaded with extras:

| Action | Command |
|---|---|
| **Extract RAR here** | `unrar x -o+` into the current directory |
| **Extract RAR to subfolder** | Same, but into a folder named after the archive |
| **Open with Kate** | Opens the selected file(s) in Kate |
| **Open Konsole here** | New Konsole tab in the current directory |

> For generic archive extraction (7z, ZIP, TAR, …) use Ark's built-in right-click menu — it is already installed and avoids a duplicate "Extract" entry in the context menu.

Edit them via *Krusader → Settings → Configure UserActions*, or directly at `/config/.local/share/krusader/useractions.xml`.

<br>

## 7. Customisation & Persistence

On the **first start only**, the container seeds defaults from `/defaults/` into `/config/`:

```
/config/
├── .config/
│   ├── kdeglobals          # KDE color scheme + Dark Mode
│   ├── krusaderrc          # Editor=kate, theme, panel layout
│   └── katerc              # Kate Dark Mode
└── .local/share/krusader/
    └── useractions.xml     # right-click actions
```

A marker file `/config/.krusader-firstrun.done` is written so subsequent container starts **never overwrite your customisations**. To re-seed defaults, delete the marker and restart.

The two env-driven knobs (`KRUSADER_LANG`, `KRUSADER_THEME`) are re-applied on **every** start via a `cont-init.d` hook, so you can flip them freely.

The base image also supports `/config/custom-cont-init.d/` for your own init scripts — see the [LinuxServer docs](https://docs.linuxserver.io/general/container-customization/).

<br>

## 8. Building Locally

```bash
git clone https://github.com/junkerderprovinz/krusader.git
cd krusader

# amd64 only (your local arch)
docker build -t krusader:dev .

# Multi-arch (amd64 + arm64) – needs buildx
docker buildx build --platform linux/amd64,linux/arm64 -t krusader:dev --load .

# Test run
docker run --rm -it \
  -p 3000:3000 \
  -v "$PWD/.dev-config:/config" \
  -v "$PWD:/storage" \
  krusader:dev
```

<br>

## 9. Updating

```bash
docker pull junkerderprovinz/krusader:latest
docker stop krusader && docker rm krusader
# re-create with the same template / docker run args
```

On Unraid: **Docker** tab → click the container → **Force Update**. Your `/config` is untouched.

> The image is rebuilt **weekly** via GitHub Actions for upstream Selkies, Ubuntu and KDE patches.

<br>

## 10. Troubleshooting

<details>
<summary><b>WebUI is black / desktop never appears</b></summary>

- Make sure `--shm-size` is at least `512mb` (Unraid template sets `1gb`)
- Check the container log for Selkies startup errors
- Try opening on `https://<ip>:3001/` (self-signed) — sometimes browsers block ws over plain http
- Wait 30–60 seconds on first start; KDE caches need to be built once
</details>

<details>
<summary><b>WebUI is unreachable</b></summary>

- Check the host port isn't already taken: `netstat -tlnp | grep 3000`
- Disable the host firewall briefly to rule it out
- Verify the container is listening: `docker exec krusader ss -tlnp`
- Confirm the network is `bridge` (or `host`), not a custom `br0` whose IP isn't reachable from your client
</details>

<details>
<summary><b>Right-click "Extract RAR here" does nothing</b></summary>

- Open a Konsole inside the container: `which unrar` should print `/usr/bin/unrar`. If empty, file an issue.
</details>

<details>
<summary><b>Language change doesn't take effect</b></summary>

- Restart the container — language is applied at start, not live
- Check the env value matches a code from the [Languages](#5-languages) table
- The script writes `/etc/profile.d/zz-krusader-lang.sh` and updates `kdeglobals[Translations]`
</details>

<details>
<summary><b>Files outside /storage not visible</b></summary>

- That's by design. Map another path: `-v /mnt/disks/somepool:/storage/somepool`
</details>

<details>
<summary><b>"Permission denied" on /storage/...</b></summary>

- Check `PUID` / `PGID`. On Unraid, `99:100` (nobody:users) match share permissions.
</details>

<details>
<summary><b>WebUI password not accepted</b></summary>

- Open in a private window once — your browser may have cached old credentials.
</details>

<details>
<summary><b>Container fails to start — "mkdir /etc/localtime: file exists"</b></summary>

You have a `/etc/localtime:/etc/localtime:ro` bind-mount configured (e.g. from an old template version). The LSIO base image manages `/etc/localtime` internally as a symlink; a bind-mount on top causes the conflict.

**Fix:** Remove the `/etc/localtime` path mapping from your container settings and use the `TZ` environment variable instead (e.g. `TZ=Europe/Vienna`). The `TZ` variable is the correct and supported way to set the timezone in LSIO-based containers.
</details>

<details>
<summary><b>Bottom status bar hides persistently now</b></summary>

Fixed as of the Selkies release (Krusader 2.9.0). Uncheck **View → Show Statusbar** once and it stays hidden across restarts — Krusader 2.9.0 auto-saves the statusbar state about a second after toggling and also saves settings on `docker stop`, so no clean exit is needed. (On the old KasmVNC image, Krusader 2.8.1 could not persist this.) The per-panel (upper) free-space / device status bar is a different widget and is unaffected.
</details>

<br>

## 11. Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  ghcr.io/linuxserver/baseimage-selkies:ubunturesolute          │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  s6-overlay v3 init                                       │  │
│  │   ↓                                                       │  │
│  │  s6-rc.d/init-krusader/run                                │  │
│  │   ↓ seeds /config from /defaults  (first run only)        │  │
│  │   ↓ sets theme, locale → s6 container environment         │  │
│  │   ↓                                                       │  │
│  │  Selkies (Xvfb+openbox) ← /defaults/autostart             │  │
│  │              → dbus-launch krusader-session               │  │
│  │                 → ksmserver (KDE session manager)         │  │
│  │                 → krusader                                │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

<br>

## 12. Contributing / License

Pull requests welcome. Issues: <https://github.com/junkerderprovinz/krusader/issues>.

**Licensing — dual:**

- This **wrapper repository** (Dockerfile, `rootfs/`, scripts, Unraid templates, README and banner/icon artwork) is licensed under the [MIT License](LICENSE).
- **Krusader itself** and the bundled KDE / Qt / Selkies / unrar / LSIO base-image components retain their upstream licenses (mostly GPL-2.0+ / GPL-3.0+ / LGPL-2.1+, plus unrar's non-free terms). When you run, redistribute or rebuild the resulting container image, you must comply with **all** of those licenses, not only with this wrapper's MIT license. See the `LICENSE` file for the full notice.

```bash
# Run lints locally (CI runs them too)
docker run --rm -i hadolint/hadolint < Dockerfile
docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:stable \
  $(find rootfs -type f \( -name '*.sh' -o -name 'run' -o -name 'autostart' -o -name 'krusader-session' \))
find . -name '*.xml' -not -path './.git/*' -exec xmllint --noout {} +
```

### Credits

- [**Krusader**](https://krusader.org) — KDE community, the actual file manager
- [**LinuxServer.io**](https://www.linuxserver.io) — for the excellent [`baseimage-selkies`](https://github.com/linuxserver/docker-baseimage-selkies)
- [**Selkies**](https://github.com/selkies-project/selkies) — for a modern, actively-developed browser desktop stack
- [**Kate**](https://kate-editor.org) — best lightweight editor on Linux
- Inspiration: binhex, jlesage and ich777 Krusader containers — they paved the way

<br>

## 13. Support this project

If this template saves you a setup hassle or a debug night, consider buying me a coffee:

<p align="center">
  <a href="https://buymeacoffee.com/junkerderprovinz">
    <img src=".github/assets/button-buy-me-a-coffee.svg" alt="Buy me a coffee" width="220">
  </a>
</p>

---

<sub>Part of a family of self-hosted Unraid apps + plugins by <b>junkerderprovinz</b> — see them all at <a href="https://github.com/junkerderprovinz">github.com/junkerderprovinz</a>, or install from <a href="https://unraid.net/community/apps">Community Applications</a>.</sub>
