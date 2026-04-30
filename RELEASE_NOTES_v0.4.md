# Release notes — v0.4.0

> Status: **shipped**. Week 4 of the 12-week milestone schedule.

## Scope (per BUILD_PROMPT.md §10)

> Inventory UI + character UI + skill hotbar + bind-skill flow.

## What ships

### Code — autoloads

- `scripts/systems/Inventory.gd` — 10×4 backpack of Item refs (40 cells), `add()` / `remove_at()` / `get_at()`, `is_full()`, `free_count()`, `changed` signal.
- `scripts/systems/SkillBook.gd` — catalog of every known skill, indexed by id. v0.4.0 ships exactly one (`basic_attack`); class skill trees land Weeks 6–9 alongside their classes.
- `scripts/systems/Hotbar.gd` — 4 slots, `set_slot(slot, skill_id)`, `clear_slot()`, `activate(slot)` emits `skill_activated(slot, skill_id)`. Slot 0 auto-binds to `basic_attack` so the spike works out of the box.
- `scripts/systems/HUD.gd` — autoload `CanvasLayer` that owns the always-on bottom bar (HP orb + Hotbar + resource-orb placeholder) and the toggleable Inventory and Character panels. Toggles via `I` / `C` / `Esc`. Player calls `HUD.bind_player(self)` so the orb subscribes to `hp_changed` directly.

### Code — UI

- `scripts/ui/HPOrb.gd` — circular orb with chord-clipped horizontal-line liquid fill, drawn entirely in `_draw()`. No texture or shader required.
- `scripts/ui/HotbarUI.gd` — 4 slot buttons. Click a slot to open a `PopupMenu` listing every known skill plus Clear; selection rebinds the slot. Bound slots get a brighter rim + `[skill name]` text.
- `scripts/ui/InventoryPanel.gd` — `PanelContainer` + 10×4 grid of `Button`s. Hovering shows the Tooltip; clicking equips the cell's item (the previously-equipped item bounces back into the inventory).
- `scripts/ui/CharacterPanel.gd` — paper-doll with all 10 slots positioned in a D2-style silhouette (head / amulet / chest / weapon / off-hand / gloves / belt / 2× rings / boots) plus a stat readout (damage, max HP, equipped count, inventory free). Click a slot to unequip back into the inventory.

### Modifications

- `scripts/actors/Player.gd`:
  - Registers with HUD via `HUD.bind_player(self)`.
  - Connects `Hotbar.skill_activated` → `_on_skill_activated`; basic_attack auto-targets the nearest enemy in 400px scan radius and routes through the existing `_attack` path.
  - `_unhandled_input` now also consumes `1` / `2` / `3` / `4` and routes them through `Hotbar.activate(slot)`.
- `scripts/actors/GroundItem.gd` — pickup goes to `Inventory.add()` (was auto-equip in v0.3.0). If the bag is full, the item stays on the ground.
- `scripts/systems/Item.gd` — added `cell_w` / `cell_h` defaults of 1 so the Week 8 multi-cell layout doesn't need a save-format migration.
- `project.godot`:
  - `application/config/version` bumped to `0.4.0`.
  - Added `Inventory`, `SkillBook`, `Hotbar`, `HUD` autoloads (in dependency order — Hotbar uses SkillBook; HUD references all of them).

## Behavior

- HUD bottom bar always visible: HP orb (left, fills bottom-up like the D2 globe), 4-slot hotbar (centered), dimmed Resource orb placeholder (right).
- Press `I` to toggle the inventory panel; `C` to toggle the character panel; `Esc` closes any open panel.
- Kill an enemy → drop lands on the floor (unchanged from v0.3.0).
- Click the ground item → it goes into the inventory bag (bag full = stays on ground).
- Click an inventory cell → its item is equipped; whatever was in that slot gets pushed back into the bag at the first free cell.
- Click a paper-doll slot → unequips back into the bag (bag full = unequip is refused; toast UI lands later).
- Hovering ground items, inventory cells, AND paper-doll slots all surface the Tooltip with `— vs equipped —` diff against whatever is currently in that slot.
- Click a hotbar slot → popup picker; pick a skill or Clear.
- Press `1` / `2` / `3` / `4` → fires the bound skill at the nearest enemy in range. Slot 0 starts pre-bound to `basic_attack`.
- Stat readout in the character panel updates live whenever PlayerStats changes.

## Verification

- `python3 tools/check_licenses.py` → exit 0
- `godot --headless --import` → exit 0, no warnings, no `SCRIPT ERROR`
- `godot --headless --quit-after 6 res://scenes/main/Main.tscn` → no `ERROR:` lines

## Deferred to later weeks

- Multi-cell items (1×1 rings vs 2×4 two-handers from spec §6.2) — `cell_w` / `cell_h` fields are wired on `Item` but the layout only places 1×1 cells. Picks up Week 8 alongside crafting + sockets where layout matters most.
- Drag-and-drop. Click-driven equip / unequip is the same number of UX steps with a fraction of the code; drag-drop becomes a single Week 8 polish pass once placement validation is needed for multi-cell items.
- Toast / on-screen "Inventory full" notifier — currently silent. Lands with the broader feedback-text system Week 6 (alongside quest-objective updates).
- Skill icons (currently text labels). Real icons arrive as classes ship in Weeks 7–9; the SkillBook entry already has an `icon_color` field for transition.
- Resource orb wiring — placeholder for now. Wired Weeks 7–9 when class resource pools (Furyborn rage, Frostmark frost, etc.) come online.
- Talent grid tab on the character panel (spec §6.2). Talents unlock with class progression Weeks 7–9.
- Settings screen + keybind remap (spec §6.3) — Week 11.
