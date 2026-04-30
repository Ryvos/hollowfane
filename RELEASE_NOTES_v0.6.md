# Release notes — v0.6.0

> Status: **shipped**. Week 6 of the 12-week milestone schedule.

## Scope (per BUILD_PROMPT.md §10)

> Act I content: village hub, intro quest, 3 main quests, Hollow Bishop boss fight.

## What ships

### Code — autoloads

- `scripts/systems/QuestLog.gd` — autoload. 3-quest chain (`speak_to_smith` → `investigate_catacombs` → `slay_hollow_bishop`). Each quest unlocks the next on completion. Survives scene transitions, so progress persists between hub and dungeon. Emits `quest_advanced(id, status)` for live UI updates.

### Code — actors

- `scripts/actors/NPC.gd` + `scenes/actors/NPC.tscn` — clickable hub character. Body is a colored rect with a name plate; click pops a small dialog and (optionally) advances a quest via `quest_complete_id`.
- `scripts/actors/ScenePortal.gd` + `scenes/actors/ScenePortal.tscn` — clickable tile that calls `change_scene_to_file(target_scene)`. Optionally advances a quest on use (e.g. stepping into the Catacombs portal completes `investigate_catacombs`).

### Code — levels

- `scripts/levels/WhitestoneHub.gd` + `scenes/levels/WhitestoneHub.tscn` — the village. 7×7 dirt-tile floor, four NPCs (Brask the Smith, Veska the Imbuer, the Stash, the Quest Board), one portal labeled `→ Catacombs`. Smith click also completes `speak_to_smith`. Player spawns at tile `(3, 3)`.
- `scripts/levels/Catacombs.gd` — now spawns:
  - a `← Whitestone` portal one tile north of the BSP entrance,
  - the **Hollow Bishop** in the BSP exit room (only if the boss-kill quest isn't already complete — autoload state means he stays dead across re-entries).
  - The exit room is now skipped when scattering trash mobs so the boss isn't crowded.

### Code — UI

- `scripts/ui/QuestLogPanel.gd` — toggleable panel listing every quest, status-coded (✓ green = complete, ▶ amber = active, • grey + "???" = hidden). Listens to `QuestLog.quest_advanced` so it updates the moment a quest fires.

### Code — modifications

- `scripts/actors/Enemy.gd` — converted hard-coded constants (HP, attack damage, item level, sprite variant) to per-instance `@export` vars. Added `is_boss`, `boss_name` (renders a name plate above the head), `quest_on_death` (calls `QuestLog.complete()` on death), `drops_count`, `drops_min_rarity` (boss = 3 drops, minimum Magic).
- `scripts/systems/LootRoller.gd` — `roll(monster_level, magic_find, min_rarity = -1)` clamps the rolled rarity to a floor when set; bosses use `Magic` (1) so loot quality reflects the kill.
- `scripts/systems/HUD.gd` — adds the Quest Log panel and `Q` toggle. `Esc` now also closes the quest panel. `bind_player()` first disconnects the previous Player's `hp_changed` so scene transitions don't leave a stale signal connection.

### Scenes

- `scenes/main/Main.tscn` — now boots into Whitestone instead of Catacombs. Player is declared first so `add_to_group("player")` runs before the level's deferred placement lookup.
- `scenes/main/Main_Catacombs.tscn` — new. Boots into Catacombs (the dungeon entry point that the hub portal targets).

### Config

- `project.godot`:
  - `application/config/version` bumped to `0.6.0`.
  - Added `QuestLog` autoload (between `Hotbar` and `HUD` so HUD can reference it on init).

## Behavior

- Game boots into Whitestone. Quest "Tools of the Trade" is active.
- Click Brask → his dialog opens, "Tools of the Trade" flips to ✓, "Beneath the Stones" auto-activates.
- Click the `→ Catacombs` portal → `change_scene_to_file` swaps to the dungeon, "Beneath the Stones" flips to ✓, "The Hollow Bishop" auto-activates.
- Catacombs renders as before (10 rooms, 354 tiles, fully connected with seed `12876480`); a `← Whitestone` portal sits at the entrance, the Hollow Bishop at the exit room.
- Hollow Bishop: 240 HP, 25 damage, name plate above his head. On death: drops 3 items at minimum-Magic rarity (most fights yield at least one usable affix), `slay_hollow_bishop` flips to ✓.
- Re-entering the Catacombs after killing him → the bishop does not respawn; the boss-kill autoload check guards against it.
- `Q` toggles the Quest Log panel anywhere; `Esc` closes any open panel.
- `I`, `C`, `Q`, `Esc`, `1`–`4` all work across scene transitions because the HUD + autoloads survive.

## Verification

- `python3 tools/check_licenses.py` → exit 0
- `godot --headless --import` → exit 0, no warnings, no `SCRIPT ERROR`
- `godot --headless --quit-after 6 res://scenes/main/Main.tscn` → no errors (hub boot)
- `godot --headless --quit-after 6 res://scenes/main/Main_Catacombs.tscn` → "Catacombs seed=12876480: 10 rooms, 354 tiles, fully connected." (dungeon boot)

## Deferred to later weeks

- Smith / Imbuer / Stash actual mechanics (gear sales, imbuement crafting, stash UI). Land Week 8 alongside crafting + sockets.
- Quest Board accept/decline UI — Week 9 with the Codex (currently quests are auto-active in chain order).
- Affix de-duplication (Rare items can roll the same prefix twice given the small 10-prefix v0.3.0 pool). Lands Week 8 when the affix table grows toward the spec's 200+200 target and a "no two affixes share the same stat key" filter becomes meaningful.
- Scene-transition save/resume of player HP. v0.6.0 heals on transition (acceptable spike behavior). Lands Week 11 with the proper save system.
- Real isometric `TileSet.tres` (from Week 5 deferral). Still a Week 6 nice-to-have but the hub + dungeon both work fine on Sprite2D-per-tile; rolled forward to Week 8.
- LPC sprites — still using Kenney male sprites. Class portraits land Weeks 7–9.
- Whitestone hub atmospherics: bonfire light, ambient music, NPC walk paths. Polish in Week 11.
