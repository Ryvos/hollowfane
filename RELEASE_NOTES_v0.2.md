# Release notes — v0.2.0

> Status: **shipped**. Week 2 of the 12-week milestone schedule.

## Scope (per BUILD_PROMPT.md §10)

> Combat skeleton: 1 enemy AI, 1 player skill, HP bar, death/respawn, damage numbers.

## What ships

### Code

- `scripts/actors/Enemy.gd` — `CharacterBody2D` with a 4-state machine (`IDLE` → `CHASE` → `ATTACK` → `DEAD`). Lazily finds the player via group lookup; chases when out of `ATTACK_RANGE_PX`, attacks on cooldown when in range, dies + `queue_free`s on HP ≤ 0.
- `scripts/actors/Player.gd` — extended for combat: left-click rule is now "if cursor is within `ATTACK_REACH_PX` of any enemy, attack the closest; else move-to-tile". Player tracks HP, takes damage, respawns at spawn position on HP ≤ 0.
- `scripts/systems/DamageNumbers.gd` — autoloaded singleton; `spawn(amount, world_pos, color)` creates a floating `Label` that tweens up + fades over 0.8s.
- `scripts/ui/HPBar.gd` — small `Control` that draws a green→yellow→red bar via `_draw()`. Used as a child of player + each enemy, positioned above the sprite by the parent scene.

### Scenes

- `scenes/actors/Enemy.tscn` — `CharacterBody2D` + `AnimatedSprite2D` + `CollisionShape2D` + `HPBar` instance.
- `scenes/ui/HPBar.tscn` — minimal `Control` with the script attached; reused by both player and enemy scenes.
- `scenes/actors/Player.tscn` — adds `HPBar` instance above the existing player setup.
- `scenes/levels/SpikeLevel.gd` — spawns one enemy at tile `(4, 4)` so the player at `(0, 0)` can walk over and engage.

### Config

- `project.godot`:
  - `application/config/version` bumped to `0.2.0`.
  - Added `DamageNumbers` autoload.

## Behavior

- Click on dirt tile → walk there (unchanged from v0.1.0).
- Click on enemy → player stops moving and deals 25 damage; yellow `25` label floats up from enemy.
- Enemy chases player when out of attack range; stops to attack on a 1-second cooldown when adjacent. Each enemy hit deals 10 damage and shows a red `10` label on the player.
- Enemy HP = 60, dies in 3 player hits.
- Player HP = 100, dies in 10 enemy hits, then respawns at `(0, 0)` with full HP.

## Verification

- `python3 tools/check_licenses.py` → exit 0
- `godot --headless --import` → exit 0, no `SCRIPT ERROR`
- `godot --headless --quit-after 5 res://scenes/main/Main.tscn` → no `ERROR:` lines

## Deferred to later weeks

- 10% XP-debt on death (placeholder; XP system arrives v0.3.0+).
- Hit-stop / hit-flash polish on enemy damaged.
- Multiple enemy archetypes (only Male variant 1 is reused as the placeholder skeleton).
- Proper attack swing animation (current implementation is just damage + numbers).
- HUD-anchored player HP orb (currently a small bar above the player sprite — full HUD orb in Week 4).
