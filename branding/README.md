# Masroof brand assets

The Masroof mark is a minimal **wallet with a gold coin clasp** and a mint
banknote edge, on a deep-emerald gradient. It is generated entirely from
code so every platform uses identical geometry.

| File | Purpose |
|------|---------|
| `scripts/generate_icons.py` | **Master source.** Geometry, palette and every export. |
| `icon/masroof-icon.svg` | Full-bleed vector icon (store listings, design tools) |
| `icon/masroof-mark.svg` | Transparent mark for in-app use |
| `icon/png/icon-1024.png` | Master raster for iOS / `flutter_launcher_icons` |
| `icon/png/adaptive-foreground.png` | Android adaptive foreground (inside 66dp safe zone) |
| `icon/png/adaptive-monochrome.png` | Android 13+ themed icon |
| `icon/png/mark-*.png` | Splash and in-app mark |

Palette: emerald `#0F7A68 → #07463D`, mint `#7FE3C1`, gold `#F5B83D`.

## Regenerating

```bash
python3 branding/scripts/generate_icons.py      # requires Pillow
```

This rewrites the files above and the web icons in `web/public/`. Then
regenerate the native launcher icons and splash screens:

```bash
cd mobile
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

See [`docs/branding.md`](../docs/branding.md) for usage rules.
