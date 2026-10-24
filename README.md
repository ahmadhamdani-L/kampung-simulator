# Kampung Simulator: Dari Desa Jadi Kota

Offline Godot 4.7.2 / GDScript village builder for Android, with a procedural 3D village, animated residents and synthesized audio. Development candidate, **not a verified production release**.

## Play

Open `project.godot` in Godot 4.7.2 and press F6 on `scenes/game/game.tscn` (or F5). Choose **Lanjutkan**. Drag the map, wheel/pinch to zoom. Tap a field to plant, wait for its gold harvest indicator, then harvest and sell in **Ekonomi**. Follow **Misi**, buy seeds, extend roads and add homes, production and services. Buildings without road access remain inactive. Use the road overlay to inspect access. **Esc / Android Back** cancels placement. Autosave runs every 30 seconds; settings also offer manual save.

## Implemented

* 40×40 logical world, expandable owned land, multi-tile placement, construction and upgrades, roads and access graph.
* 52 data-defined buildings, seven crops, six livestock producers, seven processing recipes, warehouse and trading.
* Integer currency and stock, prices, food, housing, workforce, taxes, maintenance, happiness, public services, water and power.
* Seven technologies, 28 ordered quests, repeatable market contracts, eight achievements, 300 levels / seven eras, prestige.
* Seeded weather/events, local versioned atomic saves, backup recovery, migrations and capped offline progress.
* Touch/desktop controls, 11 gameplay panels, Indonesian/English interface choices, audio settings and reduced motion.
* Ad-free platform boundary with verified callback token/deduplication tests. No native advertising SDK bundled.

## Validate

```sh
python3 tools/validate_content.py
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/run.gd
godot --path . --script tests/ui_smoke.gd
```

The UI test creates `build/screenshots/gameplay.png`. See [test plan](docs/TEST_PLAN.md), [Android build instructions](docs/ANDROID_BUILD.md), and [current progress](docs/PROGRESS.md). Generated binaries, tool installations, save files and signing material are excluded from Git.

## Android

Install matching export templates, JDK 17 and Android SDK. Set `JAVA_HOME`, `ANDROID_HOME`, and optionally `GODOT_BIN`; then run `tools/build/android.sh`. It creates a project-specific debug signing identity under ignored `.tools/` and verifies the APK. Application ID is provisional until Play Console registration. Nothing publishes to Google Play.

## License and attribution

See [asset attribution](docs/ASSET_ATTRIBUTION.md). The menu image was generated for this project; all world shapes, icon and synthesized audio were created in this repository. Godot is MIT licensed; engine notices remain in its exported runtime. No assets or secrets were copied from reference projects.
