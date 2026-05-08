# krusader-unraid

> Krusader für Unraid – Community Edition.
> Dark Mode out of the box, Kate als Editor, RAR/7z-Support per Rechtsklick, deutsche Lokalisierung.

[![Build](https://github.com/REPLACE_ME/krusader-unraid/actions/workflows/build.yml/badge.svg)](https://github.com/REPLACE_ME/krusader-unraid/actions/workflows/build.yml)
[![GHCR](https://img.shields.io/badge/ghcr.io-krusader--unraid-blue)](https://ghcr.io/REPLACE_ME/krusader-unraid)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL_3.0-yellow.svg)](LICENSE)

---

## Features

| Feature | Status |
|---|---|
| 🎨 Breeze **Dark Mode** für Krusader und Kate | ✅ Default |
| ✏️ **Kate** als externer Editor (mit Syntax-Highlighting & Spell-Check) | ✅ |
| 📦 **RAR**-Entpacken per Rechtsklick (Hier / Unterordner) | ✅ |
| 📦 **7z, ZIP, TAR, GZ, BZ2, LHA, ARJ, ACE** | ✅ |
| 🇩🇪 Deutsche UI (umschaltbar via ENV) | ✅ |
| 🇬🇧 Englisch / beliebiger ISO-Code als Alternative | ✅ |
| 🌐 noVNC-WebUI (kein lokales X nötig) | ✅ |
| 🔄 Wöchentlicher Auto-Rebuild gegen aktuelles Upstream | ✅ |

## Schnellstart auf Unraid

1. **Apps**-Tab → suche nach `krusader-unraid` (sobald in Community Applications gelistet).
2. Pfade prüfen:
   - `/config` → `/mnt/user/appdata/krusader-unraid`
   - `/storage` → `/mnt`  *(Default; gibt Zugriff auf alle Shares + Disks)*
3. **VNC_PASSWORD** setzen (mindestens 6 Zeichen empfohlen).
4. Apply → WebUI über `http://<unraid-ip>:6080` öffnen.

### Manuell via `docker run`

```bash
docker run -d \
  --name=krusader \
  --privileged \
  -p 6080:6080 -p 5900:5900 \
  -v /mnt/user/appdata/krusader-unraid:/config \
  -v /mnt:/storage:rw,slave \
  -v /etc/localtime:/etc/localtime:ro \
  -e KRUSADER_LANG=de \
  -e KRUSADER_THEME=dark \
  -e VNC_PASSWORD=changeme \
  -e PUID=99 -e PGID=100 -e UMASK=000 \
  ghcr.io/REPLACE_ME/krusader-unraid:latest
```

## Konfiguration

| ENV | Default | Beschreibung |
|---|---|---|
| `KRUSADER_LANG` | `de` | UI-Sprache. Werte: `de`, `en`, `system`, oder ISO-Codes wie `fr`, `es`, `it`. Greift bei jedem Start. |
| `KRUSADER_THEME` | `dark` | `dark` = Breeze Dark, `light` = Breeze. |
| `VNC_PASSWORD` | – | noVNC/VNC-Passwort. Min. 6 Zeichen. |
| `WEBPAGE_TITLE` | `Krusader` | Browser-Tab-Titel. |
| `TEMP_FOLDER` | `/config/krusader/tmp` | Temp-Pfad für Archive. |
| `ENABLE_STARTUP_SCRIPTS` | `no` | Aktiviert binhex-Mechanismus für `/config/home/scripts/*.sh`. |
| `PUID` / `PGID` / `UMASK` | `99` / `100` / `000` | Standard-Unraid-Permissions. |

## Anpassungen

Beim **ersten Start** legt der Container Default-Configs an, **falls sie noch nicht existieren**:

| Datei | Zweck |
|---|---|
| `/config/home/.config/kdeglobals` | Theme, Color Scheme, Sprach-Override |
| `/config/home/.config/krusaderrc` | Krusader-Verhalten, Editor=`kate` |
| `/config/home/.config/katerc` | Kate-Settings inkl. Breeze-Dark-Schema |
| `/config/home/.local/share/krusader/useractions.xml` | Rechtsklick-Aktionen (RAR-Entpacken, „Mit Kate öffnen", Konsole hier) |

Eigene Anpassungen an diesen Dateien überleben jedes Container-Update – das Setup-Skript überschreibt **nichts**, was du selbst bearbeitet hast.

### Eigene UserActions ergänzen

Bearbeite `/config/home/.local/share/krusader/useractions.xml` direkt aus Krusader heraus oder per Texteditor. Krusader lädt sie beim nächsten Start automatisch.

## Build lokal

```bash
git clone https://github.com/REPLACE_ME/krusader-unraid.git
cd krusader-unraid
docker build -t krusader-unraid:dev .
```

## Beitragen

Issues und Pull Requests sind willkommen – bitte vorher kurz im Unraid-Forum-Thread posten, damit klar ist, wer woran arbeitet.

## Lizenz

GPL-3.0 (folgt der Lizenz von [binhex/arch-krusader](https://github.com/binhex/arch-krusader)).

## Credits

- [binhex](https://github.com/binhex) – Base-Image `arch-krusader`
- [Krusader-Team](https://krusader.org/)
- [KDE-Community](https://kde.org/) – Kate, Breeze
