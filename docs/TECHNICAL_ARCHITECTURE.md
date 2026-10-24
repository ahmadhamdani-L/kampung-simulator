# Technical architecture

Godot 4.7.2 stable, GDScript, Compatibility renderer. No backend, login, analytics or native ad plugin.

`VillageSimulation` is a RefCounted, scene-independent aggregate owning a JSON-compatible state dictionary and seeded RNG. It implements transactional commands and fixed one-second simulation steps. It loads content definitions once. Scene code receives explicit references rather than autoloads. Presentation never grants rewards directly.

`VillageWorld` projects integer grid coordinates with 96×48 diamond tiles; inverse mapping rounds around tile centers. Terrain and building footprint checks are separate. Terrain is deterministic. Access uses a breadth-first road traversal rooted at the village hall; changes invalidate connectivity and occupancy caches. Aggregate population drives the economy; at most 12 cosmetic residents render. Construction blocks operations until complete. Structures are sorted by grid diagonal.

`game.gd` orchestrates scene lifecycle, world commands, touch/desktop UI, audio and save scheduling. `VillageSave` owns JSON validation, schema migration, atomic replacement and valid backup recovery. `VillageAds` is disabled by default and owns pending native callback tokens; it is not an AdMob integration.

The aggregate keeps gameplay transactions in one simulation module so headless tests cover the same commands used by the scene. VillageGrid indexes occupancy and 8×8 building chunks. VillageTerrainChunk caches static drawing in 25 CanvasItems and redraws on land changes; dynamic world objects redraw separately. VillageInfrastructure calculates bounded local services; VillagePathfinder computes cached road routes for at most 12 visible residents. Further decomposition remains optional as content grows. Physical low-end Android rendering performance is unmeasured.

Persistence uses state version 3; v1 merges missing defaults and animal fields; v2-to-v3 migration repairs the former starter road entrance while preserving occupied cells. Elapsed wall time is clamped to 0–7,200 seconds. Future saved wall times are preserved to avoid granting the same time after a rollback. A load is checkpointed at startup/resume. Local saves cannot offer tamper-proof accounting on a rooted/user-controlled device.
