# Publishing Checklist — Krusader for Unraid

Internal notes for getting this image listed on Unraid Community Applications.
**Not** part of the user-facing docs.

## 0. Repo state

- [ ] Repo is **public** (CA crawler can't see private repos)
- [ ] GHCR image `ghcr.io/junkerderprovinz/krusader:latest` is **public**
      (Settings → Packages → krusader → Change visibility)
- [ ] First successful build run completed (green Build & Push action)
- [ ] First successful lint run completed (green Lint action)

## 1. Forum thread

CA requires a support thread on the Unraid forums.

1. Create a thread in **Community Applications → Docker Containers (User)**:
   <https://forums.unraid.net/forum/61-docker-containers-user/>
2. Title suggestion: `[Support] junkerderprovinz - Krusader (KasmVNC)`
3. First post should include: short description, image link, GitHub link,
   screenshot, basic config notes.
4. Copy the thread URL.

## 2. Update template Support URL

Replace the placeholder in `unraid-template.xml`:

```xml
<Support>https://forums.unraid.net/topic/REPLACE_WITH_FORUM_THREAD/</Support>
```

→ commit + push.

## 3. Submit to CA

1. Fork <https://github.com/Squidly271/AppFeed>
2. Add an entry to `templates.xml` pointing to your raw `unraid-template.xml`:
   ```
   https://raw.githubusercontent.com/junkerderprovinz/krusader/main/unraid-template.xml
   ```
3. Open a PR. Squid (CA maintainer) reviews — usually within a few days.
4. Once merged, the container shows up in Apps for everyone.

## 4. Optional — DockerHub mirror

If you want broader reach, mirror the image to Docker Hub too:

```bash
docker pull ghcr.io/junkerderprovinz/krusader:latest
docker tag ghcr.io/junkerderprovinz/krusader:latest junkerderprovinz/krusader:latest
docker push junkerderprovinz/krusader:latest
```

(Or extend `.github/workflows/build.yml` to push to both registries.)

## 5. Maintenance

- Weekly cron in `build.yml` already rebuilds for upstream KasmVNC / Ubuntu
  patches.
- Watch upstream Krusader releases: <https://krusader.org/get-krusader/>
  Major version bumps may require config tweaks under `rootfs/defaults/`.
- Keep `language-pack-*` package list in sync with the dropdown in
  `unraid-template.xml`.
