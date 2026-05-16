# Krusader for Unraid — Known Issues & Fix Roadmap

This document collects the **persistent, non-trivial bugs** discovered while
hardening the container that **were not fixed in v1.0.x** because they require
either a bigger image overhaul or upstream behavioural changes. It is meant as
a hand-off note so that future-me (or contributors) can pick up where the
current code left off without re-deriving the root cause from zero.

For day-to-day usage issues (port collisions, KasmVNC certificates, language
not switching after a UI change, locale fallback, …) see **Section 9. Troubleshooting**
in the main [`README.md`](README.md).

---

## Table of Contents

1. [Quick status table](#quick-status-table)
2. [Bug #1 — UI state is not persisted across `Quit`](#bug-1--ui-state-is-not-persisted-across-quit)
3. [Bug #2 — Kate opens maximised, window-`X` freezes the editor](#bug-2--kate-opens-maximised-window-x-freezes-the-editor)
4. [Bug #3 — Krusader window comes back small after a restart](#bug-3--krusader-window-comes-back-small-after-a-restart)
5. [Bug #4 — Template `KRUSADER_LANG` is ignored by the running app](#bug-4--template-krusader_lang-is-ignored-by-the-running-app)
6. [Architectural background — why a session manager is the real fix](#architectural-background--why-a-session-manager-is-the-real-fix)
7. [Suggested order of attack](#suggested-order-of-attack)
8. [Useful debug commands inside the container](#useful-debug-commands-inside-the-container)

---

## Quick status table

| # | Bug | User-visible symptom | Root cause (current best guess) | Estimated effort to fix | Sketched fix |
|---|---|---|---|---|---|
| 1 | UI state not persisted | After `File → Quit` and a fresh container start, status-bar visibility, panel widths, last directory and window geometry come back at defaults | The KasmVNC X-session has **no KDE session manager** (`ksmserver`). Qt's `saveWindowState()` writes nothing because no session-save signal is emitted at shutdown. The idempotent `krusaderrc` key injector in `cont-init.d` only sets *initial* keys, it doesn't observe runtime changes. | 30–60 min debug cycles, ~150–200 MB image growth | Add `plasma-workspace-bin` (or the minimal `ksmserver` package on the LSIO baseimage's apt source), spin up a new `s6` service `init-ksmserver` that starts `ksmserver` after dbus and before Krusader, and have the Krusader startup wrapper inherit `SESSION_MANAGER`. |
| 2 | Kate opens maximised + the window `X` freezes Kate (only `Ctrl+Q` exits cleanly) | Kate fills the whole KasmVNC viewport on launch, and clicking the close decoration hangs the GUI for ~10 s before the process is killed. | Same as #1 — without `ksmserver`, Kate's close-event over D-Bus is not routed to its `closeSlot()`, so it falls through to the window-manager kill path. Maximise-on-launch is the openbox default (no `<application>` rule restricting it). | Free once #1 is fixed (same `ksmserver` work) + a 5-line openbox `<application class="kate">` rule | Together with the session-manager work, add an openbox application rule in `rootfs/defaults/openbox-rc.xml` to set `<maximized>no</maximized>` and a saved geometry for `class="kate"`. |
| 3 | Krusader window comes back small (≈ 800×600), not maximised, after a container restart | The window starts at openbox' default size rather than full viewport | Side-effect of the openbox `rc.xml` clean-up in commit `4a4e15e` — the upstream-118-mousebind file ships an **empty** `<applications/>` block, so the "force maximise" rule the original PR had is gone. With `ksmserver` missing too, there is no saved geometry to restore, so nothing fills the gap. | 1 edit, no new package | Add an openbox application rule scoped to `class="krusader"` in `rootfs/defaults/openbox-rc.xml`: `<application class="krusader"><maximized>yes</maximized></application>`. Optional once #1 is fixed (`ksmserver` will restore the real geometry). |
| 4 | **NEW (v1.0.x):** Template `KRUSADER_LANG` is ignored | User picks e.g. `de` in the Unraid template, hits Apply, reopens the web-UI — Krusader still comes up in English. | The init helper `rootfs/etc/cont-init.d/30-krusader-language.sh` (a.k.a. `krusader-language.sh`) **does run** at container start, but its `sed` does not actually touch the `[Language]` section in `~/.config/krusaderrc` when the file is missing or freshly created — and on second start it sees the file already present and skips. The runtime locale (`LANG`, `LC_ALL`) is also not forced to match `KRUSADER_LANG`, so KDE's i18n picks the system default (`en_US.UTF-8`). | 30 min, no new package | (a) Make the helper **idempotent and authoritative**: ensure `[Language]` section exists, then upsert `Language=$KRUSADER_LANG`. (b) When `KRUSADER_LANG` is set, also export `LANG=${KRUSADER_LANG}.UTF-8` and `LC_ALL=${KRUSADER_LANG}.UTF-8` via `/etc/cont-init.d/30-krusader-language.sh` (write `/etc/locale.conf` plus a profile drop-in `/etc/profile.d/krusader-lang.sh`). (c) Verify the locale is actually generated in the LSIO image; if not, run `locale-gen ${KRUSADER_LANG}.UTF-8` once. |

---

## Bug #1 — UI state is not persisted across `Quit`

### Symptom

1. Start the container, open the web-UI.
2. Drag the status bar off, resize a panel column, switch to "Detailed view",
   `cd` somewhere deep, close the second panel — anything visible.
3. `File → Quit` (or hit the X) → wait for KasmVNC to show "Session ended".
4. Stop the container, start it again, reopen the web-UI.

→ Everything is back at defaults. None of the runtime changes were saved.

### Why

Krusader uses Qt's `KMainWindow::saveAutoSaveSettings()` / `saveWindowState()` machinery,
which **requires** a KDE session manager (`ksmserver`) listening on the X
display. When `ksmserver` is missing, the application receives no
`saveYourself()` signal from the session manager at shutdown, so the state
group in `~/.config/krusaderrc` never gets rewritten.

The current image has none of:

- `ksmserver` binary
- the `SESSION_MANAGER` env variable
- a DBus name `org.kde.ksmserver`

The idempotent key injector at `rootfs/etc/cont-init.d/30-krusader-keys.sh`
(introduced in commit `3f2ed7c`) **does** seed sensible startup defaults, but
it only fires at container start — it cannot observe what the user does in the
live session, and it is not a substitute for `saveWindowState()`.

### Fix sketch

1. **Add `ksmserver`** to the image. On the LSIO KasmVNC baseimage (Ubuntu/Debian-based),
   the smallest path is to install `plasma-workspace` (~150 MB) or — if available — a
   trimmed `ksmserver` and its hard deps. Avoid `plasma-desktop`, it pulls in too much.

   In `Dockerfile`, in the existing apt-install layer:
   ```dockerfile
   RUN apt-get update && apt-get install -y --no-install-recommends \
         krusader kate \
         plasma-workspace \
         dbus-x11 \
         # ... existing packages
       && rm -rf /var/lib/apt/lists/*
   ```

2. **New s6 oneshot** `rootfs/etc/s6-overlay/s6-rc.d/init-ksmserver/`:
   - `type` = `oneshot`
   - `up`   = `/etc/s6-overlay/s6-rc.d/init-ksmserver/run` (starts `ksmserver` in the
     background after the dbus session is up)
   - Add it to the `user/contents.d/` directory and make `init-krusader` (or whatever
     the openbox/Krusader run script is called) depend on it.

3. **Export `SESSION_MANAGER`** in the Krusader wrapper (`rootfs/usr/local/bin/start-krusader`
   or wherever the entry script lives), so Qt actually finds the session bus:
   ```bash
   export $(dbus-launch)
   ksmserver &
   export SESSION_MANAGER="local/$(hostname):@/tmp/.ICE-unix/$$"
   exec krusader
   ```

4. **Verification**:
   - In the running container: `pgrep -af ksmserver` shows one process.
   - `qdbus org.kde.ksmserver /KSMServer logout 0 0 0` triggers a clean exit
     and `~/.config/krusaderrc` gains a `[$State]` group or window-geometry
     keys.
   - After a container restart, the saved geometry is restored.

### Trade-off

`plasma-workspace` is the most expensive line item, image-size-wise. If size
matters more than perfect UI persistence, an acceptable workaround is to keep
expanding the idempotent key injector with the keys users care about most
(`ToolBar`, `Geometry`, `Show menubar`, …) and document the limitation. This is
what v1.0.x does today.

---

## Bug #2 — Kate opens maximised, window-`X` freezes the editor

### Symptom

- Right-click any text file in Krusader → `Open with Kate`.
- Kate launches **maximised** to the full KasmVNC viewport, ignoring the
  multi-window layout.
- Clicking the title-bar `X` makes Kate go grey for ~10 s, then the process is
  SIGKILL'd. **`Ctrl+Q` (or `File → Quit`) closes cleanly.**

### Why

- The maximise-on-launch is openbox' default behaviour because the cleaned-up
  `rootfs/defaults/openbox-rc.xml` has an empty `<applications/>` block (we
  removed the over-eager "force maximize everything" rule). Kate doesn't ship
  its own default geometry, so openbox stretches it.
- The window-X freeze is — same root cause as Bug #1 — the absence of
  `ksmserver`. Kate's D-Bus `closeMainWindow()` slot is never reached because
  the window manager's close event is not relayed through a session bus that
  knows about the Kate instance. `Ctrl+Q` works because it goes through Kate's
  own internal action, not through the WM.

### Fix sketch

This bug **disappears entirely** once Bug #1 is fixed (the same `ksmserver`
work also makes Kate's close-event route correctly).

For the maximise issue alone, add to `rootfs/defaults/openbox-rc.xml`:
```xml
<applications>
  <application class="kate">
    <maximized>no</maximized>
    <position force="no">
      <x>center</x>
      <y>center</y>
    </position>
    <size>
      <width>1100</width>
      <height>750</height>
    </size>
  </application>
</applications>
```
Keep the empty `<applications/>` if you've not fixed Bug #1 yet — the rule is
purely cosmetic until then.

---

## Bug #3 — Krusader window comes back small after a restart

### Symptom

After a container restart, Krusader's window comes back at ~800×600 in the
top-left, not filling the viewport.

### Why

Side-effect of replacing the original `rc.xml` (which did "force-maximise
everything") with the upstream openbox 118-mousebind reference file in commit
`4a4e15e`. The reference file has an **empty** `<applications/>` block, so
there's no maximise rule at all. Combined with Bug #1 (no `ksmserver` to
restore the saved geometry), the result is "default openbox size".

### Fix sketch

Scoped maximise rule for the Krusader window class — add inside
`<applications>` in `rootfs/defaults/openbox-rc.xml`:
```xml
<application class="krusader">
  <maximized>yes</maximized>
</application>
```
This is **safe even with Bug #1 unfixed** (no other window class is touched).

Once Bug #1 is fixed, the rule becomes redundant because `ksmserver` will
restore the real geometry, but it's harmless to keep.

---

## Bug #4 — Template `KRUSADER_LANG` is ignored by the running app

### Symptom

1. In the Unraid template, change **Language** from `en` to e.g. `de`.
2. Hit **Apply** — the container restarts.
3. Open the web-UI → Krusader still comes up in English. The Settings → Language
   menu also still shows "English".

### Why (current best guess)

The init helper `rootfs/etc/cont-init.d/30-krusader-language.sh` runs at every
start, but its `sed` writes to `~/.config/krusaderrc` only when the
`[Language]` group already exists and contains a `Language=` key. On a fresh
config dir (first start, or a wiped `appdata`), Krusader will create that file
itself on first run — *after* the helper has already finished — so the new
language never takes effect.

Additionally, even if `Language=de` is set in `krusaderrc`, KDE/KF5 i18n
respects the **process locale** (`LANG`, `LC_ALL`, `LC_MESSAGES`). The current
image keeps `LANG=en_US.UTF-8` (the LSIO baseimage default), so even with a
correct `krusaderrc`, Krusader's catalogs fall back to English.

### Fix sketch

In `rootfs/etc/cont-init.d/30-krusader-language.sh`, do **all three** of:

1. **Ensure the `[Language]` section exists**, then `upsert` the key.
   Pseudo-code (POSIX sh / awk):
   ```sh
   conf="/config/.config/krusaderrc"
   mkdir -p "$(dirname "$conf")"
   touch "$conf"
   lang="${KRUSADER_LANG:-en}"

   if ! grep -q '^\[Language\]' "$conf"; then
     printf '\n[Language]\nLanguage=%s\n' "$lang" >> "$conf"
   elif grep -q '^Language=' "$conf"; then
     # in-section replace, awk-driven so we don't accidentally touch other [..] groups
     awk -v new="$lang" '
       /^\[/ { section=$0 }
       section=="[Language]" && /^Language=/ { print "Language=" new; next }
       { print }
     ' "$conf" > "$conf.tmp" && mv "$conf.tmp" "$conf"
   else
     # section present but key missing — append after [Language] header
     awk -v new="$lang" '
       { print }
       $0 == "[Language]" { print "Language=" new }
     ' "$conf" > "$conf.tmp" && mv "$conf.tmp" "$conf"
   fi
   chown abc:abc "$conf"
   ```

2. **Force the process locale to match**. Write a profile drop-in that the s6
   service environment will inherit:
   ```sh
   cat > /etc/profile.d/zz-krusader-lang.sh <<EOF
   export LANG=${lang}.UTF-8
   export LC_ALL=${lang}.UTF-8
   export LANGUAGE=${lang}
   EOF
   ```
   And export the same in the wrapper that actually starts Krusader, so the
   D-Bus child gets it even if /etc/profile is not sourced.

3. **Make sure the locale is generated.** On Debian-derived LSIO images:
   ```sh
   if ! locale -a | grep -qi "^${lang}_..*\.utf8$"; then
     sed -i "s/^# *\(${lang}_..*\.UTF-8\)/\1/" /etc/locale.gen 2>/dev/null || true
     echo "${lang}.UTF-8 UTF-8" >> /etc/locale.gen
     locale-gen "${lang}.UTF-8" 2>/dev/null || true
   fi
   ```
   This is cheap (a few KB of catalogs) and idempotent.

### Verification

```bash
# inside the container after a `de` switch
grep -A1 '^\[Language\]' /config/.config/krusaderrc   # → Language=de
locale                                                # → LANG=de_DE.UTF-8
pgrep -af krusader | xargs -r -n1 cat /proc/*/environ 2>/dev/null | tr '\0' '\n' | grep -i ^LANG=
```

Then refresh the KasmVNC tab → Krusader should come up in the chosen language
and the Settings → Language picker should reflect it.

### Related but already-fixed

Section 9 of the README already documents the "change Settings → Language in
the GUI doesn't stick" case — that one **is** caused by Bug #1, because the
runtime UI change is never written back. The Unraid-template path described
here is a **separate code path** (env var → init script → config file), which
should work even without `ksmserver`.

---

## Architectural background — why a session manager is the real fix

`baseimage-kasmvnc` boots `Xvnc + openbox + (optional) noVNC/KasmVNC web frontend`
plus a single user application. It deliberately ships **no** desktop
environment. That's perfect for "single-app web wrappers" like Firefox or
Audacity, where neither the app nor the user expects a multi-window session
to be remembered.

Krusader is different. It's a KDE/KF5 app that expects:

- A **DBus session bus** (already started by the LSIO baseimage — good).
- A **session manager** (`ksmserver`) on that bus that emits
  `saveYourself` at shutdown — **missing**.
- A correct **process locale** matching the user's language choice — **missing,
  partial**.

The first time we tried to fix UI persistence with the idempotent
`krusaderrc` key injector (commit `3f2ed7c`), we addressed half the problem
(initial defaults). The other half (saving runtime changes) cannot be done
from the outside; it has to come from the application itself, which means a
session manager has to be present.

Adding `ksmserver` is the **single highest-leverage change** in this whole
roadmap. It fixes Bug #1, Bug #2 outright, and makes Bug #3 redundant. Only
Bug #4 is genuinely independent (it's a shell-script bug + a missing locale).

---

## Suggested order of attack

If/when this work is picked up again, this is the cheapest-first / highest-leverage order:

1. **Bug #4** — pure shell-script fix in `cont-init.d`, no new packages, no
   image-size hit. ~30 min including the locale-gen verification. Standalone
   value to users (Unraid template language picker actually works).
2. **Bug #3** — single edit in `rootfs/defaults/openbox-rc.xml`, no new
   packages. Standalone value, no regression risk (rule is class-scoped).
3. **Bug #1 + Bug #2** (together) — install `plasma-workspace`, add s6 oneshot
   for `ksmserver`, export `SESSION_MANAGER`, add the Kate openbox rule.
   ~1 evening of debugging plus a multi-arch rebuild. Image grows by ~150–200 MB.
   This is the "real" fix; the previous three steps are stop-gaps.

After step 3, the idempotent key injector (commit `3f2ed7c`) can be **kept** —
it still gives users sensible defaults on a fresh `appdata`, and `ksmserver`
will then layer real saved state on top.

---

## Useful debug commands inside the container

```bash
# What is actually running?
ps -ef | grep -E 'krusader|kate|ksmserver|openbox|dbus' | grep -v grep

# DBus session bus is up and reachable?
echo $DBUS_SESSION_BUS_ADDRESS
qdbus 2>/dev/null | head

# Is ksmserver registered? (will print 'org.kde.ksmserver' once installed)
qdbus 2>/dev/null | grep -i ksm

# What does Krusader actually save?
ls -la /config/.config/krusaderrc
md5sum /config/.config/krusaderrc          # before
# ... do something in the GUI, then File → Quit ...
md5sum /config/.config/krusaderrc          # after — should differ once #1 is fixed

# Locale catalogues installed?
locale -a | sort
ls /usr/share/locale/de/LC_MESSAGES/krusader.mo  # adjust language code

# What did the init helper actually do?
cat /var/log/cont-init.d/30-krusader-language.log 2>/dev/null
cat /var/log/cont-init.d/30-krusader-keys.log 2>/dev/null
```

---

## Out of scope for this doc

- Reverse-proxy issues (Cloudflare, NPM, websockets) — see Section 9 of the README.
- Multi-user separation (this image is single-user by design).
- Mounting RAR/unrar tooling on arm64 — already handled by the build matrix in
  `.github/workflows/build.yml`.
- Adding more KDE apps (Dolphin, Konsole, …) — out of scope; if needed, fork
  and add them in `Dockerfile`'s apt layer plus a new openbox rule.

---

*Last updated together with v1.0.x release notes — May 2026.*
