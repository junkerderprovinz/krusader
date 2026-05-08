# Krusader for Unraid — KasmVNC Edition

[![Build & Push](https://github.com/junkerderprovinz/krusader/actions/workflows/build.yml/badge.svg)](https://github.com/junkerderprovinz/krusader/actions/workflows/build.yml)
[![Lint](https://github.com/junkerderprovinz/krusader/actions/workflows/lint.yml/badge.svg)](https://github.com/junkerderprovinz/krusader/actions/workflows/lint.yml)
[![Image: ghcr.io/junkerderprovinz/krusader](https://img.shields.io/badge/image-ghcr.io%2Fjunkerderprovinz%2Fkrusader-blue)](https://ghcr.io/junkerderprovinz/krusader)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL_3.0-yellow.svg)](LICENSE)

<a href="https://krusader.org">
  <img src="https://raw.githubusercontent.com/junkerderprovinz/krusader/main/.github/assets/krusader-banner.svg" alt="Krusader" width="100%">
</a>

A modern, plug-and-play Docker image for running **Krusader**, the legendary
KDE twin-pane file manager, as a web desktop on Unraid — built on
**KasmVNC** instead of the aging noVNC stack used by binhex / jlesage / ich777.
The result: a *much* smoother, hardware-accelerated browser experience,
proper clipboard, file upload/download, and high-DPI rendering out of the box.

Pre-configured for Unraid power-users: **Breeze Dark theme**, **Kate** as
default editor, full **RAR** / 7z / archive support with right-click actions,
and a **language dropdown** with 13 translated UIs.

---

## Why this image?

| | This image | binhex/krusader | jlesage/krusader | ich777/krusader |
|---|:---:|:---:|:---:|:---:|
| Web stack | **KasmVNC** | noVNC | noVNC | noVNC |
| Hardware-accelerated rendering | ✅ | ❌ | ❌ | ❌ |
| Native browser clipboard | ✅ | ⚠️ | ⚠️ | ⚠️ |
| File upload/download via WebUI | ✅ | ❌ | ❌ | ❌ |
| Breeze Dark default | ✅ | ❌ | ❌ | ❌ |
| Kate as Krusader editor | ✅ | ❌ | ❌ | ❌ |
| RAR right-click extract | ✅ | ❌ | ❌ | ❌ |
| Language dropdown (13 langs) | ✅ | ❌ | ❌ | ❌ |
| Multi-arch (amd64 + arm64) | ✅ | amd64 only | ✅ | amd64 only |

---

## Table of Contents

1. [What is this?](#1-what-is-this)
2. [Quick Start on Unraid](#2-quick-start-on-unraid)
3. [Configuration Variables](#3-configuration-variables)
4. [Languages](#4-languages)
5. [Right-Click Actions](#5-right-click-actions)
6. [Customization (configs survive updates)](#6-customization-configs-survive-updates)
7. [Building Locally](#7-building-locally)
8. [Updating](#8-updating)
9. [Troubleshooting](#9-troubleshooting)
10. [Contributing / License](#10-contributing--license)
11. [Credits](#11-credits)

---

## 1. What Is This?

[Krusader](https://krusader.org) is a powerful twin-pane file manager for KDE
in the Midnight-Commander tradition: two panels side by side, keyboard-driven,
with built-in archivers, batch renaming, file comparison, search, FTP/SFTP,
and a million little features that make moving files around fun again.

This repository builds Krusader into a **self-contained Docker image** that
boots a full Linux desktop in your browser via KasmVNC. You get:

- Krusader 2.8+ with the **Breeze Dark** theme pre-applied
- **Kate** wired up as the default external editor (also Breeze Dark)
- **Full archive support**: RAR (read & write via `unrar` + `rar`-compatible),
  7z, ZIP, TAR, GZ, BZ2, XZ, LHA, ARJ, ACE, RPM, CPIO
- **Right-click extras**: "Extract RAR here", "Extract RAR to subfolder",
  "Extract 7z here", "Open with Kate", "Open Konsole here"
- **Language dropdown** in the Unraid template — pick from 13 KDE-translated
  UIs (default: **German**); switch any time and restart the container
- **`/storage` volume** mapped to `/mnt` by default so all Unraid shares
  (`/mnt/user`) and individual disks (`/mnt/disk*`) are reachable from one
  place
- **First-run-only config seeding**: your customizations in `/config` survive
  every `docker pull`

---

## 2. Quick Start on Unraid

### Option A — Community Applications (recommended once published)

> CA submission is in progress. Until then, use Option B.

1. Open **Apps** → search for `Krusader`
2. Click **Install**
3. Adjust paths/ports if needed → **Apply**
4. Open the WebUI from the Docker tab → done

### Option B — Add as Custom Template

1. Unraid → **Docker** tab → **Add Container**
2. Set **Template** to:
   ```
   https://raw.githubusercontent.com/junkerderprovinz/krusader/main/unraid-template.xml
   ```
3. Adjust paths/ports/language → **Apply**
4. Open the WebUI from the Docker tab

### Option C — Plain `docker run`

```bash
docker run -d \
  --name krusader \
  --restart unless-stopped \
  --shm-size=1gb \
  -p 3000:3000 \
  -p 3001:3001 \
  -e PUID=99 \
  -e PGID=100 \
  -e TZ=Europe/Vienna \
  -e KRUSADER_LANG=de \
  -e KRUSADER_THEME=dark \
  -v /mnt/user/appdata/krusader:/config \
  -v /mnt:/storage \
  ghcr.io/junkerderprovinz/krusader:latest
```

Then open **http://your-unraid-ip:3000/**.

> 💡 **Tip:** `--shm-size=1gb` is required for smooth Chromium-based KDE
> rendering inside the desktop session. The Unraid template sets it for you.

---

## 3. Configuration Variables

| Variable | Default | Description |
|---|---|---|
| `PUID` | `99` | User ID inside the container (Unraid `nobody`) |
| `PGID` | `100` | Group ID inside the container (Unraid `users`) |
| `TZ` | `Etc/UTC` | Container timezone, e.g. `Europe/Vienna` |
| `KRUSADER_LANG` | `de` | UI language — see [§4](#4-languages) |
| `KRUSADER_THEME` | `dark` | `dark` (Breeze Dark) or `light` (Breeze) |
| `CUSTOM_USER` | `abc` | KasmVNC HTTP-basic-auth username |
| `PASSWORD` | *(empty)* | KasmVNC HTTP-basic-auth password — **set this if exposed beyond LAN** |
| `TITLE` | `Krusader` | Browser tab / KasmVNC top-bar title |

| Port | Purpose |
|---|---|
| `3000` | KasmVNC WebUI (HTTP) |
| `3001` | KasmVNC WebUI (HTTPS, self-signed) |

| Volume | Purpose |
|---|---|
| `/config` | Persistent Krusader / Kate / KDE configs, bookmarks, history |
| `/storage` | Files you actually want to manage (default: host `/mnt`) |

---

## 4. Languages

The Unraid template ships a **dropdown** for `KRUSADER_LANG` with the
following 13 KDE-translated UIs (plus `system` for the container default):

| Code | Language |
|---|---|
| `de` | Deutsch *(default)* |
| `en` | English |
| `fr` | Français |
| `es` | Español |
| `it` | Italiano |
| `nl` | Nederlands |
| `pl` | Polski |
| `pt` | Português |
| `ru` | Русский |
| `ja` | 日本語 |
| `zh` | 中文 (简体) |
| `tr` | Türkçe |
| `cs` | Čeština |

The corresponding `language-pack-kde-<code>` and `language-pack-<code>`
packages are baked into the image, so switching is instant — no extra
download. Change the variable, restart the container, done.

> **Why dropdown?** Unraid renders any `<Default>a|b|c</Default>` value with
> at least one `|` separator as a native `<select>` element. No guessing
> language codes.

---

## 5. Right-Click Actions

Krusader's *UserActions* are pre-loaded with five extras (right-click on a
file or selection in either panel):

| Action | What it does |
|---|---|
| **Extract RAR here** | `unrar x -o+` into the current directory |
| **Extract RAR to subfolder** | Same, but into a folder named like the archive |
| **Extract 7z here** | `7z x` into the current directory |
| **Open with Kate** | Opens the selected file(s) in Kate |
| **Open Konsole here** | New Konsole tab in the current directory |

Custom actions live in `/config/.local/share/krusader/useractions.xml` —
edit them via Krusader → *Settings* → *Configure UserActions* or directly on
disk.

---

## 6. Customization (configs survive updates)

On the **first start only**, the container copies a curated set of default
configs from `/defaults/` into `/config/`:

```
/config/
├── .config/
│   ├── kdeglobals          # KDE color scheme + Breeze Dark
│   ├── krusaderrc          # Editor=kate, theme, panel layout
│   └── katerc              # Kate Breeze Dark
└── .local/share/
    └── krusader/
        └── useractions.xml # right-click actions
```

A marker file `/config/.krusader-firstrun.done` is written so subsequent
container starts **never overwrite your customizations**. To re-seed defaults,
delete this marker and restart the container.

The two env-driven knobs (`KRUSADER_LANG`, `KRUSADER_THEME`) are re-applied
on **every** start via a tiny `cont-init.d` hook, so you can flip them freely.

### `custom-cont-init.d` hooks

The base image supports user-supplied init scripts dropped into
`/config/custom-cont-init.d/` — they run as `root` before KasmVNC starts.
Use them for installing extra packages, mounting CIFS shares, etc.
See the [LinuxServer docs](https://docs.linuxserver.io/general/container-customization/).

---

## 7. Building Locally

```bash
git clone https://github.com/junkerderprovinz/krusader.git
cd krusader

# amd64 only (fast, your local arch)
docker build -t krusader:dev .

# multi-arch (amd64 + arm64) – needs buildx
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t krusader:dev \
  --load .
```

Run your local build:

```bash
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

On Unraid: **Docker** tab → click the container → **Force Update**.
Your `/config` is untouched.

The image is rebuilt **weekly** via GitHub Actions, so you always get current
KDE / KasmVNC security patches without me lifting a finger.

---

## 9. Troubleshooting

### WebUI is black / desktop never appears
- Make sure you set `--shm-size=1gb` (or `--shm-size=512mb` minimum). The
  Unraid template does this automatically; plain `docker run` does not.
- Check the container log for KasmVNC startup errors.

### Right-click → "Extract RAR here" does nothing
- Open a Konsole inside the container and run `which unrar`. If empty,
  `apt list --installed 2>/dev/null | grep unrar` should show `unrar`.
  File an issue if it's missing — it's supposed to be baked in.

### Language change doesn't take effect
- Restart the container — language is applied at start, not live.
- Verify the env variable is one of the codes from [§4](#4-languages).
- The setting writes `LANG` and `LANGUAGE` into
  `/etc/profile.d/zz-krusader-lang.sh` on every start.

### Files outside `/storage` not visible
- That's by design. Map another path into the container if you need it,
  e.g. `-v /mnt/disks/somepool:/storage/somepool`.

### "Permission denied" on `/storage/...`
- Check `PUID` / `PGID`. On Unraid the defaults `99:100` (nobody:users)
  match share permissions. If you store files under a different user,
  align it.

### KasmVNC password not accepted
- The password is checked via HTTP basic auth — make sure your browser
  isn't caching old credentials. Open in a private window once.

---

## 10. Contributing / License

Pull requests welcome. Code is **GPL-3.0** (matching upstream Krusader).
Issues: <https://github.com/junkerderprovinz/krusader/issues>

Before submitting:

```bash
# Lints run in CI but you can run them locally
docker run --rm -i hadolint/hadolint < Dockerfile
docker run --rm -v "$PWD:/mnt" koalaman/shellcheck:stable rootfs/etc/cont-init.d/* rootfs/usr/local/bin/*
xmllint --noout unraid-template.xml ca_profile.xml
```

---

## 11. Credits

- [Krusader](https://krusader.org) — the actual file manager. Thank you,
  KDE community.
- [LinuxServer.io](https://www.linuxserver.io) — for the excellent
  [`baseimage-kasmvnc`](https://github.com/linuxserver/docker-baseimage-kasmvnc)
  this image is built on.
- [KasmVNC](https://github.com/kasmtech/KasmVNC) — for finally fixing
  remote-desktop-in-a-browser.
- [Kate](https://kate-editor.org) — best lightweight editor on Linux.
- Inspiration: binhex, jlesage and ich777 Krusader containers — they
  paved the way; this one just brings the WebUI into the 2020s.

---

<sub>Made for Unraid power-users who care about their desktop being
fast *and* dark. 🦘</sub>
