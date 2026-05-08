#!/usr/bin/env python3
"""Build banner: solid dark background + darkened user logo, nothing else."""
from PIL import Image, ImageEnhance
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
LOGO = REPO / ".github/assets/krusader-logo.jpg"
OUT_PNG = REPO / ".github/assets/krusader-banner.png"

W, H = 1600, 400
BG = (15, 18, 24)  # very dark slate, near-black

# Load logo, darken it (lower brightness, slight desaturation)
logo = Image.open(LOGO).convert("RGB")
logo = ImageEnhance.Brightness(logo).enhance(0.55)
logo = ImageEnhance.Color(logo).enhance(0.85)

# Resize logo to fit nicely in banner — height ~60% of banner
target_h = int(H * 0.62)
ratio = target_h / logo.height
target_w = int(logo.width * ratio)
logo = logo.resize((target_w, target_h), Image.LANCZOS)

# Compose
banner = Image.new("RGB", (W, H), BG)
x = (W - target_w) // 2
y = (H - target_h) // 2
banner.paste(logo, (x, y))
banner.save(OUT_PNG, "PNG", optimize=True)
print(f"wrote {OUT_PNG} ({OUT_PNG.stat().st_size} bytes)")
