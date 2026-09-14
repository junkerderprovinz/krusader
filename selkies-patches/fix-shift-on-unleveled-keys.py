#!/usr/bin/env python3
"""Keep a held Shift for keys that Shift does not level (Shift+F4, Shift+F2, ...).

Selkies' XTEST injector lifts a held Shift around a press when the target level
does not want it, so a glyph cannot land on the wrong level. That is correct for
letters and digits. It is wrong for a function key: F4 carries the same keysym at
level 0 and level 1, so Shift selects no level there, it is part of a chord. The
lift turned every Shift+F<n> into a bare F<n>.

Measured with xev inside the container. Before:

    KeyPress    Shift_L  state=0x0
    KeyRelease  Shift_L  state=0x1   lifted here
    KeyPress    F4       state=0x0   arrives without Shift
    KeyPress    Shift_L  state=0x0
    KeyRelease  F4       state=0x1
    KeyRelease  Shift_L  state=0x1

After:

    KeyPress    Shift_L  state=0x0
    KeyPress    F4       state=0x1
    KeyRelease  F4       state=0x1
    KeyRelease  Shift_L  state=0x1

In Krusader that is the difference between "New Text File" (Shift+F4) and "Edit
File" (F4), and on a folder the latter only answers "folders cannot be edited".
The browser client is not at fault: instrumenting the running instance shows it
sends the four events in the correct order. The lift happens server-side in
press().

Ctrl+Shift+X survives because ACTION_MODIFIER_KEYSYMS covers Control, Alt, Meta,
Super and Hyper, so a chord modifier being down suppresses the lift. Shift is
deliberately not in that set, since on a letter it really does select a level.
This fix therefore does not widen that set. It asks the keymap whether Shift
changes anything for this particular keycode.

Only the dev base carries this code path. The pinned ubunturesolute tag ships an
older selkies without the level synthesis, so the sibling images are unaffected.

Upstream main still carries the unpatched line (checked 2026-09-14). Drop this
script once upstream carries the fix. It exits non-zero when an anchor no longer
matches, which fails the build on purpose so the change gets re-checked instead
of shipping a patch that quietly does nothing.

A plain unified diff would have been the obvious form, but the final image has no
`patch` binary and pulling one in for a single edit is not worth a package.
"""

import ast
import glob
import sys

ANCHOR = b"""            lift.append(self._altgr_kc)
        return lift
"""

HELPER = b'''            lift.append(self._altgr_kc)
        return lift

    def _shift_selects_level(self, kc: int) -> bool:
        """Whether Shift changes what this keycode types.

        A keycode carrying the same keysym at level 0 and level 1 (function
        keys, arrows, Escape) is not leveled by Shift, so a held Shift is part
        of a chord such as Shift+F4 and must not be lifted around the press.
        """
        try:
            return self._d.keycode_to_keysym(kc, 0) != self._d.keycode_to_keysym(kc, 1)
        except Exception:
            return True
'''

CALL_OLD = b"        lifted = self._mods_to_lift(set(mods), down) if neutralize else []"

CALL_NEW = (b"        lifted = (self._mods_to_lift(set(mods), down)\n"
            b"                  if (neutralize and self._shift_selects_level(kc)) else [])")

PATTERN = "/lsiopy/lib/python3*/site-packages/selkies/input_handler.py"


def fail(message):
    print("ERROR: %s" % message, file=sys.stderr)
    print("The selkies input handler no longer looks the way this patch expects.",
          file=sys.stderr)
    print("Re-check upstream: the bug may be fixed, in which case drop "
          "selkies-patches/ and this build step.", file=sys.stderr)
    raise SystemExit(1)


def main():
    matches = sorted(glob.glob(PATTERN))
    if len(matches) != 1:
        fail("expected exactly one %s, found %d" % (PATTERN, len(matches)))
    path = matches[0]

    src = open(path, "rb").read()

    if b"_shift_selects_level" in src:
        fail("already patched, or upstream adopted the fix under the same name")
    for name, needle in (("helper anchor", ANCHOR), ("call site", CALL_OLD)):
        found = src.count(needle)
        if found != 1:
            fail("%s matched %d times, expected exactly 1" % (name, found))

    src = src.replace(ANCHOR, HELPER).replace(CALL_OLD, CALL_NEW)
    ast.parse(src.decode("utf-8"))
    open(path, "wb").write(src)
    print("krusader: kept Shift on unleveled keys in %s" % path)


if __name__ == "__main__":
    main()
