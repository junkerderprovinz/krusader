# Krusader for Unraid — Known Issues & Fix Roadmap

This document collects the **persistent, non-trivial bugs** discovered while
hardening the container that **were not fixed in v1.0.x** because they require
either a bigger image overhaul or upstream behavioural changes. It is meant as
a hand-off note so that future-me (or contributors) can pick up where the
current code left off without re-deriving the root cause from zero.

For day-to-day usage issues (port collisions, Selkies certificates, language
not switching after a UI change, locale fallback, …) see **Section 9. Troubleshooting**
in the main [`README.md`](README.md).

---

## Table of Contents

1. [Quick status table](#quick-status-table)
2. [Bug #1 — UI state is not persisted across `Quit`](#bug-1--ui-state-is-not-persisted-across-quit)
3. [Bug #2 — Kate opens maximised, window-`X` freezes the editor](#bug-2--kate-opens-maximised-window-x-freezes-the-editor)
4. [Bug #3 — Krusader window comes back small after a restart](#bug-3--krusader-window-comes-back-small-after-a-restart)
5. [Bug #4 — Template `KRUSADER_LANG` is ignored by the running app](#bug-4--template-krusader_lang-is-ignored-by-the-running-app)
6. [Bug #5 — Pasted UPPERCASE arrives lowercase on Firefox (issue #27)](#bug-5--pasted-uppercase-arrives-lowercase-on-firefox-issue-27)
7. [Architectural background — why a session manager is the real fix](#architectural-background--why-a-session-manager-is-the-real-fix)
8. [Suggested order of attack](#suggested-order-of-attack)
9. [Useful debug commands inside the container](#useful-debug-commands-inside-the-container)

---

## Quick status table

| # | Bug | Status | User-visible symptom | Fix applied |
|---|---|---|---|---|
| 1 | UI state not persisted | **Fixed** | After `File → Quit` and a fresh container start, status-bar visibility, panel widths, last directory and window geometry came back at defaults | `plasma-workspace` added to Dockerfile; new `rootfs/usr/local/bin/krusader-session` wrapper starts `ksmserver --no-lockscreen` before krusader within the same `dbus-launch` session so `org.kde.ksmserver` is present on the session bus. `autostart` now calls `krusader-session` instead of `krusader` directly. |
| 2 | Kate opens maximised + window `X` freezes | **Fixed** | Kate filled the full Selkies viewport on launch; clicking close hung for ~10 s | Openbox application rule `<application class="kate">` added to `rootfs/defaults/openbox-rc.xml` (size 1100×750, centered). Freeze fixed by same `ksmserver` work as #1. |
| 3 | Krusader window comes back small (≈ 800×600) | **Fixed** | Window started at openbox default size rather than full viewport | Openbox application rule `<application class="krusader"><maximized>yes</maximized>` added to `rootfs/defaults/openbox-rc.xml`. |
| 4 | Template `KRUSADER_LANG` ignored | **Fixed** | User set e.g. `de` in Unraid template, Krusader still came up in English | `init-krusader/run` now reads the locale values written by `krusader-language.sh` and pushes them into `/run/s6/container_environment/` via `set_env`, overriding the static Docker-ENV defaults. `autostart` fallback changed from hardcoded `de_DE.UTF-8` to neutral `en_US.UTF-8`. |
| 5 | Pasted UPPERCASE arrives lowercase (Firefox) | **Partial — fixed on upstream `main`, not yet on the `lsio` branch this image builds from, see [Bug #5](#bug-5--pasted-uppercase-arrives-lowercase-on-firefox-issue-27)** | Copying `Big Chicken A Fast Food Conspiracy` and pasting into a Krusader dialog produces `big chicken a fast food conspiracy` on Firefox; Chromium (Brave, Edge) is unaffected (issue #27). | `autostart` now loads a real Xvfb keymap (`setxkbmap`, `x11-xkb-utils`/`xkb-data` added to the Dockerfile) — a real fix for the "Shift never binds at all" failure mode, kept because it's harmless and does help other X11 modifier issues. **The "rebuilt on a base carrying upstream PR #254" claim in the original fix was verified false** — the pinned `selkies-project/selkies` commit is on the `lsio` branch and still lacks PR #254, and the resulting Firefox-specific retype bug (`_handleMobileInput` in `input.js`) is still present verbatim there. The real fix (`4edd73a`) exists on upstream `main` but hasn't reached `lsio` yet; no local code fix shipped, use the `about:config` mitigation below meanwhile — see Bug #5 for the full chain. |

---

## Bug #1 — UI state is not persisted across `Quit`

### Symptom

1. Start the container, open the web-UI.
2. Drag the status bar off, resize a panel column, switch to "Detailed view",
   `cd` somewhere deep, close the second panel — anything visible.
3. `File → Quit` (or hit the X) → wait for Selkies to show "Session ended".
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

1. **Add `ksmserver`** to the image. On the LSIO Selkies baseimage (Ubuntu-based),
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
- Kate launches **maximised** to the full Selkies viewport, ignoring the
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

Then refresh the Selkies tab → Krusader should come up in the chosen language
and the Settings → Language picker should reflect it.

### Related but already-fixed

Section 9 of the README already documents the "change Settings → Language in
the GUI doesn't stick" case — that one **is** caused by Bug #1, because the
runtime UI change is never written back. The Unraid-template path described
here is a **separate code path** (env var → init script → config file), which
should work even without `ksmserver`.

---

## Bug #5 — Pasted UPPERCASE arrives lowercase on Firefox (issue #27)

### Symptom

Copy text containing capitals in the **local** browser (e.g. `Big Chicken A
Fast Food Conspiracy`), paste it into any Krusader dialog inside the streamed
desktop. On **Firefox** it arrives as `big chicken a fast food conspiracy` —
every capital lost. On **Chromium-based browsers** (tested: Brave, Edge) the
same paste is byte-exact. Reproduces after a fresh image pull, i.e. after the
v2.3.0 fix (commit `1fc1097`) shipped.

### Why the v2.3.0 fix did not resolve it

v2.3.0's commit message claimed the image was "rebuilt on the rolling Selkies
base which now carries upstream PR #254 (restores Firefox's byte-exact
clipboard paste)". **That claim is false**, verified directly against the
pinned commit, not inferred from dates. (An earlier draft of this document
cited `0d134b6e1ffe42a579bc66363b0e7159ab22aacc` as the pin, read from a
personal fork of `docker-baseimage-selkies` rather than the real upstream
repo that actually builds the published image — that hash was stale. The
figures below are re-verified against `linuxserver/docker-baseimage-selkies`
directly.)

1. `Dockerfile` pins the base via `ARG BASE_TAG=ubunturesolute` →
   `FROM ghcr.io/linuxserver/baseimage-selkies:${BASE_TAG}`.
2. `linuxserver/docker-baseimage-selkies`'s **`ubunturesolute`** branch
   Dockerfile (the branch actually built for that tag) clones
   `selkies-project/selkies` and does
   `git checkout -f 348bc4f61da66198573e7e57db9a266aca1991d5` — for **both**
   the web-core JS build stage and the Python backend install stage, so it's a
   single source of truth. That hash is what the currently published
   `ghcr.io/linuxserver/baseimage-selkies:ubunturesolute` image actually
   contains as of this writing.
3. That commit is dated **2026-08-05** and sits on `selkies-project/selkies`'s
   **`lsio`** branch (confirmed: `git merge-base --is-ancestor <hash>
   upstream/lsio` succeeds, `... upstream/main` fails — it is not on `main`
   at all). `selkies-project/selkies` PR #254 ("Comprehensive fixes and
   performance optimizations", which added the `createClipboardGestures`
   native-paste mechanism in `addons/selkies-web-core/lib/clipboard-sync.js`)
   merged into `main` on **2026-07-14** and, as of this writing, has **not**
   been ported onto `lsio`. Confirmed directly:
   `git show 348bc4f61da66198573e7e57db9a266aca1991d5:addons/selkies-web-core/lib/clipboard-sync.js`
   → `fatal: path ... does not exist`. The file is entirely absent from the
   commit krusader actually ships. PR #254's fix was never in the image.
4. `lsio` and `main` diverged earlier (at merge-base
   `0d134b6e1ffe42a579bc66363b0e7159ab22aacc`) and have moved independently
   since — `lsio` is not merely "behind" `main`, it carries its own commits
   too. `docker-baseimage-selkies` builds from `lsio`, so fixes that land on
   `main` are not carried automatically; someone has to
   backport/re-merge them onto `lsio`, and `docker-baseimage-selkies` then has
   to bump its pinned hash.
5. `addons/selkies-web-core/lib/input.js`'s `_handleMobileInput` at that exact
   commit still contains the bug verbatim: for every uppercase character it
   sends `kd,Shift_L` → `kd,<lowercase keysym>` → `ku,<lowercase keysym>` →
   `ku,Shift_L`, i.e. it depends on the server correctly interpreting a
   held-modifier + lowercase-keysym sequence rather than sending the
   uppercase character's own keysym. This was exactly the bug tracked by
   `selkies-project/selkies` **PR #296** (`fix(input): send the character
   keysym directly for typed and pasted uppercase`, tracking issue #295).

   **Update (2026-08-10): fixed upstream, but not yet on the branch this
   image ships.** PR #296 was closed as superseded by commit
   [`4edd73a`](https://github.com/selkies-project/selkies/commit/4edd73a6c1f865abb236e87c06d40afb3ce76a1c)
   (`fix: Container logic`), which routes `_handleMobileInput` through the
   shared `_typeText` helper — it looks up each character's own keysym and
   sends `kd`/`ku` for it directly, no `Shift_L` injection, so capitals keep
   their case regardless of keymap state. Separately, commit
   [`00ce739`](https://github.com/selkies-project/selkies/commit/00ce7394046eb0b89f2bd1892492a348a23db780)
   (2026-06-13, "Performance optimizations") replaced the
   `navigator.clipboard.readText()` silent-sync path with a synchronous-copy
   fallback that works on Firefox without any `about:config` change at all —
   upstream's FAQ was rewritten accordingly ("the older Firefox `about:config`
   workaround is no longer required"). **Both fixes are on `main`, neither is
   on `lsio`** (re-verified 2026-08-17: `git compare` shows both commits are
   ancestors of `main` but not of `lsio`, whose tip is still the same
   `348bc4f6` this document already cites — `lsio` remains actively
   maintained, just hasn't cherry-picked these two yet). Until
   `docker-baseimage-selkies` bumps its `ubunturesolute` pin past a `main`
   sync (or someone ports these two commits onto `lsio` directly), the
   `about:config` mitigation below is still the fastest path for an affected
   user; it now fixes both symptoms at once (no more Paste-button friction
   *and* no more retype path, since the working clipboard sync means
   `_handleMobileInput` is never reached for a clipboard paste).

### Why Firefox specifically, and not Chromium

`window.addEventListener('focus', ...)` in `selkies-ws-core.js` tries to
silently sync the local clipboard to the remote X11 `CLIPBOARD` selection via
`navigator.clipboard.readText()` whenever the tab regains focus. When that
succeeds, a native `Ctrl+V` inside the streamed app is a plain X11 paste —
byte-exact, untouched by any Selkies JS. Chromium grants this silent,
gesture-less read; **Firefox does not** — its stricter Async Clipboard API
permission model is documented directly in this codebase: the merged FAQ
entry (`selkies-project/selkies` PR #224, by contributor `aliefe04`) tells
Firefox users to flip `dom.events.testing.asyncClipboard` in `about:config`
to get parity with Chromium, and a closed-but-descriptive draft (PR #276,
"stop Firefox/Safari paste prompt on window focus") spells out that "only
Chromium can read the system clipboard silently \[...] on Firefox and Safari
\[...] it pops up an ephemeral Paste prompt" (upstream issues #258, #234).
Without that manual flag, Firefox's silent focus-sync never populates the
remote X clipboard, so the browser falls back to whatever UI path funnels
typed/pasted text through `#keyboard-input-assist` — which is exactly the
buggy `_handleMobileInput` retype path described above. This is
architecturally distinct from "paste into a web page rendered inside the
browser tab" (what `createClipboardGestures` targets, and which is absent
from this pin anyway); it is specific to getting text into a **native X11
app inside the stream** when the silent clipboard channel is unavailable.

**Note on the `about:config` recommendation's currency:** upstream `main`
has since replaced this FAQ entry — a later commit ("Performance
optimizations", 2026-06-13) added a synchronous-copy fallback and rewrote
the FAQ to say no browser configuration is needed at all. That fallback
commit is not on `lsio` (confirmed: not an ancestor of the pinned commit), so
it is not in the image krusader ships. Its read-direction mechanism has a
narrower port up as PR #302 (see "Options considered" below) — until that
merges and reaches this image, the `about:config` workaround below is
checked against the code actually running in this container, not against
whatever upstream's live docs page currently says — the two have diverged.

### Why `setxkbmap` alone can't close the gap

The keymap fix (still worth keeping) addresses one real failure mode: with no
Xvfb keymap at all, `Shift_L` has nothing to bind to. Loading a real keymap
makes `Shift_L` bindable, but `_handleMobileInput`'s retype path still sends
a held-modifier + lowercase-keysym sequence per uppercase character instead
of the character's own keysym — a design that stays fragile regardless of
keymap state, which is exactly the class of problem PR #296 avoids entirely
by not depending on modifier state at all. (Server-side dispatch in
`input_handler.py` was checked for a timing/ordering explanation too: each
`kd`/`ku` message is drained from a single `asyncio.Queue` and fully
`await`ed before the next is processed, i.e. strictly serialized — there is
no race there, so the gap is the client-side keysym choice, not server-side
timing.) That the bug reproduces identically after the keymap fix shipped is
consistent with this: the keymap was a necessary condition for one theorized
failure mode, not a sufficient fix for the actual client-side design flaw.

### Options considered for a krusader-local fix

- **Wait for upstream.** Step (a) is done — the fix landed on `main` as
  `4edd73a` (superseding #296). Step (b), porting the keysym-lookup part onto
  `lsio` itself (not the whole `4edd73a`, which also carries an unrelated
  chord-modifier feature `lsio` doesn't have): **submitted 2026-08-17 as
  [selkies-project/selkies#301](https://github.com/selkies-project/selkies/pull/301)**,
  open. The clipboard-sync commit `00ce739` was investigated too — it's
  deeply entangled in a much larger, unrelated "Performance optimizations"
  commit (26 files, 3131 lines) with real conflicts against `lsio`'s current
  state, and about half of it is a *write*-direction (Ctrl+C) feature
  needing a new client/server protocol `lsio` doesn't have — but its
  *read*-direction mechanism (trigger the existing clipboard-read-and-send
  logic on a real Ctrl/Cmd+V keydown instead of only on window focus, since
  Firefox/Safari require real user-gesture activation for that read) turned
  out to be self-contained. That narrower slice was extracted and
  **submitted 2026-08-17 as
  [selkies-project/selkies#302](https://github.com/selkies-project/selkies/pull/302)**,
  open — see the "Why Firefox specifically" section above for the mechanism.
  Once/if both merge, still needed: (c) a new `docker-baseimage-selkies` pin
  bump (its Dockerfile hard-pins an exact commit SHA, `348bc4f...`, not the
  `lsio` branch HEAD — merging to `lsio` alone does not reach downstream
  images), (d) a new `linuxserver/baseimage-selkies` published tag that
  krusader then adopts via a `BASE_TAG` bump. Still out of krusader's
  control end-to-end, but now a tracked, concrete chain instead of "wait and
  see."
- **Local patch of the built JS in krusader's own `Dockerfile`.** Considered
  and **rejected for now**: `docker-baseimage-selkies` builds
  `selkies-web-core`/`selkies-dashboard` with `vite build`, which minifies by
  default, and krusader only inherits the pre-built, already-bundled
  `ghcr.io/linuxserver/baseimage-selkies` image — there is no source tree to
  patch, only a minified artifact whose exact contents were not inspected
  (no local `docker` available to pull and open the real image; the
  `docker-baseimage-selkies` Dockerfile itself was read directly instead, at
  its actual `ubunturesolute` branch HEAD, which is real inspection, not a
  guess — but the *served* file is one build step further than that and
  wasn't verified byte-for-byte). Note that `docker-baseimage-selkies` **does**
  already have precedent for exactly this "`COPY` a patch into the build
  context, `git apply` it before building" pattern — its own Dockerfile does
  this for `labwc-ipc.patch` before building `labwc` from source (line ~284:
  `COPY /labwc-ipc.patch /labwc-ipc.patch` → `git apply labwc-ipc.patch`). So
  the mechanism is not the blocker; the blocker is that krusader's own
  Dockerfile only pulls the pre-built `linuxserver/baseimage-selkies` image,
  it does not build `docker-baseimage-selkies` itself, so there is no local
  point at which to apply such a patch without forking that upstream repo's
  build. Shipping a blind `sed`/patch against an unverified minified string
  in the already-built image would be exactly the kind of unsafe,
  unverifiable local workaround this doc is trying to avoid — a wrong guess
  would either silently no-op (pattern doesn't match) or, worse, corrupt the
  bundle. If this route is picked up later, the first step has to be pulling
  the real `ghcr.io/linuxserver/baseimage-selkies:ubunturesolute` image and
  inspecting `/usr/share/selkies/www` (or wherever the dist output lands)
  directly, then writing a patch step that **fails the build loudly**
  (`grep -q <exact signature> file || exit 1`) if the target string isn't
  found, so a future base-image bump can't silently ship the old bug again
  under a false "still patched" assumption.
- **Immediate, zero-risk mitigation shipped in this revision.** Point Firefox
  users at the same upstream-documented `about:config` flag
  (`dom.events.testing.asyncClipboard` → `true`) that unlocks Chromium-parity
  silent clipboard sync — see the README's Troubleshooting section. This
  routes Firefox onto the same byte-exact X11-clipboard path Chromium already
  uses and sidesteps `_handleMobileInput` entirely, with no image rebuild and
  no risk.

### Verification

```bash
# Confirm the keymap actually bound (was previously unverifiable: the
# autostart script discarded setxkbmap's exit status and stderr entirely)
docker logs krusader 2>&1 | grep -A1 "keymap:"
docker exec krusader setxkbmap -display "${DISPLAY:-:1}" -query
```

---

## Architectural background — why a session manager is the real fix

`baseimage-selkies` boots `Xvfb + openbox + the Selkies web frontend`
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

*Last updated 2026-08-17 — Bug #5's client-side Firefox retype bug and the
underlying clipboard-permission issue are both fixed on `selkies-project/selkies`
`main` (`4edd73a`, `00ce739`) but not yet on the `lsio` branch this image
builds from. Narrower ports of each are up for `lsio` as PR #301 (retype
bug) and PR #302 (clipboard-permission gesture trigger), both open. See Bug
#5 for the full evidence chain and the immediate `about:config` mitigation,
which covers both symptoms at once in the meantime.*
