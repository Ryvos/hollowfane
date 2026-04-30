extends Node

## LootRoller — autoload. Centralizes drop-table + affix-roll logic so monsters
## and chests just call `LootRoller.roll(item_level, magic_find)` and get a
## fully-rolled Item resource back.
##
## Reads `data/items.json` and `data/affixes.json` once at boot. Spec §4.4
## targets Common 60 / Magic 25 / Rare 12 / Unique 2 / Mythic 1; magic-find
## tilts the curve toward higher tiers without ever lowering common-base
## probability below zero.

const ITEMS_PATH: String = "res://data/items.json"
const AFFIXES_PATH: String = "res://data/affixes.json"

var _weapons: Array[Dictionary] = []
var _prefixes: Array[Dictionary] = []
var _suffixes: Array[Dictionary] = []
var _data_ok: bool = false


func _ready() -> void:
	_load_data()


func _load_data() -> void:
	var items_text: String = FileAccess.get_file_as_string(ITEMS_PATH)
	if items_text == "":
		push_error("LootRoller: failed to read %s" % ITEMS_PATH)
		return
	var items_parsed: Variant = JSON.parse_string(items_text)
	if typeof(items_parsed) != TYPE_DICTIONARY:
		push_error("LootRoller: %s did not parse as a dict" % ITEMS_PATH)
		return
	for w: Dictionary in (items_parsed as Dictionary).get("weapons", []):
		_weapons.append(w)
	var aff_text: String = FileAccess.get_file_as_string(AFFIXES_PATH)
	if aff_text == "":
		push_error("LootRoller: failed to read %s" % AFFIXES_PATH)
		return
	var aff_parsed: Variant = JSON.parse_string(aff_text)
	if typeof(aff_parsed) != TYPE_DICTIONARY:
		push_error("LootRoller: %s did not parse as a dict" % AFFIXES_PATH)
		return
	for p: Dictionary in (aff_parsed as Dictionary).get("prefixes", []):
		_prefixes.append(p)
	for s: Dictionary in (aff_parsed as Dictionary).get("suffixes", []):
		_suffixes.append(s)
	_data_ok = _weapons.size() > 0 and _prefixes.size() > 0 and _suffixes.size() > 0


func roll(monster_level: int = 1, magic_find: float = 0.0, min_rarity: int = -1) -> Item:
	if not _data_ok:
		return null
	var rarity: int = _roll_rarity(magic_find)
	if min_rarity >= 0 and rarity < min_rarity:
		rarity = min_rarity
	var base: Dictionary = _pick_base(monster_level)
	var item: Item = Item.new()
	item.base_id = String(base.get("id", ""))
	item.base_name = String(base.get("name", ""))
	item.slot = String(base.get("slot", "weapon"))
	item.base_damage = int(base.get("base_damage", 0))
	item.item_level = int(base.get("ilevel", 1))
	item.rarity = rarity
	var n: int = _affix_count_for(rarity)
	if n >= 1:
		item.prefix = _roll_affix(_prefixes)
	if n >= 2:
		item.suffix = _roll_affix(_suffixes)
	if n >= 3:
		var extras: Array[Dictionary] = []
		for i: int in range(n - 2):
			var pool: Array[Dictionary] = _prefixes if (i % 2 == 0) else _suffixes
			extras.append(_roll_affix(pool))
		item.extra_affixes = extras
	return item


func _roll_rarity(mf: float) -> int:
	var weights: PackedFloat32Array = [60.0, 25.0, 12.0, 2.0, 1.0]
	weights[2] += mf * 5.0
	weights[3] += mf * 2.0
	weights[4] += mf * 0.5
	var total: float = 0.0
	for w: float in weights:
		total += w
	var r: float = randf() * total
	var acc: float = 0.0
	for i: int in range(weights.size()):
		acc += weights[i]
		if r <= acc:
			return i
	return Item.Rarity.COMMON


func _affix_count_for(rarity: int) -> int:
	match rarity:
		Item.Rarity.COMMON:
			return 0
		Item.Rarity.MAGIC:
			return randi_range(1, 2)
		Item.Rarity.RARE:
			return randi_range(3, 5)
		Item.Rarity.UNIQUE:
			return randi_range(4, 6)
		Item.Rarity.MYTHIC:
			return randi_range(5, 7)
	return 0


func _pick_base(monster_level: int) -> Dictionary:
	var pool: Array[Dictionary] = []
	for w: Dictionary in _weapons:
		if int(w.get("ilevel", 1)) <= maxi(monster_level, 1):
			pool.append(w)
	if pool.is_empty():
		return _weapons[0]
	return pool[randi() % pool.size()]


func _roll_affix(pool: Array[Dictionary]) -> Dictionary:
	var pick: Dictionary = pool[randi() % pool.size()]
	var v_min: int = int(pick.get("min", 0))
	var v_max: int = int(pick.get("max", 0))
	return {
		"id": pick.get("id", ""),
		"name": pick.get("name", ""),
		"stat": pick.get("stat", ""),
		"value": randi_range(v_min, v_max),
	}
