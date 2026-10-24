# World

40×40 deterministic grid, center-anchored 96×48 projection. `(x-y)*48,(x+y)*24` maps grid to world. Inverse is `floor(screen_x/96 + screen_y/48 + .5), floor(screen_y/48 - screen_x/96 + .5)`.

Only owned land permits building. The water ribbon occupies tiles with x > 20 near y = 27 + sin(x × .3) × 2. Bridges may occupy water; other structures require grass. Every occupied footprint cell is validated. A structure bordering reachable roads becomes active. Infrastructure overlay currently communicates road access; individual water/electricity radius overlays are future work.

Rendering uses original procedural shapes, palette by category, growth stages, construction counters, sparse deterministic trees and limited cosmetic residents. Terrain chunks, district visuals, detailed NPC route purposes and building-specific artwork remain improvements before production release.
