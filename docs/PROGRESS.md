# Progress — 2026-10-24

## Audit

Workspace was empty. Official repository `ahmadhamdani-L/kampung-simulator` was empty (`isEmpty=true`, default branch ref blank); cloned it and retained Git's initial `main`. There was no remote default branch to infer. Godot 4.7.2 and JDK 17 were installed; Android SDK already existed. Read only top-level Android Gradle repository/build conventions in MINDORA and UNTUNGKUPRO; neither project was modified and no signing values were inspected.

## Implemented milestone

Playable isometric world; 52 buildings; farming, livestock and seven processing chains; integer economy and warehouse; roads, housing, workforce/services; research, 28 quests, contracts, 300 levels, prestige and eight achievements; seeded timed events; local versioned atomic saves, backups and capped offline advancement; 11 UI panels; desktop/touch controls; sound buses and original audio/art; disabled ad adapter; content validation; CI validation and debug APK workflows.

## Executed validation

* JSON/content validation: 52 buildings, 28 quests, 300 levels, references and research dependency cycles checked.
* Godot 4.7.2 headless tests: 2,378 assertions, zero failures. Covers world, economy, agriculture, animals, population, research/quests, persistence/migration/offline and ad deduplication.
* 60-day smoke simulation: approximately 300 ms on development Mac, not an Android FPS benchmark.
* Desktop OpenGL UI smoke: all 11 panels loaded; rendered screenshot inspected. Fixed off-screen overlay controls/status.
* Android non-Gradle debug APK exported; apksigner verification and ZIP/ABI/content checks passed. Artifact: `build/android/kampung-simulator-debug.apk`, 59,649,126 bytes at initial export (rebuilds may differ).
* APK template inspected: minimum SDK 24, target SDK 36.

## Remaining / blockers

No project release keystore or production AdMob configuration was provided. Native ads remain excluded; release signing and distribution AAB are unverified. No Play publication attempted. Physical entry-level Android QA and long-term balance are unperformed. English names, UI navigation, crop states and notification translations were expanded; a human localization review remains outstanding. Chunk/index caching, service-radius overlays and road-routed NPCs were added in the second milestone; deeper simulation decomposition, human copy review and production-grade artwork differentiation remain engineering tasks.

## Next exact step

Finish installation/startup/offline/save checks on the newly created Kampung_QA emulator, record results, then address measured lifecycle/input issues. Commit and push the validated development milestone, and continue renderer/persistence/content refinement. Do not call this candidate production ready.

## Second milestone refinement

First milestone pushed to `main`: `2bf2af0bf9a9fb6b6f1828a38b8bd197261a4510`. GitHub validation run 40069833118 passed on Ubuntu. Repository is public.

Added cached 8×8 terrain chunks, O(1) occupancy lookup and per-chunk building indexes; local water/power/service coverage and overlays; corrected road entrance continuity; day/night tint; road pathfinding for limited cosmetic residents; corn-to-feed processing (52 buildings / seven recipes); crop moisture and manual watering; animal health effects; seven multi-objective era quests (28 total); improved English names and notifications; original distinct construction/plant/harvest/trade/level/quest audio plus rain ambience and master volume. Save validation now rejects malformed nested types, validates resource/technology identifiers and footprints, repairs missing legacy settings/IDs, and recovers valid interrupted first-save temporary files.

Android emulator: created a separate `Kampung_QA` AVD using an existing API 37 arm64 image. APK installation succeeded. Launcher activity is `com.godot.game.GodotAppLauncher`; it starts the GodotApp activity internally. Menu and gameplay rendered. Airplane mode confirmed (`airplane_mode_on=1`); touch selected the field and planted one seed. Backgrounding wrote crop `GROWING`, progress 1, seeds 39. Force-stop/relaunch restored crop `READY`, seeds still 39, offline delta 27 seconds. This tests emulator lifecycle/stock persistence, not physical hardware performance.

