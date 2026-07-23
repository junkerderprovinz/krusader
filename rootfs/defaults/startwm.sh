#!/usr/bin/env bash
# Overrides the Selkies base image's /defaults/startwm.sh.
#
# HOUSE RULE — the "<APP> IS READY" ASCII brand banner (printed by the separate
# svc-<app>-ready service once the WebUI is serving) MUST be the LAST block in
# `docker logs`. The desktop session prints continuously; if its stdout stays on
# the service's stdio, the app's output trails *past* the READY banner and the
# log no longer ends on it. We therefore send the session to /dev/null, exactly
# like the stock base script does.
#
# Do NOT remove this redirect to "keep the session log visible" — that is what
# pushed output past the banner before. Un-redirect only temporarily while
# actively debugging the desktop, and put it back.
# Identical to the base script otherwise, incl. the Nvidia/zink block.

# Enable Nvidia GPU support if detected
if which nvidia-smi > /dev/null 2>&1 && ls -A /dev/dri 2>/dev/null && [ "${DISABLE_ZINK}" == "false" ]; then
  export LIBGL_KOPPER_DRI2=1
  export MESA_LOADER_DRIVER_OVERRIDE=zink
  export GALLIUM_DRIVER=zink
fi

# Start the desktop. Output -> /dev/null so nothing trails the READY banner.
exec dbus-launch --exit-with-session /usr/bin/openbox-session > /dev/null 2>&1
