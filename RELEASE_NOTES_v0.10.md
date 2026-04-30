# Release notes — v0.10.0

> Status: **shipped**. Week 10 of the 12-week milestone schedule.

## Scope (per BUILD_PROMPT.md §10)

> Endgame Echo system + sigils + Mythic loot + Pinnacle boss. Sealwarden unlocks.

## What ships

### Code — autoload

- `scripts/systems/EchoState.gd` — autoload. Tracks `current_tier` (default 0; first Echo run sets it to 1) and `max_tier_reached`. Provides scaling helpers: `tier_hp_multiplier()` (+30% per tier), `tier_dmg_multiplier()` (+20% per tier), `tier_magic_find()` (+0.15 per tier). `is_pinnacle_tier()` returns true on every multiple of `PINNACLE_INTERVAL` (3 by default). `bump_tier(n)` is what sigils consume to deepen the next run. Survives scene transitions.

### Code — endless dungeon

- `scripts/levels/EchoDungeon.gd` — fourth biome script. Picks one of three themes per visit (Catacombs cold-blue / Frostvein pale teal / Cinderfall ember-orange) deterministically by `(tier - 1) % 3` so a given run always reads as one biome. Reuses `BSPDungeon`, `FloodFill`, the same sprite-per-tile renderer. Trash mob and boss stats are scaled by the EchoState multipliers; on a Pinnacle tier the exit-room boss is replaced with a tier-scaled Pinnacle:
  - Pinnacle base: 600 HP × tier multiplier, 40 dmg × tier multiplier, 8 drops, **guaranteed Unique floor** (with Mythic chance bonus from tier magic-find), name plate `"Pinnacle (Tier N)"`, and `quest_on_death = "slay_pinnacle"`.
  - Non-Pinnacle bosses: 280/28/4/Rare-floor with the theme's name baked in (`Catacombs Echo (Tier N)`).
- `scenes/levels/EchoDungeon.tscn` + `scenes/main/Main_Echo.tscn` — entry wiring.
- `WhitestoneHub` — new portal `→ The Echo` north of the spawn (vs. the three campaign-biome portals south).

### Code — loot

- `scripts/systems/LootRoller.gd`:
  - Mythic injection: when the rarity table rolls `MYTHIC`, take a unique entry and append one extra random affix tagged `"Mythic ..."` (per spec §4.4: "Mythic = like Unique + 1 random affix").
  - Sigil drop: 4% chance per drop to spawn an `Echo Sigil` instead of normal loot. Sigils have `slot = "sigil"`, rarity Rare, item-level matching the monster.
  - Sealwarden's class-base scaling stays out of LootRoller — it only affects the unlock check via QuestLog.
- `scripts/actors/Enemy.gd._drop_loot()` now passes `EchoState.tier_magic_find()` to `LootRoller.roll()` so high-tier Echo runs visibly drop more uniques + mythics.

### Code — class

- `PlayerStats.CLASSES.sealwarden` — fourth class, `base_damage = 33`, `base_max_hp = 75`, glass cannon. Starting skill `sealwarden_brand` (+85 damage, 8s cooldown). Unlocked when `slay_pinnacle` completes:
  - new `is_class_unlocked(id)` and `get_unlocked_class_ids()` methods,
  - `CharacterPanel`'s Switch Class button now cycles only through unlocked classes.

### Code — quest

- `QuestLog` adds `slay_pinnacle`, chained off `confront_pact_bearer`. Activates when the campaign ends; completes on first Pinnacle kill.

### Code — interaction

- `InventoryPanel` — clicking a sigil consumes it and bumps `EchoState.current_tier` by 1. The next Echo run is one tier deeper. Gem clicks remain no-ops (socket UI still pending).

### Config

- `project.godot`:
  - `application/config/version` bumped to `0.10.0`.
  - Added `EchoState` autoload (between QuestLog and HUD so HUD/UI can reference it).

## Behavior

- Whitestone now has four travel portals: Catacombs / Frostvein / Cinderfall (south) and The Echo (north).
- First Echo run: tier = 1, Catacombs-theme map, pinnacle = no, mob and boss stats are unscaled. Boss gives min-Rare drops + the tier magic-find bonus.
- Find an Echo Sigil (4% drop) → click it in the inventory → next Echo run is tier 2.
- At tier 3: Cinderfall theme, pinnacle = yes, the Pinnacle boss replaces the regular boss. Killing the Pinnacle:
  - drops 8 items at min-Unique with mythic chance bonuses,
  - completes `slay_pinnacle`,
  - unlocks Sealwarden in the class switcher.
- Switch to Sealwarden in the Character panel: Damage 33 / Max HP 75, Hotbar slot 0 becomes Sealwarden Brand (+85 dmg, 8s cd). True glass cannon; one unlucky encounter and you're back at spawn.
- Mythic items (red rarity tint) now actually appear in tooltips with a "Mythic ..." labeled affix on top of the unique's fixed roll.

## Verification

- `python3 tools/check_licenses.py` → exit 0
- `godot --headless --import` → exit 0, no warnings, no `SCRIPT ERROR`
- Smoke tests:
  - `Main.tscn` → silent (hub)
  - `Main_Echo.tscn` → "EchoDungeon T1 (Catacombs): 12 rooms, 514 tiles, fully connected, pinnacle=no"
  - All four campaign main scenes still boot cleanly.

## Deferred to later weeks

- **Save/resume** of Echo `current_tier` + `max_tier_reached` across game launches. Lives in the autoload now but evaporates on quit. Lands Week 11 with the proper save system.
- **Sigil modifiers** (spec §4.7 — "sigils that change how the dungeon spawns"). The current sigil only bumps tier; modifiers like "Echo: no resists" / "Echo: doubled mob count" land post-launch as a content pass.
- **Pinnacle boss kit** (special abilities, multi-phase fight). Currently it's the regular Enemy AI with bigger numbers and a guaranteed unique floor.
- **Sealwarden talent / kit** beyond the one starter skill — same gap as the other three classes.
- **BiomeBase refactor** — still concrete, still pending. The four biome scripts now share enough that the extraction is no longer speculative; will land Week 11 alongside the save system, where the diff is unavoidable.
- **Mythic icon/UI distinction** beyond the rarity tint — currently they look like uniques with one extra affix in the tooltip, which is exactly the spec definition; future polish could add a "M" mark or particle.
