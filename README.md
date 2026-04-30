# HOLLOWFANE

A single-player isometric action-RPG in the Diablo / Path-of-Exile lineage.
Open-source assets only. Built in Godot 4.6.

> Status: **v1.0.0** — full 12-week milestone schedule shipped. Three-act campaign
> (Whitestone → Catacombs → Frostvein → Cinderfall Spire) plus the endless Echo
> endgame. Four playable classes (Hollowbinder / Furyborn / Frostmark / Sealwarden).
> See `RELEASE_NOTES_v1.0.md` for the full ship list and `BUILD_PROMPT.md` for
> the original spec.

## Features

- **Three-act story campaign** ending in a final boss + cutscene.
- **Procedural BSP dungeons** for Catacombs, Frostvein, Cinderfall, and the Echo, with flood-fill validation so every map is fully connected.
- **D2-flavored loot system** — Common / Magic / Rare / Unique / Mythic, prefix + suffix affix rolls, fixed-flavor uniques, gem sockets.
- **Imbuement crafting** — sacrifice 3 items of one slot for a fresh Magic-or-Rare.
- **Endless Echo endgame** — tier-scaled mob and boss stats, Pinnacle bosses every 3 tiers, Echo Sigils to push deeper.
- **Four classes** — Hollowbinder (default), Furyborn, Frostmark, Sealwarden (unlocks on first Pinnacle kill).
- **Full HUD** — D2-style HP orb, 4-skill hotbar, click-driven inventory, paper-doll character sheet, quest log.
- **Settings + accessibility** — master volume, fullscreen, color-blind preset, font scale, Hardcore mode.
- **JSON save/load** with `schema_version` migration seam.
- **CI matrix** for Linux / Windows / macOS exports + license-gate.

## Controls

| Input | Action |
|---|---|
| Left-click on tile | Move-to-tile |
| Left-click on enemy | Basic attack |
| Left-click on ground item | Pick up into inventory |
| Left-click on inventory cell | Equip (or consume sigil) |
| Left-click on paper-doll slot | Unequip back to inventory |
| Left-click on NPC | Talk / open shop panel |
| Left-click on portal tile | Travel to that scene |
| `1` / `2` / `3` / `4` | Activate hotbar skill |
| `I` | Toggle Inventory |
| `C` | Toggle Character |
| `Q` | Toggle Quest Log |
| `Esc` | Close any open panel; otherwise open Settings |
| `F5` | Quick save |
| `F9` | Quick load |

## Build from source

```bash
git clone https://github.com/Ryvos/hollowfane.git
cd hollowfane

# Open in editor
godot --editor

# Or run headless
godot --headless --import
godot --headless --quit-after 5 res://scenes/main/Main.tscn

# License gate (CI requires this to be green before release tags)
python3 tools/check_licenses.py

# Bot-play crash harness (spec §11 DoD)
godot --headless -s tools/bot_play.gd -- --duration=60
```

To build the platform binaries you need **Godot 4.6 export templates**
installed locally. CI handles this automatically; for a local export run
`godot --headless --export-release "Linux/X11" build/linux/HOLLOWFANE.x86_64`
once templates are in `~/.local/share/godot/export_templates/4.6.stable/`.

## Project layout

```
hollowfane/
  project.godot          # Engine config; SOURCE OF TRUTH for version
  export_presets.cfg     # Linux / Windows / macOS export targets
  BUILD_PROMPT.md        # The full game spec — read this first
  LICENSES.md            # Mandatory third-party asset attribution table
  RELEASE_NOTES_v*.md    # Per-milestone notes; CI reads these into GH Releases
  scenes/                # *.tscn — actors, levels, ui, fx, main
  scripts/               # *.gd — actors, systems, levels, ui
  assets/                # Vendored CC0/CC-BY/OFL/MIT assets only
  data/                  # JSON: items, affixes, uniques, gems
  tools/check_licenses.py# CI license-gate
  tools/bot_play.gd      # Randomized-input crash harness
  .github/workflows/     # CI matrix
```

## Deviations from `BUILD_PROMPT.md`

The five spec deviations approved during the v0.1.0-rc1 plan still apply at v1.0.0:

1. **Engine version** — Godot 4.6 instead of 4.3 LTS.
2. **Tile pack rename** — `Isometric Miniature Dungeon` (renamed slug, still CC0).
3. **Tile size** — 256×128 isometric (rendered low-poly), not 64×32 pixel-art.
4. **LPC under CC-BY-SA 3.0** — admitted per §3.2 with the per-folder license carve-out.
5. **Sprite2D-per-tile rendering** instead of `TileMapLayer` + `TileSet.tres`. Hand-authoring isometric TileSets outside the editor is brittle; the BSP dungeon and the hub both render fine on per-tile sprites at the scales we ship. Migrating to TileMapLayer is a transparent swap when the editor pipeline is in flow.

## Open-source asset hygiene

Every leaf folder under `assets/` MUST have a row in `LICENSES.md`. CI fails
the build otherwise (`tools/check_licenses.py`).

Allowed: CC0, CC-BY 4.0, CC-BY-SA 3.0 (LPC carve-out), OFL 1.1, MIT, Apache-2.0.
Forbidden: GPL-only, CC-NC, CC-ND, unlicensed, AI-generated, ripped commercial.

## License

Game code: **MIT** (see `LICENSE`).
Game assets: per-folder — see `LICENSES.md`.
