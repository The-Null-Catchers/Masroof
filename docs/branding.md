# Branding

The Masroof mark is a **wallet with a gold coin** and a mint banknote edge on a deep-emerald
gradient: simple, recognizable at small sizes and culturally neutral.

| Token | Value |
|-------|-------|
| Emerald (primary) | `#0F7A68` → `#07463D` gradient |
| Mint | `#7FE3C1` |
| Gold | `#F5B83D` (rim `#D99A1E`) |

The same palette drives the app themes (`web/src/app/globals.css`,
`mobile/lib/core/theme/app_colors.dart`).

## Single source of truth

`branding/scripts/generate_icons.py` defines the geometry and palette in code and renders every
asset, so each platform uses identical shapes:

| Output | Used for |
|--------|----------|
| `branding/icon/masroof-icon.svg`, `icon-1024.png` | Stores, iOS icon, design tools |
| `adaptive-foreground.png` / `adaptive-background.png` | Android adaptive icon (content scaled to the 66 dp safe circle so any launcher mask keeps it intact) |
| `adaptive-monochrome.png` | Android 13+ themed icons |
| `mark-splash.png`, `mark-splash-android12.png` | Native splash screens (Android 12 variant fits the 768 px visible circle) |
| `logo-tile.png` | In-app logo on light and dark surfaces |
| `web/public/favicon.ico`, `icon.svg`, `icon-192/512.png`, `icon-maskable-512.png`, `apple-touch-icon.png` | Browser tab, PWA and home-screen icons |

## Regenerate

```bash
pip install pillow
python3 branding/scripts/generate_icons.py
cd mobile
dart run flutter_launcher_icons          # Android mipmaps + adaptive XML, iOS AppIcon set
dart run flutter_native_splash:create    # Android (incl. 12+) and iOS splash
```

Configuration lives in `mobile/pubspec.yaml` (`flutter_launcher_icons`, `flutter_native_splash`).
Commit the regenerated files.

## Splash screen

Minimal by design: the mark centered on emerald `#07463D`, followed by the in-app splash with the
Masroof name while the session is restored. No animation delays startup.

## Usage rules

* Keep clear space of at least 25% of the icon size around the mark.
* Do not recolor, rotate, add shadows or place the transparent mark on light backgrounds (its
  wallet is white). Use `logo-tile.png` on light surfaces.
* The Arabic wordmark is **مصروف**, the English one **Masroof**.
