# World

40×40 deterministic grid, center-anchored 96×48 projection. `(x-y)*48,(x+y)*24` maps grid to world. Inverse is `floor(screen_x/96 + screen_y/48 + .5), floor(screen_y/48 - screen_x/96 + .5)`.

Only owned land permits building. The water ribbon occupies tiles with x > 20 near y = 27 + sin(x × .3) × 2. Bridges may occupy water; other structures require grass. Every occupied footprint cell is validated. A structure bordering reachable roads becomes active. Infrastructure overlays communicate road access and Manhattan-radius water, power, health, education and security coverage. Only connected, completed sources provide service.

Rendering uses original procedural shapes, palette by category, growth stages, construction counters, sparse deterministic trees and limited cosmetic residents. Terrain renders in cached 8×8 chunks. Cosmetic NPCs choose housing, commerce, agriculture and industry destinations using reachable-road pathfinding; they have no independent economic brains. District visuals and detailed building-specific artwork remain improvements before production release.
