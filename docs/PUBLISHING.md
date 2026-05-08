# Veröffentlichung in Community Applications (CA)

Diese Anleitung beschreibt den vollständigen Prozess, vom GitHub-Repo bis zum
Eintrag in der Unraid-CA.

## 0. Voraussetzungen

- GitHub-Account
- Docker-Hub-Account *(optional, GHCR reicht)*
- Unraid-Forum-Account
- Funktionierendes Image, das auf Unraid getestet wurde

## 1. Repo auf GitHub anlegen

```bash
cd krusader-unraid
git init -b main
git add .
git commit -m "Initial commit: Krusader Unraid community edition"
git remote add origin git@github.com:<dein-user>/krusader-unraid.git
git push -u origin main
```

Anschließend in **allen Dateien** den Platzhalter `REPLACE_ME` durch deinen
GitHub-Username ersetzen:

```bash
grep -rl REPLACE_ME . | xargs sed -i 's/REPLACE_ME/<dein-user>/g'
git commit -am "Set repository owner"
git push
```

> Betroffen sind: `Dockerfile`, `README.md`, `unraid-template/krusader-unraid.xml`,
> Workflow-Dateien.

## 2. GHCR-Push einrichten

`ghcr.io` funktioniert ohne Zusatz-Konfiguration, sobald Actions Schreib-
zugriff auf Packages hat:

1. Repo → **Settings → Actions → General → Workflow permissions**
2. Auf **„Read and write permissions"** stellen.
3. Erstes Build manuell triggern: **Actions → build-and-publish → Run workflow**.
4. Nach Erfolg: Repo → **Packages** → das Image `krusader-unraid` öffnen
   → **Package settings → Change visibility → Public**.

### (Optional) Docker Hub zusätzlich

In den Repo-**Secrets** anlegen:

| Secret | Wert |
|---|---|
| `DOCKERHUB_USER` | dein Docker-Hub-Username |
| `DOCKERHUB_TOKEN` | Access-Token aus Docker-Hub |

Der Workflow pusht dann automatisch zusätzlich nach Docker Hub.

## 3. Container-Icon hinzufügen

Lege ein 128×128 (oder 256×256) PNG unter `unraid-template/icon.png` ab und
committe es:

```bash
cp ~/Downloads/krusader-icon.png unraid-template/icon.png
git add unraid-template/icon.png
git commit -m "Add container icon"
git push
```

## 4. Lokal auf Unraid testen

1. Image manuell pullen via SSH:
   ```bash
   docker pull ghcr.io/<dein-user>/krusader-unraid:latest
   ```
2. In der Unraid-WebGUI **Docker → Add Container**, **„Template"** unten
   auf den GitHub-Raw-Link der XML setzen:
   `https://raw.githubusercontent.com/<dein-user>/krusader-unraid/main/unraid-template/krusader-unraid.xml`
3. Apply, WebUI öffnen, Dark Mode + deutsche Sprache + Rar-Rechtsklick prüfen.
4. Iterieren, bis alles passt.

## 5. Support-Thread im Unraid-Forum

CA verlangt einen aktiven Support-Thread.

1. Forum → **Community Applications → Docker Containers** (Subforum):
   <https://forums.unraid.net/forum/55-docker-containers/>
2. Thread-Titel: `[Support] <dein-user>/krusader-unraid – Krusader mit Dark Mode, Kate, RAR`
3. Im Post: kurze Beschreibung, Link zu Repo + GHCR + Screenshots.
4. Thread-URL kopieren und in `unraid-template/krusader-unraid.xml`
   im `<Support>`-Tag eintragen, dann committen.

## 6. CA-Submission

CA benötigt eine **Templates-Repo-URL** mit gültiger Struktur.

### Variante A: eigenes Templates-Repo

Lege ein zweites Repo `<dein-user>/unraid-templates` an, mit Struktur:

```
unraid-templates/
└── krusader-unraid/
    └── krusader-unraid.xml
```

(Du kannst dieses Repo später für weitere Templates nutzen.)

### Variante B: dasselbe Repo nutzen

Mache aus diesem Repo ein offizielles Template-Repo, indem du die XML auf
Top-Level-Ebene zugänglich machst (CA akzeptiert Templates aus
beliebigen Pfaden, solange sie korrekt sind).

### Submission

1. Öffne die CA-Submission-Form: <https://forums.unraid.net/topic/87144-ca-application-policies-please-read/>
   *(im Pinned-Post sind die aktuellen Submission-Links)*.
2. Trage ein:
   - **Repository URL** des Templates-Repos
   - **Support-Thread-URL**
   - **Image-Repository** (`ghcr.io/<dein-user>/krusader-unraid`)
3. Submit. Reviewer melden sich i.d.R. innerhalb von 48 Stunden im Thread.

## 7. Updates / Wartung

- Der GitHub-Actions-Workflow rebuilt **wöchentlich** gegen das aktuelle
  `binhex/arch-krusader:latest`. So bleiben Krusader & Kate aktuell, ohne
  dass du etwas tun musst.
- Bei größeren Änderungen am Dockerfile oder den Defaults: neuen Git-Tag
  setzen (`git tag v1.1.0 && git push --tags`) – der Workflow erzeugt dann
  passende SemVer-Tags auf GHCR.
- Im Support-Thread Changelogs posten – das hilft der Community und ist
  Voraussetzung für CA-Compliance.

## Checkliste vor dem ersten Submit

- [ ] `REPLACE_ME` überall ersetzt
- [ ] `unraid-template/icon.png` hinzugefügt
- [ ] Image auf GHCR public gepusht
- [ ] Lokaler Test auf Unraid erfolgreich (Dark Mode, Kate, RAR-Rechtsklick, Sprache)
- [ ] Support-Thread im Unraid-Forum erstellt
- [ ] `<Support>`-URL im Template eingetragen
- [ ] CA-Submission ausgefüllt
