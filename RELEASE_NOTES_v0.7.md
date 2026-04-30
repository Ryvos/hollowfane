# Release notes — v0.7.0

> Status: **shipped**. Week 7 of the 12-week milestone schedule.

## Scope (per BUILD_PROMPT.md §10)

> Frostvein biome + ice-cave variants + Worm-Mother. Class #2 (Furyborn) playable.

## What ships

### Code — biomes

- `scripts/levels/Frostvein.gd` + `scenes/levels/Frostvein.tscn` — second biome. Reuses `BSPDungeon` and the sprite-per-tile renderer from Catacombs but tints every floor and wall sprite with a cold `Color(0.80, 0.95, 1.15)` modulate; the `CanvasModulate` ambient is paler teal `Color(0.30, 0.40, 0.55)` per spec §4.5. Spawns Worm-Mother (320 HP, 30 dmg, 4 drops min-Magic, sprite_variant 3) in the BSP exit room — guarded by `QuestLog.is_complete("slay_worm_mother")` so she doesn't respawn after kill. Trash mobs in Frostvein are tougher (90 HP, 14 dmg, ilvl 5) than Catacombs.
- `scenes/main/Main_Frostvein.tscn` — dungeon entry scene wiring `Frostvein` + `Player`.

### Code — class system

- `scripts/systems/PlayerStats.gd`:
  - new `CLASSES` table (Hollowbinder + Furyborn for v0.7.0; Frostmark + Sealwarden land Weeks 9–10).
  - `class_id` field tracks the active class. `set_class(id)` rebinds `Hotbar` slot 0 to that class's `starting_skill` and emits `class_changed` + `stats_changed`.
  - `get_class_base_damage()` / `get_class_base_max_hp()` / `get_class_name()` / `get_class_ids()` derive from the table.
  - `get_attack_damage()` and `get_max_hp()` now use the class base instead of the global `BASE_*` constants when no weapon is equipped, so Furyborn's burlier 22-dmg/120-HP profile shows up immediately on switch.
- `scripts/systems/SkillBook.gd` — added `furyborn_strike` (+50 damage bonus, 5s cooldown, hot orange-red icon color). Skill metadata is now data-driven (`damage_bonus`, `cooldown` fields); adding a class skill is one entry.
- `scripts/actors/Player.gd`:
  - per-slot cooldown tracker (`_skill_cooldowns: PackedFloat32Array`, ticks every physics frame).
  - `_on_skill_activated()` reads `damage_bonus` + `cooldown` from `SkillBook` rather than special-casing `basic_attack`. Any future class skill is data-only.
  - HP initializer fills to `_hp_max` post-recompute so a fresh boot as Furyborn starts at the full 120, not 100.

### Code — UI

- `scripts/ui/CharacterPanel.gd` — class line at the top of the stats readout (`[b]Hollowbinder[/b]` rendered amber). New "Switch Class" button cycles through `PlayerStats.get_class_ids()`. Subscribes to `class_changed` to refresh on class flip.

### Code — quest

- `QuestLog` adds the `slay_worm_mother` quest, chained off `slay_hollow_bishop` so it auto-activates after the Catacombs boss falls.

### Code — hub

- `scripts/levels/WhitestoneHub.gd` — second portal labeled `→ Frostvein` next to the Catacombs portal. Both portals are always live in v0.7.0 (gating Frostvein on the bishop is narrative, not mechanical, for the spike).

### Config

- `project.godot` — `application/config/version` bumped to `0.7.0`.

## Behavior

- Boot → Whitestone hub now shows two travel portals: `→ Catacombs` (left) and `→ Frostvein` (right).
- Open Character panel → top line reads `Hollowbinder`. Click `Switch Class` → flips to `Furyborn`, stats refresh (Damage 25 → 22, Max HP 100 → 120), Hotbar slot 0 becomes `Furyborn Strike`. Click again → back to Hollowbinder.
- Press `1` (or `2/3/4` if rebound) → fires the bound skill. Furyborn Strike now also goes on a 5s cooldown after each cast.
- Click the Frostvein portal → cold-tinted dungeon with Worm-Mother in the back room. Killing her completes the quest, drops 4 min-Magic items, and the boss stays dead across re-entries.
- `Q` opens the Quest Log; the four-quest chain (Tools of the Trade → Beneath the Stones → The Hollow Bishop → The Worm-Mother) flips green as you complete each.

## Verification

- `python3 tools/check_licenses.py` → exit 0
- `godot --headless --import` → exit 0, no warnings, no `SCRIPT ERROR`
- All three main scenes boot cleanly:
  - `Main.tscn` (hub) → silent boot
  - `Main_Catacombs.tscn` → "Catacombs seed=12876480: 10 rooms, 354 tiles, fully connected."
  - `Main_Frostvein.tscn` → "Frostvein seed=259019758: 11 rooms, 406 tiles, fully connected."

## Deferred to later weeks

- **Cellular-automata cave variant** (spec §4.5: "BSP/cellular automata hybrid"). The BSP layout suffices to differentiate the two biomes for the spike; the second algorithm becomes useful Week 8/9 when caves vs. structured dungeons read distinctly.
- **`BiomeBase` refactor** unifying Catacombs.gd and Frostvein.gd. They are 90% identical — copy, not extension. Will extract Week 8 once Lasthold + Cinderfall Spire are also in flight and the diff is concrete (right now the two have only diverged on tints + boss config).
- **Frostmoor hub** (spec §5.3 lists Frostmoor as Act II's town). Spec §10 Week 7 deliverables don't actually mention it — narratively the player still uses Whitestone as their home base in v0.7.0. Frostmoor lands when Act II content fleshes out.
- **Furyborn animations + portrait** — currently uses Kenney Male sprites for both classes. Class portraits + per-class run/idle animations land Weeks 7–9 polish.
- **Resource pool** for Furyborn (Rage). Spec §4.2 — Resource orb is still the dimmed placeholder. Rage / Fury / Frost wiring lands when each class's full skill kit ships Weeks 8–10.
- **Furyborn talent tree**. Spec §6.2 mentions a Talent Grid tab; v0.7.0 gives Furyborn one starter skill. Talent unlocks per-class land Weeks 8–10.
- **Class gating on Frostvein portal** (e.g. require Hollow Bishop kill). Currently both portals are always open. Will land alongside the proper quest-board UI Week 9.
- **LightOccluder2D on walls** — still passing through walls in both biomes.
