# BUILD PROMPT — HOLLOWFANE (working title)

> A single-player isometric action-RPG in the Diablo / Path-of-Exile lineage. Open-source assets only. 10+ hour main story, infinite endgame loop. Built in Godot 4.3 LTS.

Paste the **§13 START block** at the bottom into your build agent. Everything above it is the spec your agent should treat as ground truth.

> **Implementation note (added during v0.1.0-rc1 bootstrap):** five approved deviations from this spec are documented in `README.md` § "Deviations from BUILD_PROMPT.md". They are: Godot 4.6 instead of 4.3 LTS, Kenney pack rename to `Isometric Miniature Dungeon`, tile size 256×128, CC-BY-SA 3.0 admitted alongside §3.1's allowed list (per LPC carve-out in §3.2), and Sprite2D-based procedural floor for the spike instead of TileMapLayer + TileSet.tres. The body of this spec is preserved verbatim below.

---

## 1. What you are building

A top-down 3/4-perspective isometric ARPG. Single-player. Mouse-driven (click-to-move + skill hotbar). Loot-driven progression with rarity tiers. Three classes at launch + one unlockable. Three-act campaign with one boss per act + a final boss + an endless endgame dungeon ("The Echo"). Procedural dungeons stitched from authored rooms.

**Target playtime**:
- Main path: **10–12 hours** for a competent player
- + side content: 5–10 hours
- + endgame loop: indefinite (sigil tiers, leaderboard-able)

**Working title**: HOLLOWFANE. Pick your own — keep it ≤ 12 chars so it fits on a save banner.

**Platforms**: Linux (x86_64), Windows (x86_64), macOS (Apple Silicon + Intel). No mobile, no console at launch.

**Anti-goals (do not build these)**:
- Online-only / always-online DRM
- Microtransactions, lootboxes, season passes
- Telemetry / analytics phoning home
- Multiplayer (defer to v2.0 if at all)
- Voice acting (text-only ships)

---

## 2. Tech stack — locked

### 2.1 Engine: **Godot 4.3 LTS** (MIT)

Why:
- Native `TileMapLayer` with isometric mode since 4.0
- Free, no royalties, MIT license — your binaries can be sold or open-sourced
- GDScript iterates fast; C# available for hot paths if profiling demands
- Built-in `Light2D` + `CanvasItem` shaders give the dark-fantasy mood without a custom renderer
- One-line export to all three desktop OSes via headless CLI

### 2.2 Language: **GDScript** primary, **C#** for inner loops only if profiler says so

### 2.3 Tooling

- **Source control**: git, GitHub
- **CI**: GitHub Actions, matrix `ubuntu-22.04 / windows-latest / macos-latest`
- **Export**: `godot --headless --export-release "<preset>" <out>`
- **Versioning**: SemVer; single source of truth = `project.godot` `application/config/version`
- **Release notes**: `RELEASE_NOTES_v<X.Y>.md` per minor; CI reads these into the GitHub Release body
- **Issue tracking**: GitHub Issues + Projects board

### 2.4 Repo layout

```
hollowfane/
  project.godot
  scenes/
    actors/        # Player.tscn, Enemy_*.tscn
    levels/        # Town_*.tscn, Dungeon_*.tscn
    ui/            # HUD.tscn, InventoryPanel.tscn, ...
    fx/            # particles, hit-flashes
  scripts/
    actors/
    systems/       # LootRoller, AffixTable, SaveSystem, ...
    ui/
  assets/
    sprites/       # all imported sprite sheets
    tiles/         # tilesets
    audio/
      music/
      sfx/
      ambient/
    fonts/
    icons/
  data/            # JSON/CSV: items.json, affixes.json, monsters.json, ...
  shaders/         # .gdshader files
  export_presets.cfg
  LICENSES.md      # mandatory; one row per third-party asset
  RELEASE_NOTES_v0.1.md
  README.md
```

Asset folders mirror the source asset's pack name (`assets/sprites/kenney_isodungeon/`) so license attribution stays traceable.

---

## 3. Asset sources — open-source only

### 3.1 The hard rule

Every third-party asset must be one of:
- **CC0** (public domain) — preferred
- **CC-BY 4.0** (attribution) — fine, attribute in `LICENSES.md` + an in-game Attributions screen
- **OFL** (fonts) — fine, attribute
- **MIT / Apache-2.0** (code/libraries) — fine, ship the license text

