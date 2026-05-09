#!/usr/bin/env python3
"""Recolor the official Krusader SVG to KDE Breeze Dark palette and emit:
   - .github/assets/krusader-logo-breeze.svg  (recoloured master)
   - .github/assets/icon.png                  (512x512, container/template icon)
   - .github/assets/krusader-banner.png       (1600x400, README banner)
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
BANNER_PNG = REPO / ".github/assets/krusader-banner.png"

# ---- Breeze Dark palette ----
# Official KDE Breeze Dark colour roles
# Banner background = formerly the logo's frame grey (light Breeze grey).
# Logo frame bars   = formerly the dark window background (Breeze dark grey).
# Result: logo sits darker on a lighter grey backdrop — stronger dark-mode feel.
BREEZE_BG_DARK = "#bdc3c7"      # banner background — light Breeze grey (was logo frame)
BREEZE_FRAME_DARK = "#1b1e20"   # darkest detail (was very dark navy #232341)
BREEZE_FRAME_MID = "#232629"    # frame top/bottom bars — Breeze dark grey (swapped in)
BREEZE_ACCENT = "#2980b9"       # primary panel blue — darker Breeze accent (was #9696ff)
BREEZE_ACCENT_DARK = "#1d6794"  # secondary darker Breeze blue (was #323264 deep navy)
BREEZE_FG = "#fcfcfc"           # foreground / cursor highlight (was #ffffff)

COLOR_MAP = {
    "#232341": BREEZE_FRAME_DARK,
    "#323264": BREEZE_ACCENT_DARK,
    "#9696ff": BREEZE_ACCENT,
    "#bebed2": BREEZE_FRAME_MID,
    "#ffffff": BREEZE_FG,
}

# ---- Recolour SVG ----
svg_text = SRC.read_text(encoding="utf-8")
for old, new in COLOR_MAP.items():
    # case-insensitive replace, both with and without leading #
    svg_text = re.sub(re.escape(old), new, svg_text, flags=re.IGNORECASE)
SVG_OUT.write_text(svg_text, encoding="utf-8")
print(f"wrote {SVG_OUT}")

# ---- Render icon (512x512, transparent background) ----
icon_bytes = cairosvg.svg2png(url=str(SVG_OUT), output_width=512, output_height=512)
ICON_PNG.write_bytes(icon_bytes)
print(f"wrote {ICON_PNG} ({ICON_PNG.stat().st_size} bytes)")

# ---- Render banner (1600x400) ----
W, H = 1600, 400
target_h = int(H * 0.72)
logo_png = cairosvg.svg2png(url=str(SVG_OUT), output_height=target_h * 2)
logo = Image.open(BytesIO(logo_png)).convert("RGBA")
ratio = target_h / logo.height
target_w = int(logo.width * ratio)
logo = logo.resize((target_w, target_h), Image.LANCZOS)

# Convert hex bg to RGB tuple
bg_rgb = tuple(int(BREEZE_BG_DARK.lstrip("#")[i : i + 2], 16) for i in (0, 2, 4))

banner = Image.new("RGB", (W, H), bg_rgb)
x = (W - target_w) // 2
y = (H - target_h) // 2
banner.paste(logo, (x, y), logo)
banner.save(BANNER_PNG, "PNG", optimize=True)
print(f"wrote {BANNER_PNG} ({BANNER_PNG.stat().st_size} bytes)")
