extends Node

## PlayerStats — autoload. Holds equipped items + computes derived stats.
##
## Why an autoload (and not a node on the Player scene)?
##   - Survives Player respawn / scene reload without losing equipped gear.
##   - The HUD, tooltip, and any future damage-over-time effects can read stats
##     without holding a Player reference.
##   - Spec §11 save-system (Week 11) only needs to serialize this one node.
##
## For v0.3.0 the only stats wired into combat are `damage_flat` (drives the
## player's basic attack) and `max_hp` (player HP cap). Other affix stats land
## in tooltips so the data is visibly flowing end-to-end; their gameplay hooks
## arrive in later weeks alongside crits, resists, and skills.

const BASE_DAMAGE: int = 25
const BASE_MAX_HP: int = 100

# Per-class base stats. Spec §4.2 lists 3 launch + 1 unlockable classes;
# v0.7.0 ships Hollowbinder (default) + Furyborn (Week 7's playable Class #2).
# Frostmark and the unlockable Sealwarden land Weeks 9–10 with their own
# entries here.
const CLASSES: Dictionary = {
	"hollowbinder": {
		"name": "Hollowbinder",
		"base_damage": 25,
		"base_max_hp": 100,
		"starting_skill": "basic_attack",
	},
	"furyborn": {
		"name": "Furyborn",
		"base_damage": 22,
		"base_max_hp": 120,
		"starting_skill": "furyborn_strike",
	},
	"frostmark": {
		"name": "Frostmark",
		"base_damage": 28,
		"base_max_hp": 88,
		"starting_skill": "frostmark_pulse",
	},
	"sealwarden": {
		"name": "Sealwarden",
		"base_damage": 33,
		"base_max_hp": 75,
		"starting_skill": "sealwarden_brand",
	},
}


func is_class_unlocked(id: String) -> bool:
	# Sealwarden is the v0.10.0 unlock — gated on first Pinnacle kill.
	if id == "sealwarden":
		return QuestLog.is_complete("slay_pinnacle")
	return CLASSES.has(id)


func get_unlocked_class_ids() -> Array[String]:
	var out: Array[String] = []
	for k: String in CLASSES.keys():
		if is_class_unlocked(k):
			out.append(k)
	return out

var _equipped: Dictionary = {}  # slot -> Item
var class_id: String = "hollowbinder"

signal stats_changed
signal item_equipped(item: Item, prev: Item)
signal class_changed(class_id: String)


func equip(item: Item) -> Item:
	if item == null:
		return null
	var slot_key: String = item.slot
	var prev: Item = _equipped.get(slot_key, null)
	_equipped[slot_key] = item
	stats_changed.emit()
	item_equipped.emit(item, prev)
	return prev


func unequip(slot_key: String) -> Item:
	var prev: Item = _equipped.get(slot_key, null)
	if prev != null:
		_equipped.erase(slot_key)
		stats_changed.emit()
	return prev


func get_equipped(slot_key: String) -> Item:
	return _equipped.get(slot_key, null)


func get_attack_damage() -> int:
	var weapon: Item = _equipped.get("weapon", null)
	if weapon == null:
		return get_class_base_damage()
	return weapon.get_total_damage()


func get_max_hp() -> int:
	var bonus: int = 0
	for slot_key: String in _equipped.keys():
		var it: Item = _equipped[slot_key]
		bonus += it.get_stat_total("max_hp")
	return get_class_base_max_hp() + bonus


func get_class_base_damage() -> int:
	return int(CLASSES.get(class_id, {}).get("base_damage", BASE_DAMAGE))


func get_class_base_max_hp() -> int:
	return int(CLASSES.get(class_id, {}).get("base_max_hp", BASE_MAX_HP))


func get_class_name() -> String:
	return String(CLASSES.get(class_id, {}).get("name", "Hollowbinder"))


func set_class(id: String) -> void:
	if not CLASSES.has(id) or class_id == id:
		return
	class_id = id
	var starting_skill: String = String(CLASSES[id].get("starting_skill", ""))
	if starting_skill != "":
		Hotbar.set_slot(0, starting_skill)
	class_changed.emit(id)
	stats_changed.emit()


func get_class_ids() -> Array[String]:
	var out: Array[String] = []
	for k: String in CLASSES.keys():
		out.append(k)
	return out
