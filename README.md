<div align="center">

<a href="https://krusader.org">
  <img src="https://raw.githubusercontent.com/junkerderprovinz/krusader/main/.github/assets/krusader-banner.svg" alt="Krusader for Unraid" width="100%">
</a>

<br>

[![Build & Push](https://github.com/junkerderprovinz/krusader/actions/workflows/build.yml/badge.svg)](https://github.com/junkerderprovinz/krusader/actions/workflows/build.yml)
[![Lint](https://github.com/junkerderprovinz/krusader/actions/workflows/lint.yml/badge.svg)](https://github.com/junkerderprovinz/krusader/actions/workflows/lint.yml)
[![Image](https://img.shields.io/badge/image-ghcr.io%2Fjunkerderprovinz%2Fkrusader-1d99f3?style=flat-square)](https://ghcr.io/junkerderprovinz/krusader)
[![License](https://img.shields.io/badge/license-GPL--3.0-yellow?style=flat-square)](LICENSE)
[![KasmVNC](https://img.shields.io/badge/web%20stack-KasmVNC-1d99f3?style=flat-square)](https://github.com/kasmtech/KasmVNC)
[![Languages](https://img.shields.io/badge/languages-35-1d99f3?style=flat-square)](#-languages)

<br>

**A modern, plug-and-play Docker image for [Krusader](https://krusader.org) on Unraid.**
Twin-pane file management in your browser, with hardware-accelerated KasmVNC,
Breeze Dark, Kate, full archive support and 35 UI languages.

[**Install**](#-quick-start)&nbsp;·&nbsp;[**Features**](#-features)&nbsp;·&nbsp;[**Configuration**](#-configuration)&nbsp;·&nbsp;[**Languages**](#-languages)&nbsp;·&nbsp;[**Troubleshooting**](#-troubleshooting)

</div>

---

## ✨ Features

<table>
<tr>
<td width="33%" valign="top">

#### 🚀 Modern Web Stack
Built on **KasmVNC**, not noVNC. Hardware-accelerated rendering, real browser clipboard, native file upload/download, high-DPI ready.

</td>
<td width="33%" valign="top">

#### 🌑 Dark by Default
**Breeze Dark** pre-applied to Krusader, Kate and the whole KDE stack. Switch to light with one variable.

</td>
<td width="33%" valign="top">

#### 📦 Full Archive Support
**RAR**, 7z, ZIP, TAR, GZ, BZ2, XZ, LHA, ARJ, ACE, RPM, CPIO — all baked in. Right-click "Extract RAR here" works.

</td>
</tr>
<tr>
<td valign="top">

#### ✏️ Kate as Editor
**Kate** is wired up as Krusader's external editor — also Breeze Dark, with spell-check in 25+ languages.

</td>
<td valign="top">

#### 🌍 35 Languages
Pick your UI language from a **dropdown** in the Unraid template. Switch live, restart, done.

</td>
<td valign="top">

#### 🔁 Update-Safe Configs
First-run-only seeding. Your customisations in `/config` **survive every `docker pull`**.

</td>
</tr>
</table>

---

## 📊 Compared to other Krusader containers

| | **This image** | binhex | jlesage | ich777 |
|---|:---:|:---:|:---:|:---:|
| Web stack | **KasmVNC** | noVNC | noVNC | noVNC |
| HW-accelerated rendering | ✅ | ❌ | ❌ | ❌ |
| Browser clipboard | ✅ | ⚠️ | ⚠️ | ⚠️ |
| File upload via WebUI | ✅ | ❌ | ❌ | ❌ |
| Breeze Dark default | ✅ | ❌ | ❌ | ❌ |
| Kate as editor | ✅ | ❌ | ❌ | ❌ |
| RAR right-click | ✅ | ❌ | ❌ | ❌ |
| Language dropdown | ✅ (35) | ❌ | ❌ | ❌ |
| Multi-arch | ✅ amd64 + arm64 | amd64 | ✅ | amd64 |
| Base | LinuxServer | binhex/Arch | jlesage/Alpine | ich777/Debian |

---

## 🚀 Quick Start

<table>
<tr>
<td width="50%" valign="top">

### Option A — Unraid Template

1. **Docker** tab → **Add Container**
2. Paste this **Template URL**:
   ```
   https://raw.githubusercontent.com/junkerderprovinz/krusader/main/unraid-template.xml
   ```
3. Adjust paths / language / theme
4. **Apply** → open WebUI

</td>
<td width="50%" valign="top">

### Option B — Plain Docker

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

Open **http://your-unraid-ip:3000/**.

</td>
</tr>
</table>

> 💡 **`--shm-size=1gb`** is required for smooth KDE rendering. The Unraid template sets it for you.
> Once Community Applications has accepted this image, it will also be installable via **Apps** → search `Krusader`.

---

## ⚙️ Configuration

<table>
<tr><th align="left">Variable</th><th align="left">Default</th><th align="left">Description</th></tr>
<tr><td><code>PUID</code></td><td><code>99</code></td><td>User ID — Unraid's <em>nobody</em></td></tr>
<tr><td><code>PGID</code></td><td><code>100</code></td><td>Group ID — Unraid's <em>users</em></td></tr>
<tr><td><code>TZ</code></td><td><code>Etc/UTC</code></td><td>Timezone, e.g. <code>Europe/Vienna</code></td></tr>
<tr><td><code>KRUSADER_LANG</code></td><td><code>de</code></td><td>UI language — <a href="#-languages">35 codes available</a></td></tr>
<tr><td><code>KRUSADER_THEME</code></td><td><code>dark</code></td><td><code>dark</code> (Breeze Dark) or <code>light</code> (Breeze)</td></tr>
<tr><td><code>CUSTOM_USER</code></td><td><code>abc</code></td><td>KasmVNC HTTP-basic-auth username</td></tr>
<tr><td><code>PASSWORD</code></td><td><em>(empty)</em></td><td>KasmVNC password — <strong>set this if exposed beyond LAN</strong></td></tr>
<tr><td><code>TITLE</code></td><td><code>Krusader</code></td><td>Browser tab / KasmVNC top-bar title</td></tr>
</table>

#### Ports & Volumes

| Port | Purpose | | Volume | Purpose |
|---|---|---|---|---|
| `3000` | KasmVNC HTTP | | `/config` | Persistent KDE / Krusader / Kate configs |
| `3001` | KasmVNC HTTPS *(self-signed)* | | `/storage` | Files to manage — default host `/mnt` |

---

## 🌍 Languages

The Unraid template ships a **dropdown** with **35 UI languages** (German default, plus `system` fallback).
Each language has its `language-pack-<code>` and `language-pack-kde-<code>` baked in — switching is instant.

<table>
<tr>
<td width="25%" valign="top">

**Western Europe**
- 🇩🇪 `de` — Deutsch *(default)*
- 🇬🇧 `en` — English (US)
- 🇬🇧 `en_GB` — English (UK)
- 🇫🇷 `fr` — Français
- 🇪🇸 `es` — Español
- 🇮🇹 `it` — Italiano
- 🇵🇹 `pt` — Português
- 🇧🇷 `pt_BR` — Português (BR)
- 🇳🇱 `nl` — Nederlands
- 🇪🇸 `ca` — Català
- 🇪🇸 `eu` — Euskara
- 🇮🇪 `ga` — Gaeilge

</td>
<td width="25%" valign="top">

**Northern Europe**
- 🇩🇰 `da` — Dansk
- 🇸🇪 `sv` — Svenska
- 🇳🇴 `nb` — Norsk Bokmål
- 🇫🇮 `fi` — Suomi
- 🇮🇸 `is` — Íslenska

**Middle East**
- 🇹🇷 `tr` — Türkçe
- 🇮🇱 `he` — עברית
- 🇸🇦 `ar` — العربية

</td>
<td width="25%" valign="top">

**Central / Eastern Europe**
- 🇵🇱 `pl` — Polski
- 🇨🇿 `cs` — Čeština
- 🇸🇰 `sk` — Slovenčina
- 🇭🇺 `hu` — Magyar
- 🇷🇴 `ro` — Română
- 🇸🇮 `sl` — Slovenščina
- 🇭🇷 `hr` — Hrvatski
- 🇷🇸 `sr` — Српски
- 🇧🇬 `bg` — Български
- 🇺🇦 `uk` — Українська
- 🇷🇺 `ru` — Русский
- 🇬🇷 `el` — Ελληνικά

</td>
<td width="25%" valign="top">

**Asia / CJK**
- 🇯🇵 `ja` — 日本語
- 🇰🇷 `ko` — 한국어
- 🇨🇳 `zh` — 中文 (简体)
- 🇹🇼 `zh_TW` — 中文 (繁體)

**System**
- `system` — container default

</td>
</tr>
</table>

> **How it works:** Unraid renders any `<Default>a|b|c</Default>` value with at least one `|`
> as a native `<select>` dropdown. The cont-init hook re-applies the language on every start.

---

## 🖱️ Right-Click Actions

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

## 🛡️ Customisation (your configs survive updates)

On the **first start only**, the container seeds defaults from `/defaults/` into `/config/`:

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
container starts **never overwrite your customisations**.
To re-seed defaults, delete the marker and restart.

The two env-driven knobs (`KRUSADER_LANG`, `KRUSADER_THEME`) are re-applied
on **every** start via a `cont-init.d` hook, so you can flip them freely.

The base image also supports **`/config/custom-cont-init.d/`** for your own
init scripts — see the [LinuxServer docs](https://docs.linuxserver.io/general/container-customization/).

---

## 🛠️ Build Locally

```bash
git clone https://github.com/junkerderprovinz/krusader.git
cd krusader

# amd64 only (your local arch)
docker build -t krusader:dev .

# Multi-arch (amd64 + arm64) – needs buildx
docker buildx build --platform linux/amd64,linux/arm64 -t krusader:dev --load .
```

```bash
docker run --rm -it \
  -p 3000:3000 \
  -v "$PWD/.dev-config:/config" \
  -v "$PWD:/storage" \
  krusader:dev
```

---

## 🔄 Updating

```bash
docker pull ghcr.io/junkerderprovinz/krusader:latest
docker stop krusader && docker rm krusader
# re-create with the same template / docker run args
```

On Unraid: **Docker** tab → click the container → **Force Update**.
Your `/config` is untouched.

> Image is rebuilt **weekly** via GitHub Actions for upstream KasmVNC / Ubuntu / KDE patches.

---

## 🧯 Troubleshooting

<details>
<summary><b>WebUI is black / desktop never appears</b></summary>

- Make sure `--shm-size` is at least `512mb` (Unraid template sets `1gb`).
- Check the container log for KasmVNC startup errors.
- Try opening on `https://your-ip:3001/` (self-signed) — sometimes browsers block ws over plain http.
</details>

<details>
<summary><b>Right-click "Extract RAR here" does nothing</b></summary>

- Open a Konsole inside the container: `which unrar` should print `/usr/bin/unrar`.
- If empty: file an issue — `unrar` is supposed to be baked in from the multiverse repo.
</details>

<details>
<summary><b>Language change doesn't take effect</b></summary>

- Restart the container — language is applied at start, not live.
- Check the env variable matches a code from [§ Languages](#-languages).
- The script writes `/etc/profile.d/zz-krusader-lang.sh` and updates `kdeglobals[Translations]`.
</details>

<details>
<summary><b>Files outside /storage not visible</b></summary>

- That's by design. Map another path into the container:
  `-v /mnt/disks/somepool:/storage/somepool`
</details>

<details>
<summary><b>"Permission denied" on /storage/...</b></summary>

- Check `PUID` / `PGID`. On Unraid, `99:100` (nobody:users) match share permissions.
- If you store files under a different user, align it.
</details>

<details>
<summary><b>KasmVNC password not accepted</b></summary>

- Open in a private window once — your browser may have cached old credentials.
</details>

---

## 🧱 Architecture

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

## 🤝 Contributing & License

Pull requests welcome. Code is **GPL-3.0** (matching upstream Krusader).
Issues: <https://github.com/junkerderprovinz/krusader/issues>

```bash
# Run lints locally (CI runs them too)
docker run --rm -i hadolint/hadolint < Dockerfile
docker run --rm -v "$PWD:/mnt" koalaman/shellcheck:stable rootfs/etc/cont-init.d/* rootfs/usr/local/bin/*
xmllint --noout unraid-template.xml ca_profile.xml
```

---

## 🙏 Credits

- [**Krusader**](https://krusader.org) — KDE community, the actual file manager
- [**LinuxServer.io**](https://www.linuxserver.io) — for the excellent [`baseimage-kasmvnc`](https://github.com/linuxserver/docker-baseimage-kasmvnc)
- [**KasmVNC**](https://github.com/kasmtech/KasmVNC) — for finally fixing remote-desktop-in-a-browser
- [**Kate**](https://kate-editor.org) — best lightweight editor on Linux
- Inspiration: binhex, jlesage and ich777 Krusader containers — they paved the way

<div align="center">

<sub>Made with 🦘 for Unraid power-users who like their desktops fast <em>and</em> dark.</sub>

</div>