**Do not use**: GPL-only assets (would force whole-game GPL), CC-NC (non-commercial blocks Steam), CC-ND (no-derivatives blocks edits), unlicensed scrapes, AI-generated images of unclear copyright status, any ripped/extracted assets from commercial games.

> v0.1.0-rc1 addendum: **CC-BY-SA 3.0** is also admitted, scoped to the LPC pack carve-out in §3.2. CC-BY-SA only requires *derivatives of those assets* to remain CC-BY-SA — it does not viral-license the rest of the game.

### 3.2 2D sprites & tiles (recommended path — 2D pixel art)

| Pack | License | URL | Use |
|---|---|---|---|
| **Kenney "Isometric Dungeon"** | CC0 | kenney.nl/assets/isometric-dungeon | floor/wall tiles, doors, props |
| **Kenney "Roguelike Caves & Dungeons"** | CC0 | kenney.nl/assets/roguelike-caves-and-dungeons | cavern variants, traps |
| **Kenney "Tiny Dungeon"** | CC0 | kenney.nl/assets/tiny-dungeon | UI iconography, fallback chars |
| **0x72 "Dungeon Tileset II"** | CC0 | 0x72.itch.io/dungeontileset-ii | grimy fallback tiles, mobs |
| **LPC characters (OpenGameArt)** | CC-BY-SA 3.0 | opengameart.org/content/lpc-collection | player + enemy walk cycles |
| **Pixel Frog "Pixel Adventure" (free)** | CC0 | pixelfrog-assets.itch.io | enemy sprites, FX |
| **Cethiel "Pixel Item Pack" (OGA)** | CC0 | opengameart.org search "cethiel" | weapons, potions, scrolls icons |
| **Oryx "Lo-Fi Fantasy" (free version)** | CC-BY | oryxdesignlab.com | item icon style reference |
| **Buch "Roguelike/RPG pack"** (OGA) | CC0 | opengameart.org search "buch" | misc fillers |

> v0.1.0-rc1 addendum: Kenney "Isometric Dungeon" was renamed to **Kenney "Isometric Miniature Dungeon"** at `kenney.nl/assets/isometric-miniature-dungeon`. CC0, 753 PNG files, includes a `Characters/Male` folder.

### 3.3 3D assets — only if you go fixed-iso-camera 3D-rendered

| Pack | License | URL | Use |
|---|---|---|---|
| **Quaternius "Ultimate RPG Pack"** | CC0 | quaternius.com | low-poly chars + props |
| **KayKit "Dungeon Pack"** | CC0 | kaylousberg.itch.io | dungeon environment kit |
| **KayKit "Adventurers Character Pack"** | CC0 | kaylousberg.itch.io | playable + enemy chars |
| **Mixamo** | Adobe free-for-commercial | mixamo.com | rig + animation library |
| **Poly Pizza** (filter CC0) | CC0/CC-BY | poly.pizza | misc props |
| **Sketchfab CC0 filter** | CC0 | sketchfab.com (filter "Downloadable" + CC0) | spot replacements |

If 3D: orthographic camera at `(30°, 45°)`, render at integer pixel scale (1, 2, or 4) so silhouettes stay crisp.

### 3.4 Audio

| Source | License | URL | Use |
|---|---|---|---|
| **Eric Matyas (Soundimage)** | CC-BY 4.0 | soundimage.org | dungeon/town/boss music |
| **Kevin MacLeod (Incompetech)** | CC-BY 4.0 | incompetech.com | menu / cinematic |
| **Sonniss "GDC Game Audio Bundle"** | royalty-free for game use | sonniss.com/gameaudiogdc | bulk SFX (~60 GB free per year) |
| **Freesound.org** (filter CC0/CC-BY) | varies, check each | freesound.org | one-shot SFX |
| **OpenGameArt "Music" CC0 filter** | CC0 | opengameart.org/art-search-advanced | misc |
| **OpenGameArt "Sound Effect" CC0 filter** | CC0 | opengameart.org/art-search-advanced | hits, footsteps |

### 3.5 Fonts (all OFL — Google Fonts)

| Font | Use |
|---|---|
| **MedievalSharp** | titles, scene labels |
| **IM Fell DW Pica** | flavor / lore text |
| **Press Start 2P** | retro UI numbers, damage popups |
| **Inter** | menus / settings (legibility) |

Bundle the woff2/TTF locally under `assets/fonts/`. **Never** load from a CDN at runtime.

### 3.6 `LICENSES.md` is mandatory

One row per third-party asset, even derived/edited copies. CI auto-fails if an asset folder has no row in `LICENSES.md`. CC-BY assets must also surface attribution in an in-game **Credits / Attributions** screen reachable from the main menu.

