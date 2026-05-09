<h1 align="center">Krusader for Unraid</h1>

<a href="https://krusader.org">
  <img src="https://raw.githubusercontent.com/junkerderprovinz/krusader/main/.github/assets/krusader-banner.png" alt="Krusader" width="100%">
</a>

<p align="center">
  <a href="https://github.com/junkerderprovinz/krusader/actions/workflows/build.yml"><img src="https://img.shields.io/github/actions/workflow/status/junkerderprovinz/krusader/build.yml?branch=main&label=Build&style=for-the-badge&logo=githubactions&logoColor=white" alt="Build" height="36"></a>&nbsp;
  <a href="https://github.com/junkerderprovinz/krusader/pkgs/container/krusader"><img src="https://img.shields.io/badge/Image-ghcr.io-1d99f3?style=for-the-badge&logo=docker&logoColor=white" alt="Image" height="36"></a>&nbsp;
  <a href="https://github.com/junkerderprovinz/krusader/pkgs/container/krusader"><img src="https://img.shields.io/badge/Arch-amd64%20%7C%20arm64-success?style=for-the-badge&logo=linux&logoColor=white" alt="Arch" height="36"></a>&nbsp;
  <a href="https://github.com/kasmtech/KasmVNC"><img src="https://img.shields.io/badge/Web-KasmVNC-3daee9?style=for-the-badge&logo=kde&logoColor=white" alt="KasmVNC" height="36"></a>&nbsp;
  <a href="#4-languages"><img src="https://img.shields.io/badge/Languages-25-3daee9?style=for-the-badge&logo=googletranslate&logoColor=white" alt="Languages" height="36"></a>&nbsp;
  <a href="https://unraid.net"><img src="https://img.shields.io/badge/Unraid-Template-f15a2c?style=for-the-badge&logo=unraid&logoColor=white" alt="Unraid" height="36"></a>&nbsp;
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge&logo=opensourceinitiative&logoColor=white" alt="License" height="36"></a>
</p>

<p align="center">
A modern, plug-and-play Docker image for <b>Krusader</b> on Unraid. Twin-pane file
management in your browser, powered by KasmVNC, with Breeze Dark, Kate as
external editor, full archive support and 25 UI languages — all configurable
from the Unraid template, no SSH or config-file editing required.
</p>

---

## Table of Contents

