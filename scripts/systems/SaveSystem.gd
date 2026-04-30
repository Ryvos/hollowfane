extends Node

## SaveSystem — autoload. Single-slot JSON save (spec §8 — multi-slot lands
## post-launch). Serializes every persistable autoload: PlayerStats class +
## equipped, Inventory cells, Hotbar bindings, QuestLog statuses, EchoState
## tier counters. Stores at `user://save_v0.11.json`.
##
## **Schema migration policy** (spec §8): every bump of `SCHEMA_VERSION` ships
## a one-way migrator. v1 is the v0.11.0 launch schema; v2 will arrive when a
## new field needs to be added that v1 saves don't have a default for.

const SCHEMA_VERSION: int = 1
const SAVE_PATH: String = "user://save_v0.11.json"

signal save_completed(success: bool)
signal load_completed(success: bool)


func save_game() -> bool:
	var data: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"player_stats": _serialize_player_stats(),
		"inventory": _serialize_inventory(),
		"hotbar": _serialize_hotbar(),
		"quest_log": _serialize_quest_log(),
		"echo": _serialize_echo(),
		"settings": Settings.serialize(),
	}
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: could not open %s for writing" % SAVE_PATH)
		save_completed.emit(false)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	save_completed.emit(true)
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		load_completed.emit(false)
		return false
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		load_completed.emit(false)
		return false
	var raw: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		load_completed.emit(false)
		return false
	var data: Dictionary = parsed
	var v: int = int(data.get("schema_version", 0))
	data = _migrate(data, v)
	_apply_player_stats(data.get("player_stats", {}))
	_apply_inventory(data.get("inventory", []))
	_apply_hotbar(data.get("hotbar", []))
	_apply_quest_log(data.get("quest_log", {}))
	_apply_echo(data.get("echo", {}))
	if data.has("settings"):
		Settings.deserialize(data["settings"])
	load_completed.emit(true)
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	# When SCHEMA_VERSION bumps to 2, add an `if from_version < 2:` block here
	# that fills new fields with v1 defaults. Never break v1 saves silently.
	return data


func _serialize_player_stats() -> Dictionary:
	var equipped: Dictionary = {}
	for slot_key: String in PlayerStats.get_class_ids():
		pass  # placate GDScript: we want to walk equipped, not classes
	# Walk the equipped table directly via the public API.
	for slot_id: String in ["head", "chest", "gloves", "boots", "belt", "amulet", "ring_1", "ring_2", "weapon", "off_hand"]:
		var it: Item = PlayerStats.get_equipped(slot_id)
		if it != null:
			equipped[slot_id] = it.to_dict()
	return {"class_id": PlayerStats.class_id, "equipped": equipped}


func _serialize_inventory() -> Array:
	var cells: Array = []
	for i: int in range(Inventory.TOTAL_CELLS):
		var it: Item = Inventory.get_at(i)
		cells.append(it.to_dict() if it != null else null)
	return cells


func _serialize_hotbar() -> Array:
	var slots: Array = []
	for i: int in range(Hotbar.SLOTS):
		slots.append(Hotbar.get_slot(i))
	return slots


func _serialize_quest_log() -> Dictionary:
	var out: Dictionary = {}
	for q: Dictionary in QuestLog.all_quests():
		var qid: String = String(q["id"])
		out[qid] = QuestLog.get_status(qid)
	return out


func _serialize_echo() -> Dictionary:
	return {
		"current_tier": EchoState.current_tier,
		"max_tier_reached": EchoState.max_tier_reached,
	}


func _apply_player_stats(d: Dictionary) -> void:
	if d.is_empty():
		return
	var cid: String = String(d.get("class_id", "hollowbinder"))
	if PlayerStats.CLASSES.has(cid):
		PlayerStats.class_id = cid
	# Re-equip every saved slot. We bypass `equip()` so we don't generate UI
	# noise during a load.
	var equipped: Dictionary = d.get("equipped", {})
	for slot_id: String in equipped.keys():
		var it: Item = Item.from_dict(equipped[slot_id])
		if it != null:
			PlayerStats.equip(it)


func _apply_inventory(cells: Array) -> void:
	# Clear current inventory and refill from save.
	for i: int in range(Inventory.TOTAL_CELLS):
		Inventory.remove_at(i)
	for i: int in range(cells.size()):
		if i >= Inventory.TOTAL_CELLS:
			break
		var entry: Variant = cells[i]
		if typeof(entry) == TYPE_DICTIONARY and not (entry as Dictionary).is_empty():
			var it: Item = Item.from_dict(entry)
			if it != null:
				Inventory.add(it)


func _apply_hotbar(slots: Array) -> void:
	for i: int in range(slots.size()):
		if i >= Hotbar.SLOTS:
			break
		Hotbar.set_slot(i, String(slots[i]))


func _apply_quest_log(d: Dictionary) -> void:
	for qid: String in d.keys():
		var status: int = int(d[qid])
		if status == QuestLog.Status.COMPLETE:
			QuestLog.complete(qid)


func _apply_echo(d: Dictionary) -> void:
	EchoState.current_tier = int(d.get("current_tier", 0))
	EchoState.max_tier_reached = int(d.get("max_tier_reached", 0))
