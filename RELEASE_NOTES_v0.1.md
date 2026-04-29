# Release notes — v0.1.0

> Status: **v0.1.0-rc1 committed**. The `v0.1.0` tag itself lands once the user records `docs/v0.1.0-spike.gif` per spec §10 / §11.

## Scope (Week-1 tech spike)

The single goal of v0.1.0 is to validate that the engine handles isometric coordinate math + click-to-move on a real tilemap with a real sprite. Per `BUILD_PROMPT.md` §10:

> Tech-spike: Godot iso TileMapLayer + click-to-move + Kenney tileset, 1 walking sprite.

If this spike runs cleanly, every subsequent week (loot, inventory, dungeons, classes, bosses) is "just data and gameplay" — a much safer set of risks than coordinate-system bugs.

## What ships in v0.1.0-rc1

### Code

- `scripts/systems/IsoUtils.gd` — autoloaded singleton, `tile_to_world` / `world_to_tile` for 256×128 dimetric tiles. Math concentrated in one file; every other script calls in.
- `scripts/actors/Player.gd` — click-to-move; lerps from current tile center to target tile center; switches Idle ↔ Run animation based on velocity.
- `scenes/levels/SpikeLevel.gd` — procedurally builds an 8×8 dirt floor of `Sprite2D` children using `IsoUtils.tile_to_world`. y-sort enabled.
- `scenes/main/Main.tscn` — boots `SpikeLevel` + `Player`. Project's `application/run/main_scene`.
- `scenes/actors/Player.tscn` — `CharacterBody2D` + `AnimatedSprite2D` + `CollisionShape2D` + `Camera2D` (zoom 0.5× to fit the rendered art).

### Assets

- Kenney Isometric Miniature Dungeon (CC0, 753 files) — used for floor + player sprite.
- LPC Medieval Fantasy Character Sprites (CC-BY-SA 3.0) — vendored only; reserved for later weeks.
- MedievalSharp font (OFL 1.1) — vendored; not yet rendered (HUD ships Week 2+).

### Infrastructure

- `tools/check_licenses.py` — license gate; walks `assets/`, fails if any leaf folder lacks a `LICENSES.md` row.
- `.github/workflows/ci.yml` — matrix build (ubuntu-22.04, windows-latest, macos-latest); installs Godot 4.6, runs license gate, exports headless binaries, uploads artifacts. Tag `v*` → draft GitHub Release with all three binaries.
- `BUILD_PROMPT.md` — full spec saved verbatim per §14 ("save a copy alongside the game repo so future contributors and Claude Code sessions have a single source of truth").

## Approved deviations from `BUILD_PROMPT.md`

See `README.md` § "Deviations from BUILD_PROMPT.md" — there are five. Summary:

1. Godot 4.6 instead of 4.3 LTS (already installed on dev box).
2. Kenney "Isometric Miniature Dungeon" replaces the renamed "Isometric Dungeon".
3. Tile size 256×128 instead of 64×32 (rendered Kenney art, not pixel art).
4. CC-BY-SA 3.0 admitted alongside spec §3.1's CC0/CC-BY/OFL/MIT, for the LPC carve-out called for in §3.2.
5. Sprite2D-based procedural floor instead of TileMapLayer + TileSet.tres (TileMapLayer authoring deferred to Week 2).

## Definition of Done — spike level

Mechanically verifiable in this commit:

- [x] `godot --headless --import` exits 0
- [x] `python3 tools/check_licenses.py` exits 0
- [x] `godot --headless --quit-after 5 res://scenes/main/Main.tscn` shows no `ERROR:` lines
- [x] Repo structure matches `BUILD_PROMPT.md` §2.4
- [x] Every asset leaf folder is attributed in `LICENSES.md`

User-driven (still required to mint `v0.1.0`):

- [ ] Open Godot 4.6 editor, run `Main.tscn`
- [ ] Click on tiles — character walks to the clicked tile, depth-sort correct
- [ ] Record `docs/v0.1.0-spike.gif` (≥ 30 seconds)
- [ ] `git tag v0.1.0` and push

## What does NOT ship in v0.1.0

Everything else in the spec — combat, loot, inventory, dungeons, biomes, classes, bosses, endgame, settings, accessibility checklist. Each is its own milestone in `BUILD_PROMPT.md` §10.

## Changelog

- Initial commit. Project bootstrap.
