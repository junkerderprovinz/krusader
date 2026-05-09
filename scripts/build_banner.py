#!/usr/bin/env python3
"""Build banner: solid dark background + darkened official Krusader logo, nothing else."""
import cairosvg
from io import BytesIO
from PIL import Image, ImageEnhance
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
LOGO_SVG = REPO / ".github/assets/krusader-logo.svg"
OUT_PNG = REPO / ".github/assets/krusader-banner.png"

W, H = 1600, 400
BG = (15, 18, 24)  # very dark slate, near-black

# Render SVG → PNG at high resolution (logo height ~ 70 % of banner)
target_h = int(H * 0.70)
png_bytes = cairosvg.svg2png(
    url=str(LOGO_SVG), output_height=target_h * 2  # 2x for crisp downscale
)
logo = Image.open(BytesIO(png_bytes)).convert("RGBA")

# Downscale to target with high-quality filter
ratio = target_h / logo.height
target_w = int(logo.width * ratio)
logo = logo.resize((target_w, target_h), Image.LANCZOS)

# Darken the logo (preserve alpha)
r, g, b, a = logo.split()
rgb = Image.merge("RGB", (r, g, b))
rgb = ImageEnhance.Brightness(rgb).enhance(0.62)
rgb = ImageEnhance.Color(rgb).enhance(0.85)
r2, g2, b2 = rgb.split()
logo = Image.merge("RGBA", (r2, g2, b2, a))

# Compose on dark background
banner = Image.new("RGB", (W, H), BG)
x = (W - target_w) // 2
y = (H - target_h) // 2
banner.paste(logo, (x, y), logo)  # use alpha as mask
banner.save(OUT_PNG, "PNG", optimize=True)
print(f"wrote {OUT_PNG} ({OUT_PNG.stat().st_size} bytes)")
