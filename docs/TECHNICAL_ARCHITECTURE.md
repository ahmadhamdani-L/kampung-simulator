# Technical architecture

Godot 4.7.2 stable, GDScript, Compatibility renderer. No backend, login, analytics or native ad plugin.

`VillageSimulation` is a RefCounted, scene-independent aggregate owning a JSON-compatible state dictionary and seeded RNG. It implements transactional commands and fixed one-second simulation steps. It loads content definitions once. Scene code receives explicit references rather than autoloads. Presentation never grants rewards directly.

`VillageWorld` projects integer grid coordinates with 96×48 diamond tiles; inverse mapping rounds around tile centers. Terrain and building footprint checks are separate. Terrain is deterministic. Access uses a breadth-first road traversal; changes invalidate the connectivity cache. Aggregate population drives the economy; at most 12 cosmetic residents render. Construction blocks operations until complete. Structures are sorted by grid diagonal.

`game.gd` orchestrates scene lifecycle, world commands, touch/desktop UI, audio and save scheduling. `VillageSave` owns JSON validation, schema migration, atomic replacement and valid backup recovery. `VillageAds` is disabled by default and owns pending native callback tokens; it is not an AdMob integration.

The initial aggregate deliberately keeps gameplay commands in one simulation module so headless tests cover exactly the same code used by the scene. Splitting economy, population, progression and agriculture into injected submodules, indexed occupancy and chunk render caches remains a scalability task. Current drawing walks 1,600 terrain tiles each frame; no claim of low-end Android performance is made.

Persistence uses state version 2; v1 merges missing defaults then migrates animal fields. Elapsed wall time is clamped to 0–7,200 seconds. Future saved wall times are preserved to avoid granting the same time after a rollback. A load is checkpointed at startup/resume. Local saves cannot offer tamper-proof accounting on a rooted/user-controlled device.
