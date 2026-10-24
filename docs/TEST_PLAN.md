# Test plan

Executed headless suite: grid round trips over all 1,600 cells, footprint bounds/occupancy, construction and road access, transactional purchases/sales, insufficient resources, warehouse cap, recipe inputs/output, crop stages and fertilizer, animal purchase/feed/collection, housing/employment/food/migration, quests and duplicate claims, dependencies, progression/prestige, save roundtrip/backup/corruption/schema/overlap validation, clock rollback/offline cap, disabled/verified/double ad callbacks, and 60-day economic smoke simulation.

`tests/ui_smoke.gd` instantiates the real scene, opens all 11 panels, asserts content exists and captures a rendered frame. This verifies scene/resource wiring rather than human usability. Run with a display (or Xvfb); its frame-post-draw wait requires rendering.

Before release: physical entry-level Android phone, install/start, airplane-mode farming/trading/reload, multitouch zoom and camera, notches/safe areas, language, TalkBack/readability, audio settings, 30 minute play, memory/thermal/FPS, repeated pause/resume, process kill during save, upgrade install and save migration. No physical device testing has yet been performed. Emulator results, if executed, are recorded separately in PROGRESS.md.

Additional executed checks: malformed nested save types and unknown technologies, interrupted first-save recovery, crop moisture pause/watering, feed processing, occupancy invalidation, bounded local water/education coverage, disconnected service inactivity, shortest road paths and v2-to-v3 road access migration. Final suite: 2,378 checks.

UI regression also emulates touch on desktop, swipes through the actual build catalog and checks that no building is selected accidentally. The APK was verified on the emulator: a swipe over buttons scrolls the field panel; harvesting then persists eight paddy, 39 seeds and 24 XP. Automated UI failures terminate with a nonzero exit code.
