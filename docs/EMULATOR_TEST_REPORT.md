# Android emulator audit — 2026-10-25

## Device and build

- `Kampung_QA`: Android 17 / API 37, arm64, landscape 2400 × 1080.
- Installed `build/android/kampung-simulator-debug.apk` after the 3D rebuild. The debug APK and AAB passed package verification.
- The emulator uses virtual graphics hardware; its memory and timing are not representative of a physical phone.

## Verified behavior

- Game launched and rendered the 3D village, buildings, residents, field, trees, weather, HUD and controls. See `build/screenshots/android-final-3d.png`.
- Touch selected the rice field and opened its action panel. See `build/screenshots/android-final-field.png`.
- Harvest action changed the field's persisted crop state to `HARVESTED` in `files/village.json`. The save remained schema v3, and the application resumed after Home.
- Android Back opened the main menu without closing the app on the retest. See `build/screenshots/android-final-back-retest.png`.
- The menu hid gameplay controls, and Continue returned to gameplay.
- Godot log after final launch showed a shader cache recompile warning; no script exception or Android fatal exception was observed during these checks.

## Measured limits

- One `dumpsys meminfo` snapshot showed total PSS of 189,095 KiB (about 185 MiB). This is a point measurement, not a memory stability test.
- No trustworthy Godot frame rate, thermal or battery measurement was obtained. Android `gfxinfo` describes View frames and is not a Godot 3D FPS benchmark.
- Automated local tests cover the gameplay model (2,403 assertions) and UI wiring (11 panels in both languages). Emulator interaction covered the concrete actions above; every catalog entry and long play session were not manually exercised.

## Visual assessment

The new scene is genuine 3D and more legible than the previous flat map. Building silhouettes, tools and residents are recognizable. The current procedural meshes and simple character motion remain visibly low poly, and the painted menu illustration has a different level of detail from live gameplay. A premium result still needs authored art direction, richer materials, character animation and physical-device performance tuning.
