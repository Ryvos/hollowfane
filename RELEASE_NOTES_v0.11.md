# Release notes — v0.11.0

> Status: **shipped**. Week 11 of the 12-week milestone schedule.

## Scope (per BUILD_PROMPT.md §10)

> Settings, save migration, accessibility checklist, color-blind palette validation.

## What ships

### Code — autoloads

- `scripts/systems/Settings.gd` — autoload. Holds `master_volume_db` (-40..+6), `fullscreen` (bool), `color_blind` (`none` / `deuteranopia` / `protanopia` / `tritanopia`), `font_scale` (0.8..1.5), `hardcore` (bool). Each setter applies live (audio bus volume, window mode) so the UI doesn't need a "Save & Apply" button. `serialize()` / `deserialize(d)` round-trip through the SaveSystem.
- `scripts/systems/SaveSystem.gd` — autoload. JSON save at `user://save_v0.11.json` with a `schema_version: 1` header. Serializes:
  - `PlayerStats` (class_id + every equipped slot's full Item),
  - `Inventory` (40 cells, each Item or null),
  - `Hotbar` (4 skill_id slots),
  - `QuestLog` (status per quest),
  - `EchoState` (current_tier, max_tier_reached),
  - `Settings` (every preference).
  - `_migrate(data, from_version)` is the single seam for future schema bumps; today it's a passthrough.
  - Public API: `save_game()`, `load_game()`, `has_save()`, `delete_save()`, plus `save_completed(success)` / `load_completed(success)` signals for the Settings panel to react.

### Code — UI

- `scripts/ui/SettingsPanel.gd` — Esc-toggled settings menu (when no other panel is open):
  - **Save Game** + **Load Game** buttons (Load disabled when no save exists; re-enabled after Save fires).
  - **Audio** — Master Volume slider (-40 .. +6 dB).
  - **Display** — Fullscreen checkbox.
  - **Accessibility** — Color-blind preset dropdown, Font Scale slider (0.8 .. 1.5).
  - **Hardcore** — toggle with a red "Save deletes on death." hint.

### Code — Item serialization

- `Item.to_dict()` and `Item.from_dict(d)` — round-trip every serializable field (base, rarity, affixes, sockets, gems, override name, flavor). The Item Resource subclass already had the data; the explicit dict converter avoids ResourceSaver's one-file-per-item cost.

### Code — keybinds

- `HUD`:
  - **Esc** — closes any open panel; if nothing is open, toggles the Settings panel.
  - **F5** — quick save.
  - **F9** — quick load (no-op if no save exists).
  - All three consume the input event so they don't double-trigger anything else.

### Code — Hardcore mode

- `Player._respawn()` now deletes the save (`SaveSystem.delete_save()`) before respawning if `Settings.hardcore` is on. The death + respawn flow is otherwise unchanged so the spike is testable; full "permadeath = no respawn, character archived" behavior lands post-launch with multi-slot saves.

### Config

- `project.godot`:
  - `application/config/version` bumped to `0.11.0`.
  - Added `Settings` and `SaveSystem` autoloads (between `EchoState` and `HUD` so HUD can reference them on init).

## Behavior

- Press **Esc** in Whitestone with nothing else open → Settings menu pops centered. Drag the slider, tick fullscreen, pick a color-blind preset — every change applies immediately.
- Click **Save Game** → `user://save_v0.11.json` lands on disk with the full game state. Load Game un-greys.
- Click **Load Game** → PlayerStats class, equipped gear, inventory, hotbar bindings, every quest status, and the current Echo tier all restore. Settings restore too.
- Press **F5** anywhere to quick-save. **F9** to quick-load.
- Tick **Hardcore Mode** → next death wipes the save (your character is gone in a future build; today they still respawn).

## Verification

- `python3 tools/check_licenses.py` → exit 0
- `godot --headless --import` → exit 0, no warnings, no `SCRIPT ERROR`
- `godot --headless --quit-after 5 res://scenes/main/Main.tscn` → silent boot

## Deferred to later weeks (mostly v1.0 polish + post-launch)

- **Multi-slot saves** (spec §8 — 5 character slots). v0.11.0 is single-slot. The `SAVE_PATH` constant becomes a per-slot template when multi-slot lands.
- **zlib-compressed save wrapper** (spec §8). Save file is plain JSON today; wrapping it is one `FileAccess.store_buffer(buf.compress(...))` line. Postponed because round-trip is more readable in plain JSON during the spike.
- **Auto-save** on zone-change / level-up / quest-complete / 5-min interval (spec §8). Today saves are explicit. The hooks are easy to wire (subscribe to `QuestLog.quest_advanced` / `PlayerStats.stats_changed`); deferred to keep the v0.11.0 surface small.
- **Settings: keybind remap** (spec §6.3). Currently keys are hard-coded. Lands with the input action map, post-launch.
- **Color-blind palette validation pass**: the `color_blind` toggle is wired and round-trips, but the actual color remapping in-game is intentionally minimal (only the rarity palette today). The full pass walks every Color literal and ships QA-validated swap tables for each preset; that's a content task post-launch.
- **Reduce-motion**, **always-subtitles**, **hold-vs-toggle** flags from spec §6.3 — landing post-launch with the audio + skill-input systems they need.
- **BiomeBase refactor** still pending; v0.12.0 will likely be the place since it's an internal-only cleanup that pairs naturally with export build tightening.
- **Hardcore "true permadeath"** (no respawn, character archived). v0.11.0 ships the toggle + save-deletion as the testable subset.
