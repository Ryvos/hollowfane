# Release notes — v0.9.0

> Status: **shipped**. Week 9 of the 12-week milestone schedule.

## Scope (per BUILD_PROMPT.md §10)

> Cinderfall Spire + final boss + ending cutscene. Class #3 (Frostmark) playable.

## What ships

### Code — biome

- `scripts/levels/CinderfallSpire.gd` + `scenes/levels/CinderfallSpire.tscn` — third biome. 30×30 BSP dungeon with ember-orange tile modulate (`Color(1.20, 0.85, 0.65)`), warm ambient (`Color(0.45, 0.18, 0.10)`), and ember-orange room lights. Trash mobs are tougher than Frostvein (130 HP, 18 dmg, ilvl 7). Last room hosts the Pact-Bearer.
- `scenes/main/Main_Cinderfall.tscn` — dungeon entry scene wiring `CinderfallSpire` + `Player`.

### Code — final boss

- The Pact-Bearer in the BSP exit room: 520 HP, 36 damage, 6 drops at min-Rare floor, sprite_variant 5, name plate, `quest_on_death = "confront_pact_bearer"`. Like the other bosses, guarded by `QuestLog.is_complete(...)` so he stays dead across re-entries.

### Code — ending cutscene

- `scripts/ui/EndingCutscene.gd` — full-screen `ColorRect` overlay that subscribes to `QuestLog.quest_advanced` and auto-shows when `confront_pact_bearer` flips to `COMPLETE`. 1-second beat after kill so the boss death animation + drop have a moment to land before the screen takes over. RichTextLabel with center-aligned BBCode prose; press any key or click anywhere to dismiss.
- HUD now constructs and parents the ending cutscene as a top-layer overlay child of the HUD root.

### Code — Frostmark class

- `PlayerStats.CLASSES.frostmark`: `base_damage = 28`, `base_max_hp = 88`, `starting_skill = "frostmark_pulse"`. Glassier than Hollowbinder; bigger stick, smaller life pool.
- `SkillBook.frostmark_pulse`: `+45 damage`, `6.0s cooldown`, cool-blue icon. Fires through the same data-driven dispatcher Player added in Week 7 — no special-casing needed.
- Switch Class button in the Character panel now cycles through three classes: Hollowbinder → Furyborn → Frostmark → back. Stats, max HP, and the auto-bound slot 0 skill all update on switch.

### Code — quest

- `QuestLog` adds `confront_pact_bearer`, chained off `slay_worm_mother`. Automatically activates when the Worm-Mother dies; its completion (Pact-Bearer death) triggers the ending cutscene.

### Code — hub

- `WhitestoneHub` adds the third portal `→ Cinderfall Spire` next to the Catacombs and Frostvein portals. All three are always live in v0.9.0; portal-gating UX lands Week 11.

### Config

- `project.godot` — `application/config/version` bumped to `0.9.0`.

## Behavior

- The campaign now has a real end-state. Walk hub → Catacombs (kill Bishop) → hub → Frostvein (kill Worm-Mother) → hub → Cinderfall Spire (kill Pact-Bearer) → ending cutscene.
- Switching to Frostmark in the Character panel: Damage 25 → 28, Max HP 100 → 88, Hotbar slot 0 becomes Frostmark Pulse.
- All four quests now visible in the Quest Log; the chain self-advances as you complete each.
- Re-entering Cinderfall after killing the Pact-Bearer doesn't respawn him; the ending cutscene also doesn't re-show (it only fires on the COMPLETE *transition*, not on every check).

## Verification

- `python3 tools/check_licenses.py` → exit 0
- `godot --headless --import` → exit 0, no warnings, no `SCRIPT ERROR`
- All four main scenes boot:
  - `Main.tscn` → silent (hub)
  - `Main_Catacombs.tscn` → "Catacombs seed=12876480: 10 rooms, 354 tiles, fully connected."
  - `Main_Frostvein.tscn` → "Frostvein seed=259019758: 11 rooms, 406 tiles, fully connected."
  - `Main_Cinderfall.tscn` → "CinderfallSpire seed=203079281: 16 rooms, 481 tiles, fully connected."

## Deferred to later weeks

- **Lasthold hub** (spec §5.3 — Act III's town). Spec §10 Week 9 doesn't strictly require it; using Whitestone as the persistent home base is acceptable for the spike. Lands Week 10/11 with endgame content if at all.
- **Per-class endings** (different prose for Hollowbinder / Furyborn / Frostmark). v0.9.0 ships one ending; per-class variants land v1.1.
- **Unique mechanics** (the on-hit / on-cast / on-kill hooks described as flavor strings on uniques). Still descriptive only — the hook engine + 60 unique items lands as a content + system pass post-launch.
- **BiomeBase refactor**. Catacombs, Frostvein, and CinderfallSpire are now demonstrably 90% identical. Will extract Week 10/11 alongside the Echo system which adds a 4th biome consumer.
- **Set items** — still on the deferred list.
- **Talent grid** — still pending; class kits ship with one starter skill each.
- **Frostmark resource pool** (Glacier-sense or similar) — placeholder Resource orb still dim.
- **Per-class portraits + run/idle animations** — still Kenney Male for everyone. Asset polish pass post-launch.