---

## 4. Genre mechanics — full spec

### 4.1 Camera + controls

- Fixed isometric camera. Tile size: **64×32 px** (2:1 dimetric)
- **Left-click**: move-to-tile, OR attack-target if hovering enemy
- **Right-click**: cast bound skill at cursor
- **Number row 1–4**: skill bar (4 active slots)
- **`I`** inventory · **`C`** character · **`M`** map · **`Esc`** pause/menu · **`Tab`** loot-highlight overlay
- **Shift+click**: force-attack (don't move into melee)
- **Hold shift**: stand still while attacking
- All keys remappable in settings

> v0.1.0-rc1 addendum: tile size pinned to **256×128** in `IsoUtils.gd` to match Kenney's "Isometric Miniature" rendered art (4× the spec's 64×32, same 2:1 aspect). Same iso math, just a constant change.

### 4.2 Classes — 3 launch + 1 unlockable

| Class | Primary stat | Resource | Theme | Six active skills |
|---|---|---|---|---|
| **Bonecaller** | Will | Bone Shards (drop on kill, pick up to refill) | Necromancer | Raise Skeleton, Bone Spear, Corpse Explode, Drain, Blood Pool, Wraith Form |
| **Furyborn** | Strength | Rage (builds via attacks, decays out of combat) | Berserker | Cleave, Leap, Whirlwind, War Cry, Bloodthirst, Earthquake |
| **Frostmark** | Agility | Mana (regens passively) | Ice ranger | Volley, Frost Trap, Glacial Spike, Hawk-Eye, Ice Lance, Shadowstep |
| **Sealwarden** *(unlocks after Act III credits)* | Faith | Vigil (charge-based, max 3) | Paladin | Smite, Aegis, Holy Aura, Verdict, Reconsecrate, Last Light |

**Talent grid**: 4×4 per class. 12 passive nodes per grid. 1 talent point per level + 1 from each main quest. Respec available at the Hub Imbuer for escalating gold cost.

### 4.3 Stats

- **HP / Resource** — scale with level + gear
- **Damage** = weapon-base × class-scalar × skill-modifier × (1 + crit_chance × crit_damage)
- **Armor** (flat phys reduction) + **Resists** (Phys / Fire / Cold / Lightning / Shadow), capped 75%
- **Crit Chance** (cap 75%), **Crit Damage** (uncapped, scales)
- **Move Speed** (base 100%, cap +75%)
- **Cooldown Reduction** (cap 50%)
- **Magic Find** (multiplier on rare-or-better drop chance)

### 4.4 Loot system — D2-flavored

**Rarity tiers** (white → red):
1. **Common** (white) — base item, no affixes
2. **Magic** (blue) — 1–2 affixes, prefix/suffix from pool
3. **Rare** (yellow) — 3–5 affixes, generated name from prefix+suffix nameset
4. **Unique** (gold) — fixed name, fixed flavor, 4–6 fixed affixes, **1 unique mechanic** ("on-hit chains lightning to 3 enemies")
5. **Mythic** (red) — endgame only — like Unique + 1 random affix

**Item slots** (10): head, chest, gloves, boots, belt, amulet, ring×2, weapon, off-hand.

**Targets**:
- ≥ 60 unique items at launch (~6 per slot)
- 8 named **set items** (multi-piece bonuses)
- 200 magic prefixes + 200 suffixes (combinatorial variety so rare drops feel fresh)

**Drop tables**: weighted by monster level. Monster pack → 1 magic guaranteed, 8% rare. Boss → 1 rare guaranteed, 30% unique. Act boss → 1 unique guaranteed.

**Crafting**: "Imbuement" at the Imbuer NPC. Sacrifice 3 magic items of same slot → 1 rare of that slot. Gold cost scales with item-level.

**Sockets + gems**: weapons/armor have 0–3 sockets. 5 gem types (ruby/sapphire/topaz/emerald/skull) × 5 quality tiers. Skull gem mechanics (life-leech) keep the D2 nostalgic.

### 4.5 Procedural dungeons

- BSP (Binary Space Partitioning) room-and-corridor as the simple baseline. Wave-Function-Collapse as a v1.1 upgrade if you have appetite.
- Rooms are authored sets ("3×3 cell room with pillars", "long corridor with traps") tagged by biome
- 4 biomes:
  - **Catacombs** — Act I dungeons + Echo variants
  - **Frostvein Caves** — Act II
  - **Ruined Keep** — Act III floors 1–3
  - **Blood Cathedral** — Act III final + Pinnacle endgame
