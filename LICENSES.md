# LICENSES

Mandatory third-party attribution table for HOLLOWFANE.
**Every leaf folder under `assets/` MUST have at least one row here.**
CI (`tools/check_licenses.py`) fails the build if this invariant is violated.

## Asset attribution table

| Asset | Author | License | Source URL | SHA-256 of source archive | Used in |
|---|---|---|---|---|---|
| Isometric Miniature Dungeon | Kenney Vleugels (kenney.nl) | CC0 1.0 | https://kenney.nl/assets/isometric-miniature-dungeon | `187a0888451317fe47caac5f26e984bb79c5ddce9b8630926f0f5d9c0247d343` | `assets/tiles/kenney_iso_miniature_dungeon/` |
| LPC Medieval Fantasy Character Sprites | wulax (and OGA contributors) | CC-BY-SA 3.0 + GPL 3.0 + OGA-BY 3.0 (we apply CC-BY-SA 3.0) | https://opengameart.org/content/lpc-medieval-fantasy-character-sprites | `709896aa94fd9f190934901065f0e8f0bf74ca8a258b4160d1bff9af803a1db9` | `assets/sprites/lpc_entry/` |
| MedievalSharp | Evanh Gultom (Kludgy Fonts) | OFL 1.1 | https://fonts.google.com/specimen/MedievalSharp | TTF `74cb2e6738bd7703adf120802f68fba0c9ddb9147a08e6847f1005b1e55df5a5` / OFL `45b1f44d2cb859ea4b7be2f322c57b8ff7be55075c336744e62b5550cd0a97eb` | `assets/fonts/medievalsharp/` |

## Per-folder license map

The CI gate parses the `Used in` column above. Each folder below must appear in that column at least once.

```
assets/tiles/kenney_iso_miniature_dungeon/   → CC0       (Kenney)
assets/sprites/lpc_entry/                    → CC-BY-SA  (LPC, multi-licensed)
assets/fonts/medievalsharp/                  → OFL       (Google Fonts)
```

## License compatibility notes

- **CC0** assets place no obligations on us; we still attribute as best practice.
- **CC-BY-SA 3.0 (LPC)** requires *derivatives of those specific assets* to remain CC-BY-SA. It does NOT relicense unrelated game code or other-licensed assets. Modified LPC sprites must ship with attribution + the SA notice.
- **OFL 1.1 (MedievalSharp)** allows bundling the font in a game without making the game OFL. We must not sell the font as a standalone product, and the OFL.txt must travel with the TTF.

## Usage in v0.1.0-rc1 (Week-1 spike)

- Floor + character sprites: Kenney Isometric Miniature Dungeon (`Characters/Male/`, `Isometric/dirt_E.png`).
- Font: not yet rendered to screen (HUD lands Week 2+).
- LPC: vendored only — not used at runtime in v0.1.0. Reserved for sprite variety in later weeks.

## Future asset additions checklist

When vendoring a new pack:
1. Create `assets/<category>/<pack_slug>/` (snake_case, prefix with author when ambiguous).
2. Compute SHA-256 of the source zip/file: `sha256sum <file>`.
3. Add a row to the table above with the source URL and SHA.
4. Add the folder to the per-folder license map.
5. Run `python3 tools/check_licenses.py` locally — must exit 0.
6. Commit the asset folder + this file in the same commit.

## In-game attribution screen

For CC-BY / CC-BY-SA assets, an **Attributions** screen reachable from the main menu is required (per spec §3.6). This screen lands in Week 2 with the menu UI; for v0.1.0-rc1 (no menu), this `LICENSES.md` file is the authoritative attribution.
