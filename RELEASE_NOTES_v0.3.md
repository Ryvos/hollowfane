# Release notes — v0.3.0

> Status: **shipped**. Week 3 of the 12-week milestone schedule.

## Scope (per BUILD_PROMPT.md §10)

> Loot pipeline: rarity tiers, affix table, drop, ground-pickup, equip, stat-recalc, tooltip compare.

## What ships

### Code

- `scripts/systems/Item.gd` — `Resource` subclass with `Rarity` enum (Common / Magic / Rare / Unique / Mythic), prefix + suffix + extra-affixes layout, `get_total_damage()`, `get_stat_total(stat)`, `get_display_name()`, `get_color()`. Modeled as a Resource so the Week 11 save-system can serialize equipped gear without rewrites.
- `scripts/systems/LootRoller.gd` — autoload. Reads `data/items.json` + `data/affixes.json` once at boot. `roll(monster_level, magic_find) -> Item` picks rarity by weighted table (60/25/12/2/1, magic-find tilts toward higher tiers), picks a base whose ilevel ≤ monster_level, then rolls 0–7 affixes per rarity (Common 0, Magic 1–2, Rare 3–5, Unique 4–6, Mythic 5–7).
- `scripts/systems/PlayerStats.gd` — autoload. `equip(item)` returns the previously-equipped item (so the world can drop it back), `get_attack_damage()` and `get_max_hp()` aggregate base + affixes. Survives Player respawn / scene reload.
- `scripts/systems/Tooltip.gd` — autoload `CanvasLayer`. One reusable PanelContainer + RichTextLabel that follows the cursor and renders the hovered item with rarity-tinted name, item level, total damage, all affixes, and a `— vs equipped —` diff block (green for upgrades, red for downgrades).
- `scripts/actors/GroundItem.gd` — `Area2D` with a colored gem + name label. Hover fires the tooltip; click equips and consumes the input event so the player doesn't also walk to that tile. The previously equipped item drops back at the same spot (with jitter) so progress stays reversible until the inventory grid lands Week 4.
- `scripts/actors/Enemy.gd` — `_die()` now calls `_drop_loot()` before `queue_free()`, instantiating one rolled `GroundItem` at the corpse position via `LootRoller.roll(ITEM_LEVEL=3)`.
- `scripts/actors/Player.gd` — replaced hard-coded `ATTACK_DAMAGE: 25` constant with `PlayerStats.get_attack_damage()`. Tracks dynamic `_hp_max` from `PlayerStats.get_max_hp()`, listens for `stats_changed` to grow the bar when +max_hp gear is equipped (the new headroom fills, so the upgrade is felt).

### Scenes

- `scenes/actors/GroundItem.tscn` — `Area2D` + `CollisionShape2D` (28×28 square hitbox) + `ColorRect` gem + `Label` name plate. Mouse filters set so the gem and label don't eat clicks meant for the Area2D.

### Data

- `data/items.json` — three weapon bases (Crude Club ilvl1 / Iron Sword ilvl3 / Steel Blade ilvl5).
- `data/affixes.json` — 10 prefixes + 10 suffixes covering `damage_flat` and `max_hp` across 5 tiers.

### Config

- `project.godot`:
  - `application/config/version` bumped to `0.3.0`.
  - Added `PlayerStats`, `LootRoller`, `Tooltip` autoloads (in that order — Tooltip reads from PlayerStats).

## Behavior

- Kill an enemy → ground item drops at the corpse with a colored gem + name label tinted by rarity.
- Hover the item → tooltip floats next to the cursor showing total damage, all affixes, and a side-by-side compare against whatever is currently equipped.
- Click the item → it is equipped; the previously equipped item (if any) drops back at the same spot with a small jitter.
- Player damage scales with the equipped weapon's base damage + every `damage_flat` affix; max HP scales with every `max_hp` affix.
- Newly granted max-HP headroom fills automatically on equip — equipping a `+30 max_hp` belt mid-fight gives you 30 HP back, not just a bigger bar.

## Verification

- `python3 tools/check_licenses.py` → exit 0
- `godot --headless --import` → exit 0, no `SCRIPT ERROR`
- `godot --headless --quit-after 5 res://scenes/main/Main.tscn` → no `ERROR:` lines

## Deferred to later weeks

- Inventory grid + paper-doll for non-weapon slots (Week 4).
- Hotbar + bind-skill flow (Week 4).
- Affixes that need full combat math: crit chance, crit damage, resists, move speed, attack speed (Week 6+ as skills + classes come online).
- Unique items (need the unique-mechanic engine — Week 8 alongside crafting).
- Set items + Imbuement crafting + sockets/gems (Week 8).
- Drop tables that distinguish trash / pack / boss / act-boss tiers (Week 6 boss content).
- Hover-while-aiming-skill suppression (the inventory grid drives that polish in Week 4).
