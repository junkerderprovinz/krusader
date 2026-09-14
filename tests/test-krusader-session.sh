#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Behaviour tests for rootfs/usr/local/bin/krusader-session
# -----------------------------------------------------------------------------
# The session script supervises krusader inside the container. These tests run
# it for real against stub binaries on PATH, so they exercise the actual signal
# and exit handling instead of a re-implementation of it.
#
# Run: tests/test-krusader-session.sh   (or `just test`)
# -----------------------------------------------------------------------------
set -uo pipefail

# Invoked through `bash` on purpose: the shipped scripts are mode 0644 in git
# and get their +x from the Dockerfile, so requiring the executable bit here
# would fail on a fresh checkout (and on Windows checkouts generally).
SESSION="$(cd "$(dirname "$0")/.." && pwd)/rootfs/usr/local/bin/krusader-session"
[ -f "${SESSION}" ] || { echo "session script not found: ${SESSION}" >&2; exit 1; }

ORIG_PATH="${PATH}"
PASS=0
FAIL=0
SB=""

ok() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
no() { echo "  FAIL: $1 — expected [$2], got [$3]"; FAIL=$((FAIL + 1)); }
eq() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1" "$2" "$3"; fi; }

# A sandbox is a private PATH holding one stub krusader, plus a call log.
# XDG_CACHE_HOME is pinned inside it so the script's cache purge can never
# reach the real user's cache.
sandbox() {
    [ -n "${SB}" ] && rm -rf "${SB}"
    SB="$(mktemp -d)"
    mkdir -p "${SB}/bin" "${SB}/cache"
    export KRTEST_CALLS="${SB}/calls"
    : > "${KRTEST_CALLS}"
    export XDG_CACHE_HOME="${SB}/cache"
    export PATH="${SB}/bin:${ORIG_PATH}"
    cat > "${SB}/bin/krusader" <<STUB
#!/usr/bin/env bash
echo start >> "\${KRTEST_CALLS}"
$1
STUB
    chmod +x "${SB}/bin/krusader"
}

calls() { wc -l < "${KRTEST_CALLS}" | tr -d '[:space:]'; }

echo "== krusader-session =="

# -----------------------------------------------------------------------------
# 1) Quitting krusader must give the user a new krusader, not a black screen.
#    The stub quits immediately; on its third start it signals the session to
#    shut down (standing in for `docker stop`) so the test terminates.
# -----------------------------------------------------------------------------
sandbox '
if [ "$(wc -l < "${KRTEST_CALLS}")" -ge 3 ]; then
    kill -TERM "${PPID}"
    sleep 10
fi
exit 0'
timeout 90 bash "${SESSION}" > "${SB}/out" 2>&1
rc=$?
eq "restarts krusader after a clean quit" "3" "$(calls)"
eq "exits 0 when the container is stopped" "0" "${rc}"

# -----------------------------------------------------------------------------
# 2) Container shutdown must END the session — it must not restart krusader.
# -----------------------------------------------------------------------------
sandbox 'sleep 30'
bash "${SESSION}" > "${SB}/out" 2>&1 &
pid=$!
for _ in $(seq 1 60); do
    [ "$(calls)" -ge 1 ] && break
    sleep 0.2
done
kill -TERM "${pid}" 2>/dev/null
wait "${pid}"
rc=$?
eq "does not restart krusader after SIGTERM" "1" "$(calls)"
eq "exits 0 on SIGTERM" "0" "${rc}"

# -----------------------------------------------------------------------------
# 3) A krusader that cannot start at all must not spin: give up after a few
#    immediate failures instead of burning CPU in a restart loop.
# -----------------------------------------------------------------------------
sandbox 'exit 1'
timeout 120 bash "${SESSION}" > "${SB}/out" 2>&1
rc=$?
eq "gives up after 5 immediate failures" "5" "$(calls)"
if [ "${rc}" -ne 0 ]; then ok "reports failure when giving up"
else no "reports failure when giving up" "non-zero" "${rc}"; fi
if grep -qi 'giving up' "${SB}/out"; then ok "logs why it stopped restarting"
else no "logs why it stopped restarting" "a 'giving up' line" "$(tail -3 "${SB}/out")"; fi

# -----------------------------------------------------------------------------
# 4) The spin guard must also catch a krusader that exits CLEANLY but
#    instantly, every single time — e.g. a second instance handing over to a
#    unique-instance owner that is already gone. Exit code 0 alone must not
#    buy an endless restart loop.
# -----------------------------------------------------------------------------
sandbox 'exit 0'
timeout 120 bash "${SESSION}" > "${SB}/out" 2>&1
rc=$?
eq "gives up after 20 instant clean exits" "20" "$(calls)"
if grep -qi 'giving up' "${SB}/out"; then ok "logs why it stopped restarting instant clean exits"
else no "logs why it stopped restarting instant clean exits" "a 'giving up' line" "$(tail -3 "${SB}/out")"; fi

# -----------------------------------------------------------------------------
# 5) Shutdown must ASK krusader to quit itself before resorting to a signal,
#    so its "save settings on exit" gets the chance to run (Bug #1).
# -----------------------------------------------------------------------------
sandbox 'sleep 30'
cat > "${SB}/bin/qdbus6" <<'STUB'
#!/usr/bin/env bash
echo "qdbus6 $*" >> "${KRTEST_CALLS}.quit"
pkill -TERM -x krusader 2>/dev/null
exit 0
STUB
chmod +x "${SB}/bin/qdbus6"
: > "${KRTEST_CALLS}.quit"
bash "${SESSION}" > "${SB}/out" 2>&1 &
pid=$!
for _ in $(seq 1 60); do
    [ "$(calls)" -ge 1 ] && break
    sleep 0.2
done
kill -TERM "${pid}" 2>/dev/null
wait "${pid}"
if grep -q 'org.kde.krusader' "${KRTEST_CALLS}.quit"; then ok "asks krusader to quit itself on shutdown"
else no "asks krusader to quit itself on shutdown" "a qdbus6 quit call" "$(cat "${KRTEST_CALLS}.quit")"; fi

# -----------------------------------------------------------------------------
[ -n "${SB}" ] && rm -rf "${SB}"
echo "---"
echo "${PASS} passed, ${FAIL} failed"
[ "${FAIL}" -eq 0 ]