1. [What is this?](#1-what-is-this)
2. [Quick Start on Unraid](#2-quick-start-on-unraid)
3. [Configuration](#3-configuration)
4. [Languages](#4-languages)
5. [Right-Click Actions](#5-right-click-actions)
6. [Customisation & Persistence](#6-customisation--persistence)
7. [Building Locally](#7-building-locally)
8. [Updating](#8-updating)
9. [Troubleshooting](#9-troubleshooting)
10. [Architecture](#10-architecture)
11. [Contributing / License](#11-contributing--license)

---

## 1. What is this?

This image packages [Krusader](https://krusader.org) — KDE's twin-pane file
manager — into a self-contained Docker container that runs in any modern web
browser. It is built on top of [`linuxserver/baseimage-kasmvnc`](https://github.com/linuxserver/docker-baseimage-kasmvnc),
so it benefits from LSIO's hardware-accelerated KasmVNC stack and weekly
security updates, while everything Krusader-specific (theme, archive tools,
right-click actions, language packs, default configs) is layered on top in
this repo.

What's included beyond bare Krusader:

- **KasmVNC** instead of noVNC — hardware-accelerated rendering, real
  browser clipboard, native file upload and download, high-DPI ready
- **Breeze Dark** pre-applied to Krusader, Kate and the whole KDE stack;
  switch to light with one variable
- **Kate** wired up as Krusader's external editor, also Breeze Dark, with
  spell-check
- **Full archive support** — RAR, 7z, ZIP, TAR, GZ, BZ2, XZ, LHA, ARJ, ACE,
  RPM, CPIO; right-click "Extract RAR here" works out of the box
- **25 UI languages** picked from a dropdown in the Unraid template
- **Update-safe configs** — first-run-only seeding, your customisations in
  `/config` survive every `docker pull`
- **Multi-arch** — amd64 and arm64

| | **This image** | binhex | jlesage | ich777 |
|---|:---:|:---:|:---:|:---:|
| Web stack | **KasmVNC** | noVNC | noVNC | noVNC |
| HW-accelerated rendering | ✅ | ❌ | ❌ | ❌ |
| Browser clipboard | ✅ | ⚠️ | ⚠️ | ⚠️ |
| File upload via WebUI | ✅ | ❌ | ❌ | ❌ |
| Breeze Dark default | ✅ | ❌ | ❌ | ❌ |
| Kate as editor | ✅ | ❌ | ❌ | ❌ |
| RAR right-click | ✅ | ❌ | ❌ | ❌ |
| Language dropdown | ✅ (25) | ❌ | ❌ | ❌ |
| Multi-arch | ✅ amd64 + arm64 | amd64 | ✅ | amd64 |
| Base | LinuxServer | binhex/Arch | jlesage/Alpine | ich777/Debian |

---

## 2. Quick Start on Unraid

### Step 1 — Install the template

The repository ships one template: `unraid-template.xml` — production install
(`Krusader`, ports 3000/3001).

Pull the template directly into Unraid's user-template folder via the
Unraid console / SSH:

```bash
mkdir -p /boot/config/plugins/dockerMan/templates-user && \
curl -fsSL -o /boot/config/plugins/dockerMan/templates-user/my-Krusader.xml \
  https://raw.githubusercontent.com/junkerderprovinz/krusader/main/unraid-template.xml
```

### Step 2 — Add the container

In the Unraid Web UI: **Docker** tab → **Add Container** → in the
**Template** dropdown, pick **Krusader** under *User templates*. All fields
are pre-filled.

### Step 3 — Adjust paths and start

The defaults work out of the box, but you may want to tweak:

- **Storage (`/storage`)** — defaults to `/mnt`, which exposes all shares
  and disks. Restrict to e.g. `/mnt/user` if you want.
- **UI Language** — dropdown, default `de`.
- **Theme** — `dark` or `light`.
- **KasmVNC Password** — leave empty for LAN-only, set anything for
  exposure beyond the LAN.

Hit **Apply**. The first start takes 30–60 seconds while the container
seeds its config and KasmVNC generates a self-signed certificate.

### Step 4 — Open the WebUI

`http://<unraid-ip>:3000/` (HTTP) or `https://<unraid-ip>:3001/` (HTTPS, self-signed).

### Plain Docker (no Unraid)

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
  ghcr.io/junkerderprovinz/krusader:latest
```

> **`--shm-size=1gb`** is required for smooth KDE rendering. The Unraid
> template sets it for you. Once Community Applications has accepted this
> image, it will also be installable via **Apps** → search `Krusader`.

---

## 3. Configuration

| Variable | Default | Description |
|---|---|---|
| `PUID` | `99` | User ID — Unraid's *nobody* |
| `PGID` | `100` | Group ID — Unraid's *users* |
| `TZ` | `Etc/UTC` | Timezone, e.g. `Europe/Vienna` |
| `KRUSADER_LANG` | `de` | UI language — see [§ Languages](#4-languages) |
| `KRUSADER_THEME` | `dark` | `dark` (Breeze Dark) or `light` (Breeze) |
| `CUSTOM_USER` | `abc` | KasmVNC HTTP-basic-auth username |
| `PASSWORD` | *(empty)* | KasmVNC password — **set this if exposed beyond LAN** |
| `TITLE` | `Krusader` | Browser tab / KasmVNC top-bar title |
| `UMASK` | `022` | File-creation mask |

### Ports & Volumes

| Port | Purpose |  | Volume | Purpose |
|---|---|---|---|---|
| `3000` | KasmVNC HTTP |  | `/config` | Persistent KDE / Krusader / Kate configs |
| `3001` | KasmVNC HTTPS *(self-signed)* |  | `/storage` | Files to manage — default host `/mnt` |

---

## 4. Languages

The Unraid template ships a **dropdown** with **25 UI languages** (German
default, plus `system` fallback). Each language has its
`language-pack-<code>` and `language-pack-kde-<code>` baked in — switching
is instant after a restart.

| Region | Languages |
|---|---|
| **Western Europe** | 🇩🇪 `de` Deutsch · 🇬🇧 `en` English · 🇫🇷 `fr` Français · 🇪🇸 `es` Español · 🇮🇹 `it` Italiano · 🇵🇹 `pt` Português · 🇳🇱 `nl` Nederlands · 🇪🇸 `ca` Català · 🇪🇸 `eu` Euskara · 🇮🇪 `ga` Gaeilge |
| **Northern Europe** | 🇩🇰 `da` Dansk · 🇸🇪 `sv` Svenska · 🇳🇴 `nb` Norsk Bokmål · 🇫🇮 `fi` Suomi · 🇮🇸 `is` Íslenska |
| **Central / Eastern Europe** | 🇵🇱 `pl` Polski · 🇨🇿 `cs` Čeština · 🇸🇰 `sk` Slovenčina · 🇭🇺 `hu` Magyar · 🇷🇴 `ro` Română · 🇸🇮 `sl` Slovenščina · 🇭🇷 `hr` Hrvatski · 🇷🇸 `sr` Српски · 🇧🇬 `bg` Български · 🇺🇦 `uk` Українська · 🇷🇺 `ru` Русский · 🇬🇷 `el` Ελληνικά |
| **Middle East** | 🇹🇷 `tr` Türkçe · 🇮🇱 `he` עברית · 🇸🇦 `ar` العربية |
| **Asia / CJK** | 🇯🇵 `ja` 日本語 · 🇰🇷 `ko` 한국어 · 🇨🇳 `zh` 中文 |
| **Fallback** | `system` — use the container's default locale |

*Default: `de` (Deutsch). Set via `KRUSADER_LANG` or the Unraid dropdown.*

> **How it works:** Unraid renders any `<Default>a|b|c</Default>` value
> with at least one `|` as a native `<select>` dropdown. The cont-init hook
> re-applies the language on every start.

---

## 5. Right-Click Actions

Krusader's *UserActions* are pre-loaded with five extras:

| Action | Command |
|---|---|
| **Extract RAR here** | `unrar x -o+` into the current directory |
| **Extract RAR to subfolder** | Same, but into a folder named after the archive |
| **Extract 7z here** | `7z x` into the current directory |
| **Open with Kate** | Opens the selected file(s) in Kate |
| **Open Konsole here** | New Konsole tab in the current directory |

Edit them via *Krusader → Settings → Configure UserActions*, or directly at
`/config/.local/share/krusader/useractions.xml`.

---

## 6. Customisation & Persistence

On the **first start only**, the container seeds defaults from `/defaults/`
into `/config/`:

```
/config/
├── .config/
│   ├── kdeglobals          # KDE color scheme + Breeze Dark
│   ├── krusaderrc          # Editor=kate, theme, panel layout
│   └── katerc              # Kate Breeze Dark
└── .local/share/krusader/
    └── useractions.xml     # right-click actions
```

A marker file `/config/.krusader-firstrun.done` is written so subsequent
container starts **never overwrite your customisations**. To re-seed
defaults, delete the marker and restart.

The two env-driven knobs (`KRUSADER_LANG`, `KRUSADER_THEME`) are
re-applied on **every** start via a `cont-init.d` hook, so you can flip
them freely.

The base image also supports `/config/custom-cont-init.d/` for your own
init scripts — see the [LinuxServer docs](https://docs.linuxserver.io/general/container-customization/).

---

## 7. Building Locally

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

---

## 8. Updating

```bash
docker pull ghcr.io/junkerderprovinz/krusader:latest
docker stop krusader && docker rm krusader
# re-create with the same template / docker run args
```

On Unraid: **Docker** tab → click the container → **Force Update**. Your
`/config` is untouched.

> The image is rebuilt **weekly** via GitHub Actions for upstream KasmVNC,
> Ubuntu and KDE patches.

---

## 9. Troubleshooting

<details>
<summary><b>WebUI is black / desktop never appears</b></summary>

- Make sure `--shm-size` is at least `512mb` (Unraid template sets `1gb`)
- Check the container log for KasmVNC startup errors
- Try opening on `https://<ip>:3001/` (self-signed) — sometimes browsers
  block ws over plain http
- Wait 30–60 seconds on first start; KDE caches need to be built once
</details>

<details>
<summary><b>WebUI is unreachable</b></summary>

- Check the host port isn't already taken: `netstat -tlnp | grep 3000`
- Disable the host firewall briefly to rule it out
- Verify the container is listening: `docker exec krusader ss -tlnp`
- Confirm the network is `bridge` (or `host`), not a custom `br0` whose
  IP isn't reachable from your client
</details>

<details>
<summary><b>Right-click "Extract RAR here" does nothing</b></summary>

- Open a Konsole inside the container: `which unrar` should print
  `/usr/bin/unrar`. If empty, file an issue.
</details>

<details>
<summary><b>Language change doesn't take effect</b></summary>

- Restart the container — language is applied at start, not live
- Check the env value matches a code from [§ Languages](#4-languages)
- The script writes `/etc/profile.d/zz-krusader-lang.sh` and updates
  `kdeglobals[Translations]`
</details>

<details>
<summary><b>Files outside /storage not visible</b></summary>

- That's by design. Map another path:
  `-v /mnt/disks/somepool:/storage/somepool`
</details>

<details>
<summary><b>"Permission denied" on /storage/...</b></summary>

- Check `PUID` / `PGID`. On Unraid, `99:100` (nobody:users) match share
  permissions.
</details>

<details>
<summary><b>KasmVNC password not accepted</b></summary>

- Open in a private window once — your browser may have cached old
  credentials.
</details>

---

## 10. Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  ghcr.io/linuxserver/baseimage-kasmvnc:ubuntunoble              │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  s6-overlay v3 init                                       │  │
│  │   ↓                                                       │  │
│  │  /etc/cont-init.d/30-krusader-firstrun.sh                 │  │
│  │   ↓ seeds /config from /defaults  (first run only)        │  │
│  │   ↓ runs krusader-language.sh  (every run)                │  │
│  │   ↓                                                       │  │
│  │  KasmVNC ← /defaults/autostart → dbus-launch krusader     │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 11. Contributing / License

Pull requests welcome. Issues: <https://github.com/junkerderprovinz/krusader/issues>.

**Licensing — dual:**

- This **wrapper repository** (Dockerfile, `rootfs/`, scripts, Unraid
  templates, README and banner/icon artwork) is licensed under the
  [MIT License](LICENSE).
- **Krusader itself** and the bundled KDE / Qt / KasmVNC / unrar / LSIO
  base-image components retain their upstream licenses (mostly
  GPL-2.0+ / GPL-3.0+ / LGPL-2.1+, plus unrar's non-free terms). When
  you run, redistribute or rebuild the resulting container image, you
  must comply with **all** of those licenses, not only with this
  wrapper's MIT license. See the `LICENSE` file for the full notice.

```bash
# Run lints locally (CI runs them too)
docker run --rm -i hadolint/hadolint < Dockerfile
docker run --rm -v "$PWD:/mnt" koalaman/shellcheck:stable rootfs/etc/cont-init.d/* rootfs/usr/local/bin/*
xmllint --noout unraid-template.xml ca_profile.xml
```

### Credits

- [**Krusader**](https://krusader.org) — KDE community, the actual file manager
- [**LinuxServer.io**](https://www.linuxserver.io) — for the excellent [`baseimage-kasmvnc`](https://github.com/linuxserver/docker-baseimage-kasmvnc)
- [**KasmVNC**](https://github.com/kasmtech/KasmVNC) — for finally fixing remote-desktop-in-a-browser
- [**Kate**](https://kate-editor.org) — best lightweight editor on Linux
- Inspiration: binhex, jlesage and ich777 Krusader containers — they paved the way
