# Release notes — v0.8.0

> Status: **shipped**. Week 8 of the 12-week milestone schedule.

## Scope (per BUILD_PROMPT.md §10)

> Class balance pass + 20 unique items + crafting (imbue) + sockets + gems.

## What ships

### Code — data

- `data/uniques.json` — 5 unique items with fixed name, flavor, base_id ref, 3–4 fixed affixes, and a descriptive `unique_mechanic` string for the on-hit hook (which lands Week 9 alongside class skill kits). Spec target is ≥60 uniques at v1.0; the 5-item subset proves the pipeline end-to-end (drop → tooltip → equip → stat-recalc).
- `data/gems.json` — 3 gems (Chipped Ruby, Sapphire, Skull) at tier 1. Spec target is 5 types × 5 tiers = 25 at v1.0.

### Code — Item resource

- New fields: `sockets` (0–3), `socketed_gems` (Array of Dictionaries), `display_name_override` (used so uniques like "Crusher of Kings" survive the prefix-suffix builder), `flavor` (one-line italic blurb shown in the tooltip).
- `get_all_affixes()` now folds socketed gems into the affix stream, so any installed gem's stats automatically count toward `get_stat_total()` and `get_total_damage()`.

### Code — LootRoller

- Loads `uniques.json` + `gems.json` alongside items + affixes (defensively — both are optional; the core data_ok check still passes if they're absent).
- `roll(...)` injects a unique on a `UNIQUE` rarity roll; injects a gem on a 10% drop-chance override (regardless of rarity).
- Sockets are rolled per drop: `SOCKET_ROLL_CHANCE[rarity]` controls whether the item gets any sockets at all (Common 0%, Magic 40%, Rare 70%, Unique 90%); count is 1–3 weighted toward 1 except on Rare/Unique which can spike to 3.
- New `imbue(items: Array[Item]) -> Item`: validates 3 items share a slot, computes the highest item-level among them, rolls a fresh Magic-or-Rare (40% chance Rare) at that ilevel.

### Code — UI

- `scripts/ui/ImbuePanel.gd` — toggleable HUD panel. 10×4 grid mirroring the inventory; click 3 cells to select. Bottom hint label color-codes status (`Pick 3 of matching slot.` / `Mismatched slots — must all be weapon.` / `Ready. Imbue 3 weapon items.`). Imbue button enables only when the 3 selections all share a slot. On press: removes the 3 from inventory, appends the new item; if the bag is full, the result drops at the player's feet.
- `scripts/systems/Tooltip.gd` — now renders the flavor line in italic-rarity-color above the divider, plus a `Sockets: filled / total` line for items with sockets.

### Code — interaction

- `scripts/actors/NPC.gd` — new `panel_id` field. When set, clicking the NPC opens the named HUD panel (e.g. `imbue`) instead of the placeholder dialog. Also still fires `quest_complete_id` if set.
- `scripts/levels/WhitestoneHub.gd` — Imbuer NPC now wires `panel = "imbue"` so clicking Veska opens the imbue UI.
- `scripts/systems/HUD.gd` — `show_panel(name_id)` dispatcher routes `"imbue"`, `"inventory"`, `"character"`, `"quest"` to the corresponding panel. `Esc` also closes the imbue panel.
- `scripts/ui/InventoryPanel.gd` — clicking a gem in the inventory is a no-op (gems socket; they don't equip). The socket-install UI lands Week 9.

### Code — class balance pass

- Furyborn Strike: cooldown `5.0s → 4.0s`, damage bonus `+50 → +60`. The bishop fight (now 280 HP) takes ~3 strikes from a Furyborn with a Magic weapon, ~5 from Hollowbinder spam-clicking — a meaningful but not overwhelming class spread.
- Hollow Bishop (Catacombs): HP `240 → 280`, drops `3 → 4`. With unique drops now possible, players reach the bishop with stronger gear; the bump keeps the fight readable.
- Worm-Mother (Frostvein): HP `320 → 400`, drops `4 → 5`. Same logic — late-game boss should feel like one.

### Config

- `project.godot` — `application/config/version` bumped to `0.8.0`.

## Behavior

- Drops now occasionally roll uniques (gold-tinted name, italic flavor line, 4 fixed affixes), gems (a separate slot that doesn't equip), and socketed gear (`Sockets: 0/2` line in the tooltip).
- Click Veska the Imbuer in Whitestone → the Imbue panel opens. Pick 3 inventory items of the same slot → click Imbue → they fuse into one fresh Magic-or-Rare item. Mismatched slots stay disabled with a tinted hint.
- Furyborn Strike feels punchier on the 4s cooldown.
- Boss fights take more hits and pay better.

## Verification

- `python3 tools/check_licenses.py` → exit 0
- `godot --headless --import` → exit 0, no warnings, no `SCRIPT ERROR`
- All three main scenes boot:
  - `Main.tscn` → silent (hub)
  - `Main_Catacombs.tscn` → "Catacombs seed=12876480: 10 rooms, 354 tiles, fully connected."
  - `Main_Frostvein.tscn` → "Frostvein seed=259019758: 11 rooms, 406 tiles, fully connected."

## Deferred to later weeks

- **Socket-install UI**. Sockets and gems both drop and serialize correctly, but there's no in-game way yet to drop a gem into a socketed item. Lands Week 9 alongside the Smith's actual mechanics.
- **Remaining 15 uniques** to hit spec's target of 20. The pipeline is fully in — adding more is a content task.
- **Remaining 22 gems** to hit spec's 5×5 = 25 target. Likewise content.
- **Set items** (8 named multi-piece sets). Spec §4.4. Lands Week 9 with the Smith.
- **Unique on-hit / on-cast / on-kill mechanics**. Currently descriptive strings only; the hook engine arrives Week 9 alongside Frostmark.
- **Affix de-duplication on Rare items** (still rolls with replacement).
- **Crafting cost** (gold). The spec calls for "Gold cost scales with item-level"; gold doesn't exist yet — Week 9 with the Smith adds the currency.
- **Multi-cell items** (item-tetris layout). The Item resource already has `cell_w` / `cell_h`; the layout doesn't use them yet.
- **Class talent grids** (spec §6.2). Lands Week 9 with class kits.