Development AAB Gradle export succeeded. Initial debug bundle was unsigned; build tooling now explicitly signs development bundles with the isolated project debug identity and checks JAR signatures and bundle structure. Google bundletool 1.18.3 validation passed on the development bundle. Release APK/AAB presets and a secret-gated manual CI release path are prepared but have not been executed with a release identity.

Final regression suite after refinements: 2,378 checks, zero failures. One new infrastructure fixture initially placed a school adjacent to an existing road; corrected its location to test genuinely disconnected coverage. A duplicate test-local variable was also corrected before rerunning. Save schema is now v3; migration adds the missing entrance connector only for the former exact starter layout, preserving v2 farm road access after upgrading.

Final-source APK installed over the prior candidate successfully. On launch, the saved schema became v3, the missing starter connector appeared and the 39-seed inventory was preserved. Both APK and AAB declare no requested Android permissions. The AAB passed bundletool validation again after rebuilding; the non-Gradle APK has a non-blocking themed-launcher resource warning documented in IMPLEMENTATION_REPORT.md.

UI smoke now exercises all 11 panels in both Indonesian and English. Shell build scripts passed `bash -n`; both workflow YAML files parsed successfully. No physical-device FPS/memory claim is made.

Second milestone source pushed: `c35e96c74e63cf18b70a4a6006affbb5c8321202`. Ubuntu validation run 40070626330 passed. First Android CI attempt 40070628051 failed before reaching the game build because setup-android v3 defaults to the obsolete SDK package `tools`; the workflow now explicitly requests `platform-tools` and suppresses verbose license text. Re-running the corrected workflow is the next CI check.

Touch follow-up: emulator swipes over child buttons initially failed to scroll long menus. Gameplay button/container mouse filters now pass drag events to ScrollContainer; text labels ignore pointer capture. The UI regression enables desktop touch emulation explicitly, swipes the real build catalog, checks that scrolling occurred and verifies no building was selected accidentally. It now exits nonzero on failed checks instead of leaving a running test scene. The updated APK was reinstalled; an actual emulator swipe revealed the harvest action, which was tapped successfully. Background save recorded HARVESTED, eight paddy, 39 seeds and 24 XP. Both bilingual panel and touch scrolling smoke checks pass.

## Third milestone refinement: copy review, cultural visual art & progression tests

- Replaced 51 identical boilerplate descriptions in `data/buildings.json` with authentic, culturally grounded Indonesian and English copy for each of the 52 buildings.
- Refined quest titles in `data/quests.json` and introduced clean bilingual objective lines in `scripts/core/game.gd` replacing raw developer keys.
- Localized achievements in Indonesian and English with descriptive text.
- Integrated `DisplayServer.get_display_safe_area()` padding in `game.gd` to protect top HUD and bottom navigation controls from mobile camera cutouts and display notches.
- Enhanced procedural rendering in `scripts/world/world_view.gd`: Balai Desa features a tiered Joglo roof, tiang pendopo and flagpole; roadside Warung displays a striped awning canopy; aquaculture ponds (catfish/tilapia) feature animated swimming fish streaks; clinics and hospitals display medical emblems; schools display flagpoles; utilities display distinct visual markers.
- Expanded headless regression suite in `tests/run.gd` with multi-era progression testing covering pioneer setup, commerce, research, land expansion, and mid-era stability. Test suite expanded to 2,403 checks with 0 failures. UI smoke suite passes cleanly.

## Third milestone verification

- Content validation passed: 52 buildings, 28 quests and 300 levels. Godot headless suite passed 2,403 checks with zero failures; desktop UI smoke loaded all 11 panels in both languages and passed touch scrolling checks.
- Rebuilt debug APK and development-signed AAB from the third milestone source. APK signing/package checks, AAB signing/package checks and bundletool validation passed. Exact artifact hashes and source commit are recorded in ignored `build/android/artifacts.json`.
- Prior commit `924dc43` passed both GitHub validation (run 40070845307) and Android (run 40070859895) workflows. Third milestone workflow results should be checked after pushing this commit.
