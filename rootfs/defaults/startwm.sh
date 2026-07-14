#!/usr/bin/env bash
# Overrides the Selkies base image's /defaults/startwm.sh for ONE reason: the
# base redirects the whole desktop session to /dev/null (`> /dev/null 2>&1`),
# which swallows every line the openbox session and its children write — our
# autostart's diagnostics and anything Krusader/Kate print to the session.
# Identical to the base script otherwise, incl. the Nvidia/zink block.
# (The "KRUSADER IS READY" banner is a separate s6 service and is unaffected;
# this is purely about keeping the desktop log visible in `docker logs`.)

# Enable Nvidia GPU support if detected
if which nvidia-smi > /dev/null 2>&1 && ls -A /dev/dri 2>/dev/null && [ "${DISABLE_ZINK}" == "false" ]; then
  export LIBGL_KOPPER_DRI2=1
  export MESA_LOADER_DRIVER_OVERRIDE=zink
  export GALLIUM_DRIVER=zink
fi

# Start DE — output stays on the service's stdio so it lands in the docker log.
exec dbus-launch --exit-with-session /usr/bin/openbox-session
