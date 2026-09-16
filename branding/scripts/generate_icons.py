#!/usr/bin/env python3
"""Masroof brand icon generator.

Single source of truth for the Masroof mark (wallet + coin). It writes:

  branding/icon/masroof-icon.svg              master vector (full-bleed, square)
  branding/icon/masroof-mark.svg              transparent mark (for UI use)
  branding/icon/png/icon-1024.png             master raster (iOS / stores / flutter_launcher_icons)
  branding/icon/png/adaptive-foreground.png   Android adaptive foreground (mask-safe)
  branding/icon/png/adaptive-monochrome.png   Android 13+ themed icon
  branding/icon/png/mark-*.png                transparent mark for splash / in-app use
  web/public/*                                favicon.ico, icon.svg, PWA icons

Platform launcher icons for mobile are then produced by
`dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`
inside `mobile/` (see docs/branding.md).

Requires Pillow (`pip install pillow`).
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
ICON_DIR = ROOT / "branding" / "icon"
PNG_DIR = ICON_DIR / "png"
WEB_PUBLIC = ROOT / "web" / "public"

# ---- Brand palette -------------------------------------------------------
BG_TOP = "#0F7A68"      # emerald 600
BG_BOTTOM = "#07463D"   # emerald 900
WALLET = "#FFFFFF"
NOTE = "#7FE3C1"        # mint banknote
CLASP = "#07463D"
COIN = "#F5B83D"        # gold
COIN_RIM = "#D99A1E"

# ---- Geometry on a 1024 canvas (content centred at 512,512) --------------
# Content box spans x 200..848, y 256..768 => centred at (524, 512).
# Shapes are expressed relative to canvas and transformed by scale about centre.
NOTE_RECT = (272, 256, 716, 400, 48)       # banknote peeking above the wallet
BODY_RECT = (200, 336, 800, 768, 104)      # wallet body
CLASP_RECT = (588, 468, 848, 636, 84)      # clasp tab (protrudes right)
COIN_CIRCLE = (716, 552, 50)               # coin on clasp
CONTENT_CENTER = (524, 512)


def _tx(v: float, c: float, scale: float) -> float:
    return 512 + (v - c) * scale


def _rect(r, scale):
    x0, y0, x1, y1, rad = r
    cx, cy = CONTENT_CENTER
    return (_tx(x0, cx, scale), _tx(y0, cy, scale), _tx(x1, cx, scale), _tx(y1, cy, scale), rad * scale)


def _circle(c, scale):
    x, y, rad = c
    cx, cy = CONTENT_CENTER
    return (_tx(x, cx, scale), _tx(y, cy, scale), rad * scale)


def _gradient(size: int) -> Image.Image:
    top = Image.new("RGB", (1, 1), BG_TOP).getpixel((0, 0))
    bottom = Image.new("RGB", (1, 1), BG_BOTTOM).getpixel((0, 0))
    grad = Image.new("RGB", (1, size))
    for y in range(size):
        t = y / (size - 1)
        grad.putpixel((0, y), tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return grad.resize((size, size)).convert("RGBA")


def render(
    size: int,
    *,
    scale: float,
    background: bool,
    monochrome: bool = False,
    clasp_color: str | None = None,
) -> Image.Image:
    """Render the mark at `size` px. `scale` shrinks content about the centre."""
    ss = 4  # supersampling for clean anti-aliased edges
    big = size * ss
    k = big / 1024
    img = _gradient(big) if background else Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def rr(r, fill):
        x0, y0, x1, y1, rad = _rect(r, scale)
        d.rounded_rectangle((x0 * k, y0 * k, x1 * k, y1 * k), radius=rad * k, fill=fill)

    white = "#FFFFFF"
    if monochrome:
        # Themed icon: single colour silhouette, clasp + coin punched out.
        rr(NOTE_RECT, white)
        rr(BODY_RECT, white)
        rr(CLASP_RECT, white)
        x, y, rad = _circle(COIN_CIRCLE, scale)
        d.ellipse(((x - rad) * k, (y - rad) * k, (x + rad) * k, (y + rad) * k), fill=(0, 0, 0, 0))
    else:
        rr(NOTE_RECT, NOTE)
        rr(BODY_RECT, WALLET)
        rr(CLASP_RECT, clasp_color or CLASP)
        x, y, rad = _circle(COIN_CIRCLE, scale)
        d.ellipse(((x - rad) * k, (y - rad) * k, (x + rad) * k, (y + rad) * k), fill=COIN_RIM)
        inner = rad * 0.78
        d.ellipse(((x - inner) * k, (y - inner) * k, (x + inner) * k, (y + inner) * k), fill=COIN)

    return img.resize((size, size), Image.LANCZOS)


def svg(scale: float, background: bool) -> str:
    parts = [
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">',
    ]
    if background:
        parts += [
            "<defs><linearGradient id=\"bg\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\">",
            f'<stop offset="0" stop-color="{BG_TOP}"/><stop offset="1" stop-color="{BG_BOTTOM}"/>',
            "</linearGradient></defs>",
            '<rect width="1024" height="1024" fill="url(#bg)"/>',
        ]

    def rect(r, fill):
        x0, y0, x1, y1, rad = _rect(r, scale)
        return (
            f'<rect x="{x0:.1f}" y="{y0:.1f}" width="{x1 - x0:.1f}" height="{y1 - y0:.1f}" '
            f'rx="{rad:.1f}" fill="{fill}"/>'
        )

    x, y, rad = _circle(COIN_CIRCLE, scale)
    parts += [
        rect(NOTE_RECT, NOTE),
        rect(BODY_RECT, WALLET),
        rect(CLASP_RECT, CLASP),
        f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{rad:.1f}" fill="{COIN_RIM}"/>',
        f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{rad * 0.78:.1f}" fill="{COIN}"/>',
        "</svg>",
    ]
    return "\n".join(parts) + "\n"


# Full-bleed icon: content occupies ~63% of the canvas width, which reads well
# inside iOS squircles and legacy Android masks.
FULL_SCALE = 1.0
# Android adaptive foreground: 108dp canvas, only the central 66dp circle is
# guaranteed visible. Content half-diagonal (~410 at scale 1) must stay within
# 1024 * 33/108 = 313px, so scale to 0.72 (≈297px, inside the safe circle).
ADAPTIVE_SCALE = 0.72
# Transparent mark used in-app/splash: fill the canvas with small padding.
MARK_SCALE = 1.1


def main() -> None:
    PNG_DIR.mkdir(parents=True, exist_ok=True)
    WEB_PUBLIC.mkdir(parents=True, exist_ok=True)

    (ICON_DIR / "masroof-icon.svg").write_text(svg(FULL_SCALE, background=True))
    (ICON_DIR / "masroof-mark.svg").write_text(svg(MARK_SCALE, background=False))
    (WEB_PUBLIC / "icon.svg").write_text(svg(FULL_SCALE, background=True))

    master = render(1024, scale=FULL_SCALE, background=True).convert("RGB")
    master.save(PNG_DIR / "icon-1024.png", optimize=True)
    render(1024, scale=ADAPTIVE_SCALE, background=False).save(PNG_DIR / "adaptive-foreground.png", optimize=True)
    render(1024, scale=ADAPTIVE_SCALE, background=False, monochrome=True).save(
        PNG_DIR / "adaptive-monochrome.png", optimize=True
    )
    for s in (192, 512, 1024):
        render(s, scale=MARK_SCALE, background=False).save(PNG_DIR / f"mark-{s}.png", optimize=True)
    # Splash variant for dark backgrounds: clasp matches dark splash colour.
    render(1024, scale=MARK_SCALE, background=False, clasp_color=BG_BOTTOM).save(
        PNG_DIR / "mark-splash.png", optimize=True
    )

    # Web / PWA
    for s, name in ((180, "apple-touch-icon.png"), (192, "icon-192.png"), (512, "icon-512.png")):
        render(s, scale=FULL_SCALE, background=True).convert("RGB").save(WEB_PUBLIC / name, optimize=True)
    # Maskable PWA icon uses the adaptive safe-zone scale on the brand background.
    render(512, scale=ADAPTIVE_SCALE, background=True).convert("RGB").save(
        WEB_PUBLIC / "icon-maskable-512.png", optimize=True
    )
    ico_sizes = [(16, 16), (32, 32), (48, 48)]
    render(256, scale=1.2, background=True).save(WEB_PUBLIC / "favicon.ico", sizes=ico_sizes)
    print("Masroof icons generated.")


if __name__ == "__main__":
    main()
