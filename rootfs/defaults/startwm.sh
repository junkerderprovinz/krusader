#!/usr/bin/env bash
# Overrides the Selkies base image's /defaults/startwm.sh.
#
# The "<APP> IS READY" banner that svc-krusader-ready prints once the WebUI is
# serving has to be the last block in `docker logs`. The desktop session prints
# continuously, and left on the service's stdio its output would trail past the
# banner, so the session goes to /dev/null as in the stock base script. Lift the
# redirect only while debugging the desktop, and put it back afterwards.
# Otherwise identical to the base script, Nvidia/zink block included.

# Enable Nvidia GPU support if detected
if which nvidia-smi > /dev/null 2>&1 && ls -A /dev/dri 2>/dev/null && [ "${DISABLE_ZINK}" == "false" ]; then
  export LIBGL_KOPPER_DRI2=1
  export MESA_LOADER_DRIVER_OVERRIDE=zink
  export GALLIUM_DRIVER=zink
fi

exec dbus-launch --exit-with-session /usr/bin/openbox-session > /dev/null 2>&1