- Each dungeon: 3–5 floors, 1 boss room (final floor), 1–2 hidden rooms (lever/pressure-plate gated), 1 shrine (random buff)
- Boss + quest rooms are **authored**, not procedural. The corridors between them are procedural.

### 4.6 Combat tuning

- Normal-mob TTK at level-appropriate gear: **1–2 seconds**
- Elite-pack TTK: 5–10 seconds
- Boss TTK: 30–90 seconds at fair gear
- Player death: 10% XP debt (deducted from XP bar), no item loss; corpse retrieval clears debt. Permadeath is a separate "Hardcore" character mode toggled at character creation.

### 4.7 Endgame — "The Echo"

- After Act III credits, "Sigil of <biome>" items begin dropping
- Apply a sigil at the Echo Portal in any hub → spawns a procedural dungeon at sigil's tier (1–20)
- Tier scales monster level + magic find + boss difficulty
- **Pinnacle boss** spawns at sigil tier 15+, drops Mythic exclusively
- Sigils stack as the only meaningful endgame currency

---

## 5. Content scope — 10+ hours

### 5.1 Acts

| Act | Setting | Hours | Quests | Boss |
|---|---|---|---|---|
| **I — The Failing Light** | Burning village → catacombs | ~2.5 | 3 main + 6 side | The Hollow Bishop |
| **II — Frostvein Pass** | Mountain town → ice caves | ~3.0 | 3 main + 6 side | Worm-Mother Vyl |
| **III — Cinderfall Spire** | Ruined keep → blood cathedral | ~3.5 | 3 main + 7 side | The Pact-Bearer |
| **Epilogue — The Echo** | Endless dungeon | open-ended | per-sigil | Pinnacle every 5 floors |

Main path total: **~10 hours**. Side quests + thorough exploration: **+5–10 hours**. Endgame: indefinite.

### 5.2 Quest taxonomy (per act)

- **3 main quests**: scripted, gate Act progression, unlock the boss
- **5–7 side quests**: kill X, fetch Y, escort Z, lore-tomb sequence, mini-boss
- **~10 lore codex entries** (book pickups, NPC dialogue) — codex is browsable from menu

### 5.3 Town hubs (1 per act)

- **Whitestone** (Act I), **Frostmoor** (Act II), **Lasthold** (Act III)
- 4 NPC services per hub:
  - **Smith** — repair, weapon upgrade (consumes lower-tier of same)
  - **Imbuer** — craft (3 magic → 1 rare), gem socketing, respec talents
  - **Stash** — 4 tabs of 10×10 grid, shared across characters
  - **Quest-board** — surfaces side quests scaled to current level
- Per-act NPC banter advances on milestones

### 5.4 Enemy roster

- **25 monster archetypes** × 3 biome variants = 75 visual entries
- **6 elite modifiers**: Frenzied, Frost-Aura, Multi-shot, Vampiric, Blink, Summoner — combine 2 per pack
- **5 designed boss fights** with 3 phases each (Acts I/II/III + Pinnacle + a hidden secret-boss for cheek)

### 5.5 Items target

- 60 unique items at launch
- 8 set bonuses
- 200 prefixes + 200 suffixes
- 5 gem types × 5 qualities
- 30 consumables (potions, scrolls of identify/town-portal, elixirs)

---

## 6. UI / UX

### 6.1 HUD (combat)

- HP orb (left), Resource orb (right), 4-skill hotbar centered between
- Minimap top-right (toggle full-map with `M`)
- Floating combat text: damage numbers (toggleable), crit highlights, "ABSORB" / "RESIST" markers
- Buff/debuff icons row above orbs
- Mini-quest tracker top-left (collapsible)

### 6.2 Menus

- **Inventory**: 10×4 grid, item-tetris style (D2-coded: 1×1 rings, 2×2 boots, 2×4 two-handers)
- **Character**: paper-doll equipped slots + stat readout + talent grid tab
- **Map**: fog-of-war fades on visit, waypoints persist
- **Codex**: searchable lore + bestiary + item index (% discovered)
- **Pause / Settings / Save / Quit**

### 6.3 Settings

- **Graphics**: resolution, vsync, fullscreen mode, particles low/med/high, post-FX on/off
- **Audio**: master / music / SFX / ambient sliders, mute-on-focus-loss
- **Gameplay**: auto-pickup gold, item-name-always-on, quest-marker on/off, screen-shake intensity
- **Accessibility**: color-blind preset (deuteranopia/protanopia/tritanopia), reduce-motion, font-size 80–150%, always-subtitles, hold-vs-toggle for skills
- **Controls**: full keybind remap including movement; mouse-button rebind

