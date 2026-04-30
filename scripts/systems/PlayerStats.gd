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

var _equipped: Dictionary = {}  # slot -> Item

signal stats_changed
signal item_equipped(item: Item, prev: Item)


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
		return BASE_DAMAGE
	return weapon.get_total_damage()


func get_max_hp() -> int:
	var bonus: int = 0
	for slot_key: String in _equipped.keys():
		var it: Item = _equipped[slot_key]
		bonus += it.get_stat_total("max_hp")
	return BASE_MAX_HP + bonus
