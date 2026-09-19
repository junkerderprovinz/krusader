#!/usr/bin/env python3
"""Recolour the official Krusader SVG to the KDE Breeze Dark palette and write
   - .github/assets/krusader-logo-breeze.svg  (recoloured master)
   - .github/assets/icon.png                  (512x512 container/CA icon on a
     transparent background, since the Breeze frame and blue panes read fine on
     the dark CA page and a white box around the rounded icon looks worse)
   - .github/assets/krusader-banner-logo.png  (1600x500 logo-only banner for
     the support thread; the README banner krusader-banner.png comes from
     .github/assets/gen-banner.mjs and is left alone here)
"""
import re
import cairosvg
from io import BytesIO
from PIL import Image
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SRC = REPO / ".github/assets/krusader-logo.svg"
SVG_OUT = REPO / ".github/assets/krusader-logo-breeze.svg"
ICON_PNG = REPO / ".github/assets/icon.png"
BANNER_PNG = REPO / ".github/assets/krusader-banner-logo.png"

# KDE Breeze Dark colour roles; COLOR_MAP below lists the source colour each
# one replaces.
BREEZE_BG_DARK = "#ffffff"      # banner background, white as in the matrix repo
BREEZE_FRAME_DARK = "#1b1e20"   # darkest detail
BREEZE_FRAME_MID = "#232629"    # frame top and bottom bars, Breeze dark grey
BREEZE_ACCENT = "#2980b9"       # primary panel blue, the darker Breeze accent
BREEZE_ACCENT_DARK = "#1d6794"  # secondary, darker Breeze blue
BREEZE_FG = "#fcfcfc"           # foreground and cursor highlight

COLOR_MAP = {
    "#232341": BREEZE_FRAME_DARK,
    "#323264": BREEZE_ACCENT_DARK,
    "#9696ff": BREEZE_ACCENT,
    "#bebed2": BREEZE_FRAME_MID,
    "#ffffff": BREEZE_FG,
}

svg_text = SRC.read_text(encoding="utf-8")
for old, new in COLOR_MAP.items():
    svg_text = re.sub(re.escape(old), new, svg_text, flags=re.IGNORECASE)
SVG_OUT.write_text(svg_text, encoding="utf-8")
print(f"wrote {SVG_OUT}")

icon_bytes = cairosvg.svg2png(url=str(SVG_OUT), output_width=512, output_height=512)
ICON_PNG.write_bytes(icon_bytes)
print(f"wrote {ICON_PNG} ({ICON_PNG.stat().st_size} bytes)")

W, H = 1600, 500
target_h = int(H * 0.72)
logo_png = cairosvg.svg2png(url=str(SVG_OUT), output_height=target_h * 2)
logo = Image.open(BytesIO(logo_png)).convert("RGBA")
ratio = target_h / logo.height
target_w = int(logo.width * ratio)
logo = logo.resize((target_w, target_h), Image.LANCZOS)

bg_rgb = tuple(int(BREEZE_BG_DARK.lstrip("#")[i : i + 2], 16) for i in (0, 2, 4))

banner = Image.new("RGB", (W, H), bg_rgb)
x = (W - target_w) // 2
y = (H - target_h) // 2
banner.paste(logo, (x, y), logo)
banner.save(BANNER_PNG, "PNG", optimize=True)
print(f"wrote {BANNER_PNG} ({BANNER_PNG.stat().st_size} bytes)")