---

## 7. Audio direction

- **Music**: 1 looping ambient track per zone (3–4 min, seamless), 1 combat-up-tempo overlay (sidechain on combat-detect), 1 stinger per dialogue beat
- **SFX (~80 unique)**: footsteps × 4 surfaces (stone/wood/water/blood), weapon-swing × 4 weapon classes, hit-feedback × 3 armor classes (cloth/leather/plate), skill SFX × 6 per class
- **Ambient loops**: wind, dripping water, distant chants per biome
- **No voice acting** at launch (text + portraits only). Subtitles are always on by default.

---

## 8. Save / persistence

- **5 character slots**, each its own save file
- Save format: **JSON inside zlib-compressed wrapper**, versioned with a `schema_version: int`
- Auto-save on: zone-change, level-up, quest-complete, every 5 minutes
- Manual save: only at hubs (prevents save-scumming through fights — maintains the genre's tension)
- **Schema migration policy**: every save schema bump ships a one-way migrator; never break old saves silently
- **Hardcore mode**: permadeath, save deleted on death
- Cloud save: deferred to v1.1

---

## 9. CI / build / release

### 9.1 GitHub Actions matrix

```yaml
strategy:
  matrix:
    platform: [ubuntu-22.04, windows-latest, macos-latest]
```

Steps: checkout → cache Godot binary → install Godot 4.3 export templates → `godot --headless --import` → `godot --headless --export-release "<platform>" build/<platform>/HOLLOWFANE` → upload artifact → on `v*` tag, read `RELEASE_NOTES_v<X.Y>.md` → create draft GitHub Release with all 3 binaries.

### 9.2 License-compliance gate

A CI step diffs `assets/**` against `LICENSES.md` rows (script-driven, list of source folders). Fails the build if any asset folder isn't attributed.

### 9.3 Versioning

- SemVer
- Pre-1.0: minor bumps for milestones (`v0.1` → `v0.9` development, `v1.0` first release)
- Single source: `project.godot` `application/config/version` — every other file reads from there at build time

---

## 10. Milestones — suggested 12-week cadence

| Week | Deliverable |
|---|---|
| 1 | Tech-spike: Godot iso TileMapLayer + click-to-move + Kenney tileset, 1 walking sprite. **Tag `v0.1.0`.** |
| 2 | Combat skeleton: 1 enemy AI, 1 player skill, HP bar, death/respawn, damage numbers. **`v0.2.0`** |
| 3 | Loot pipeline: rarity tiers, affix table, drop, ground-pickup, equip, stat-recalc, tooltip compare. **`v0.3.0`** |
| 4 | Inventory UI + character UI + skill hotbar + bind-skill flow. **`v0.4.0`** |
| 5 | BSP procedural dungeon generator + Catacombs biome (Kenney tiles) + lighting. **`v0.5.0`** |
| 6 | Act I content: village hub, intro quest, 3 main quests, Hollow Bishop boss fight. **`v0.6.0`** |
| 7 | Frostvein biome + ice-cave variants + Worm-Mother. Class #2 (Furyborn) playable. **`v0.7.0`** |
| 8 | Class balance pass + 20 unique items + crafting (imbue) + sockets + gems. **`v0.8.0`** |
| 9 | Cinderfall Spire + final boss + ending cutscene. Class #3 (Frostmark) playable. **`v0.9.0`** |
| 10 | Endgame Echo system + sigils + Mythic loot + Pinnacle boss. Sealwarden unlocks. **`v0.10.0`** |
| 11 | Settings, save migration, accessibility checklist, color-blind palette validation. **`v0.11.0`** |
| 12 | QA, balance, RC builds, marketing assets, ship **`v1.0.0`** |

Each week's deliverable lands as a tagged release with notes — even if internal-only — so you have a fall-back if anything ratchets sideways.

---

## 11. Definition of Done — `v1.0.0`

The release is "done" when **all** check:

- [ ] Fresh `git clone` → install Godot 4.3 → `godot --headless --export-release` produces runnable binaries on Linux/Windows/macOS
- [ ] First-time player completes Act I in **≤ 3 hours** following only in-game prompts (no external wiki)
- [ ] All 3 launch classes playable solo through Act III without grinding (test with default-build for each)
- [ ] Bot-play harness runs 1 hour of randomized inputs without a crash
- [ ] Save → quit → reload preserves: position, inventory, equipped gear, quest state, talent points, HP%/resource%, gold, codex unlocks
- [ ] Every asset folder has a row in `LICENSES.md`; CI license-gate is green
- [ ] Settings menu allows full keybind remap including movement keys
- [ ] Reduce-motion toggle disables: screen shake, hit-particle bursts, damage-popup tween, post-FX bloom
- [ ] Color-blind preset (deuteranopia) tested against Sim Daltonism — loot rarity colors remain distinguishable
- [ ] CI green on `main` for all 3 OS targets for at least 7 consecutive days
- [ ] Tagged `v1.0.0` GitHub Release has 3 binaries attached + `LICENSES.md` + `RELEASE_NOTES_v1.0.md`
- [ ] README has playable screenshot, controls reference, and "How to build from source" section

---

## 12. Risks + mitigations

| Risk | Mitigation |
|---|---|
| Asset legal ambiguity | License-gate CI check; only CC0/CC-BY/OFL/MIT allowed; `LICENSES.md` mandatory |
| Combat feel flat | Week-2 spike has hit-stop (4-frame freeze on hit) + screen-shake + damage popups in the proof-of-concept; iterate weekly |
| Loot table runaway complexity | Affixes live in `data/affixes.json` (pure data), unit-test affix-roller deterministically |
| Save format breaks | Every schema bump ships a migrator; reject loads of unknown schema with a clear error |
| Procgen produces unwinnable layouts | Generator runs flood-fill validation: every key location reachable; reject + reroll otherwise |
| Scope creep | Hard-cap at the 12-week milestone table; new features go to v1.1 |
| Asset visual incoherence | Pick one tile pack as the visual anchor; recolor LPC chars via shader to match palette |

---

## 13. START — paste this block into the build agent

```
You are building HOLLOWFANE, a single-player isometric action-RPG in
Godot 4.3 LTS. Follow the spec in BUILD_PROMPT.md exactly. Use only
CC0, CC-BY, OFL, or MIT-licensed third-party assets, sourced from the
list in §3. Every asset must have a row in LICENSES.md with the
source URL, author, and license, before you commit it.

Target: 10+ hour main story across 3 acts (The Failing Light,
Frostvein Pass, Cinderfall Spire) + endless endgame "Echo" loop. 3
playable classes at launch (Bonecaller, Furyborn, Frostmark) +
Sealwarden unlock after Act III credits. D2-style loot tiers (Common
/ Magic / Rare / Unique / Mythic) with procedural affixes from
data/affixes.json. Procedural dungeons via BSP across 4 authored
biomes. 25 monster archetypes, 60 uniques, 8 sets at launch.

Stack: Godot 4.3 + GDScript primary (C# only if profiler demands).
Build via `godot --headless --export-release`. CI matrix on
ubuntu-22.04 / windows-latest / macos-latest. SemVer. First tag
v0.1.0 after the Week-1 deliverable; v1.0.0 when every box in §11
checks.

Begin Week 1: initialize repo, vendor Kenney "Isometric Dungeon"
under assets/tiles/kenney_isodungeon/, add its row to LICENSES.md,
build a TileMapLayer scene with click-to-move on a single walking
sprite (LPC archer, attribute in LICENSES.md). Tag v0.1.0 with a
30-second screen-recording committed to docs/v0.1.0-spike.gif.
Update RELEASE_NOTES_v0.1.md.

Hard rules:
- No GPL-only assets, no AI-generated images, no ripped commercial
  game art, no online-only DRM, no microtransactions, no telemetry.
- Never break the accessibility checklist (§6.3 + §11).
- Every release is tagged + has its own RELEASE_NOTES file.
- Confirm each Week's milestone with a screenshot + headless playtest
  log before advancing.
- If a milestone slips, do not skip — re-cut the schedule, slip v1.0
  rather than cutting the DoD checklist.

Begin.
```

---

## 14. Bonus polish (cuttable from v1.0, save for v1.1)

- rough.js-style hand-drawn UI accents
- Per-act color-grade LUT (warm Act I → cold Act II → blood-red Act III)
- Cinematic letterbox + zoom-in for boss intros
- Photo-mode (pause + free-cam, hide HUD, screenshot key)
- Steam Workshop for community sigil seeds (post-launch)
- Lighting: Light2D normals on tiles for moody dynamic shadows
- Weather overlays (rain, snow, ash) per zone

---

End of build prompt. Saved alongside the game repo per §14 as the single source of truth.
