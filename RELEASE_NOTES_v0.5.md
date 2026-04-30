# Release notes — v0.5.0

> Status: **shipped**. Week 5 of the 12-week milestone schedule.

## Scope (per BUILD_PROMPT.md §10)

> BSP procedural dungeon generator + Catacombs biome (Kenney tiles) + lighting.

## What ships

### Code

- `scripts/levels/BSPDungeon.gd` — pure-data BSP generator. `BSPDungeon.generate(seed, width, height)` returns a Dictionary with `rooms`, `corridors`, `floor_tiles`, `entrance`, `exit`, `room_centers`, and the echoed `seed`. Recursively splits the bounding rect on the longer axis until depth or size limits trip; each leaf places a randomly-shrunken room; sibling rooms are joined by an L-corridor between random descendants of their two subtrees. Deterministic from `seed` — required for spec §8 save-loading.
- `scripts/levels/FloodFill.gd` — 4-connected reachability check on a tile-set Dictionary. `validate(start, walkable)` returns true iff every walkable tile is reachable from start; `unreachable_count(start, walkable)` reports how many tiles are stranded (used to push_warning when an unwinnable seed slips through).
- `scripts/levels/Catacombs.gd` — orchestrates the biome:
  - generates a 28×28 BSP dungeon (typically 8–12 rooms),
  - renders a `Sprite2D` per floor tile (Kenney `dirt_E.png`),
  - renders a `Sprite2D` wall on every tile adjacent to a floor but not itself walkable (Kenney `stoneWallAged_E.png`), y-sorted so the player can pass behind walls,
  - adds a `CanvasModulate` for the cold-blue ambient (spec §4.5),
  - drops a `PointLight2D` at every room center using a programmatically-built radial `GradientTexture2D` (no asset dep, no shader),
  - flood-fill validates the level and `print`s `Catacombs seed=N: R rooms, T tiles, fully connected.` (or `push_warning`s if any tile is stranded),
  - defers `_place_player` and `_spawn_enemies` so they run after every sibling's `_ready`,
  - skips the entrance room when scattering enemies — the player gets a moment before the first fight.
- `scripts/actors/Player.gd` — added `set_spawn_tile(tile)`. Levels call this so the death/respawn position tracks the level's intended start instead of being locked to `(0, 0)`.

### Scenes

- `scenes/levels/Catacombs.tscn` — `Node2D` with `y_sort_enabled` and the script attached.
- `scenes/main/Main.tscn` — now instances `Catacombs` instead of the v0.1.0 `SpikeLevel`.

### Config

- `project.godot` — `application/config/version` bumped to `0.5.0`.

## Behavior

- Boot → 10-ish rooms procedurally laid out, every tile reachable from the entrance.
- Player spawns at the entrance; respawn after death also goes to the entrance, not the legacy `(0, 0)`.
- 5–6 enemies scattered across non-entrance rooms; each room is its own pocket of light against a cold-blue ambient.
- Console line on boot: `Catacombs seed=N: R rooms, T tiles, fully connected.` — useful for repro if a seed ever produces something pathological.

## Verification

- `python3 tools/check_licenses.py` → exit 0
- `godot --headless --import` → exit 0, no warnings, no `SCRIPT ERROR`
- `godot --headless --quit-after 8 res://scenes/main/Main.tscn` → "Catacombs seed=12876480: 10 rooms, 354 tiles, fully connected." with no `ERROR:` lines

## Deferred to later weeks

- Real `TileSet.tres` resource (spec called for it Week 5). Hand-authoring an isometric TileSet outside the editor is brittle (atlas metadata + per-cell offsets); instead it lands Week 6 alongside the hand-authored Whitestone hub, where the editor-driven asset pipeline is the natural place to bring it in. Sprite2D-per-tile rendering works for ~800 tiles per dungeon; replacing it with TileMapLayer is a transparent swap (the BSP layout already speaks tile coordinates).
- `LightOccluder2D` on walls — currently lights pass through walls visually. Adding occluders to every wall sprite is fiddly and noisy on a procedurally-rebuilt scene; will land Week 6 alongside the proper TileMapLayer where occluder polygons live in the TileSet.
- Player follow-light (the player carries a small light wherever they walk). Rooms cover the dungeon for now; deferred to Week 6 polish.
- Boss room marker / mini-boss spawn at the BSP exit room — Week 6 (Hollow Bishop).
- Per-biome ambient tints (Frostvein pale teal, etc.) — Week 7.
- Cellular-automata cave variant per spec §4.5 — second algorithm becomes useful once we have a second biome (Frostvein) to differentiate from the Catacombs structured layout.
- `LPC` sprite integration (currently using Kenney male sprites for both player and enemies). LPC cleanup happens when class portraits arrive Weeks 7–9.
- `SpikeLevel.gd` + `SpikeLevel.tscn` are still in the repo as reference; they no longer boot. Will be deleted alongside the Week 6 hub work.
