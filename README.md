# HOLLOWFANE

A single-player isometric action-RPG in the Diablo / Path-of-Exile lineage.
Open-source assets only. Built in Godot 4.6.

> Status: **v0.1.0-rc1** — Week-1 tech spike (TileMapLayer + click-to-move).
> Not yet a release. See `RELEASE_NOTES_v0.1.md` and `BUILD_PROMPT.md` (§10) for the milestone schedule.

## Controls (current spike)

| Input | Action |
|---|---|
| Left-click on tile | Move-to-tile |
| `Esc` | Quit |

The full control scheme (skill bar, inventory, hotkeys) lands in later milestones — see `BUILD_PROMPT.md` §4.1.

## Build from source

```bash
git clone <this-repo> hollowfane
cd hollowfane

# Open in editor (recommended for the spike)
godot --editor

# Or run headless to verify imports parse
godot --headless --import
godot --headless --quit-after 5 res://scenes/main/Main.tscn

# CI license gate (required before release tags)
python3 tools/check_licenses.py
```

Requires **Godot 4.6** (works with 4.3 LTS too — see deviation note below).

## Project layout

```
hollowfane/
  project.godot          # Engine config; SOURCE OF TRUTH for version
  BUILD_PROMPT.md        # The full game spec — read this first
  LICENSES.md            # Mandatory third-party asset attribution table
  RELEASE_NOTES_v*.md    # Per-milestone notes; CI reads these into GH Releases
  scenes/                # *.tscn — actors, levels, ui, fx, main
  scripts/               # *.gd — actors, systems, ui (level scripts co-locate w/ scene)
  assets/                # Vendored CC0/CC-BY/OFL/MIT assets only
    tiles/<pack>/
    sprites/<pack>/
    fonts/<pack>/
    audio/{music,sfx,ambient}/
  data/                  # JSON/CSV: items.json, affixes.json, monsters.json, ...
  shaders/               # *.gdshader
  tools/check_licenses.py# CI license-gate
  .github/workflows/     # CI matrix
```

## Deviations from `BUILD_PROMPT.md`

Three spec deviations were approved during the v0.1.0-rc1 plan. They live here so future contributors don't trip on them:

1. **Engine version** — pinned to **Godot 4.6** instead of 4.3 LTS (locally installed). `TileMapLayer` exists in both. CI installs 4.6.
2. **Tile pack** — `kenney.nl/assets/isometric-dungeon` (spec §3.2) was renamed/reorganized; the equivalent current pack is `Isometric Miniature Dungeon` (still CC0). Vendored to `assets/tiles/kenney_iso_miniature_dungeon/`.
3. **Tile size** — spec §4.1 expected pixel-art 64×32. Kenney "Isometric Miniature" tiles are rendered 3D at 256×128 footprint. `IsoUtils.TILE_W = 256, TILE_H = 128`. Visual style shifts from pixel-art to rendered-low-poly; iso math is identical.
4. **LPC under CC-BY-SA 3.0** — spec §3.1 lists allowed licenses as CC0/CC-BY/OFL/MIT, but §3.2 lists LPC under CC-BY-SA. CC-BY-SA only requires *derivatives of those assets* to remain CC-BY-SA — it does not viral-license the whole game. We honor §3.2 and ship LPC under CC-BY-SA. See `LICENSES.md` for the per-folder license map.
5. **Spike implementation choice** — for v0.1.0 only, `SpikeLevel.gd` builds a procedural floor of `Sprite2D` nodes instead of a `TileMapLayer` + `TileSet.tres` resource. The math the spike validates (tile↔world conversion, iso click-to-move) is identical. Proper `TileMapLayer` arrives in Week 2 when the asset count justifies editor authoring.

## Open-source asset hygiene

Every leaf folder under `assets/` MUST have a row in `LICENSES.md`. CI fails the build otherwise (`tools/check_licenses.py`). New asset → add the row in the same commit.

Allowed: CC0, CC-BY 4.0, CC-BY-SA 3.0 (LPC carve-out), OFL 1.1, MIT, Apache-2.0.
Forbidden: GPL-only, CC-NC, CC-ND, unlicensed, AI-generated, ripped commercial assets.

## License

Game code: **MIT** (see `LICENSE` — TBD before v1.0).
Game assets: **per-folder** — see `LICENSES.md`.
