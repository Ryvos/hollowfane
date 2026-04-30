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
const UNIQUES_PATH: String = "res://data/uniques.json"
const GEMS_PATH: String = "res://data/gems.json"

const SOCKET_ROLL_CHANCE: PackedFloat32Array = [0.0, 0.4, 0.7, 0.9, 1.0]  # COMMON..MYTHIC
const GEM_DROP_CHANCE: float = 0.10  # 10% of all drops are a gem instead of a weapon
const SIGIL_DROP_CHANCE: float = 0.04  # 4% of drops are a sigil (Echo tier-up)

var _weapons: Array[Dictionary] = []
var _prefixes: Array[Dictionary] = []
var _suffixes: Array[Dictionary] = []
var _uniques: Array[Dictionary] = []
var _gems: Array[Dictionary] = []
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
	# Uniques + gems are optional in case future builds strip the content; the
	# core data_ok check still passes if they're absent (you just never see
	# uniques drop, and gems become unavailable).
	var uniq_text: String = FileAccess.get_file_as_string(UNIQUES_PATH)
	if uniq_text != "":
		var uniq_parsed: Variant = JSON.parse_string(uniq_text)
		if typeof(uniq_parsed) == TYPE_DICTIONARY:
			for u: Dictionary in (uniq_parsed as Dictionary).get("uniques", []):
				_uniques.append(u)
	var gems_text: String = FileAccess.get_file_as_string(GEMS_PATH)
	if gems_text != "":
		var gems_parsed: Variant = JSON.parse_string(gems_text)
		if typeof(gems_parsed) == TYPE_DICTIONARY:
			for g: Dictionary in (gems_parsed as Dictionary).get("gems", []):
				_gems.append(g)
	_data_ok = _weapons.size() > 0 and _prefixes.size() > 0 and _suffixes.size() > 0


func roll(monster_level: int = 1, magic_find: float = 0.0, min_rarity: int = -1) -> Item:
	if not _data_ok:
		return null
	# Sometimes a drop is a sigil (Echo tier-up consumable) or a gem.
	if randf() < SIGIL_DROP_CHANCE:
		return _make_sigil_item(monster_level)
	if not _gems.is_empty() and randf() < GEM_DROP_CHANCE:
		return _make_gem_item(_gems[randi() % _gems.size()], monster_level)
	var rarity: int = _roll_rarity(magic_find)
	if min_rarity >= 0 and rarity < min_rarity:
		rarity = min_rarity
	# Unique rolls inject a fixed-flavor item from the uniques table.
	# Mythic rolls take a unique and append one extra random affix
	# (per spec §4.4 "Mythic = like Unique + 1 random affix").
	if not _uniques.is_empty():
		if rarity == Item.Rarity.MYTHIC:
			return _make_mythic_item(_uniques[randi() % _uniques.size()])
		if rarity == Item.Rarity.UNIQUE:
			return _make_unique_item(_uniques[randi() % _uniques.size()])
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
	item.sockets = _roll_socket_count(rarity)
	return item


func _roll_socket_count(rarity: int) -> int:
	var idx: int = clampi(rarity, 0, SOCKET_ROLL_CHANCE.size() - 1)
	if randf() >= SOCKET_ROLL_CHANCE[idx]:
		return 0
	# 1 socket common, 2 sockets sometimes, 3 only on rares+
	var r: float = randf()
	if rarity >= Item.Rarity.RARE and r < 0.2:
		return 3
	if r < 0.4:
		return 2
	return 1


func _make_unique_item(u: Dictionary) -> Item:
	var base_id: String = String(u.get("base_id", ""))
	var base: Dictionary = _find_base_by_id(base_id)
	var item: Item = Item.new()
	item.base_id = base_id
	item.base_name = String(base.get("name", base_id))
	item.slot = String(base.get("slot", "weapon"))
	item.base_damage = int(base.get("base_damage", 0))
	item.item_level = maxi(1, int(base.get("ilevel", 1)) + 2)
	item.rarity = Item.Rarity.UNIQUE
	item.display_name_override = String(u.get("name", item.base_name))
	item.flavor = String(u.get("flavor", ""))
	var fixed_affixes: Array[Dictionary] = []
	for a: Dictionary in u.get("affixes", []):
		fixed_affixes.append(a)
	item.extra_affixes = fixed_affixes
	item.sockets = _roll_socket_count(Item.Rarity.UNIQUE)
	return item


func _make_mythic_item(u: Dictionary) -> Item:
	var item: Item = _make_unique_item(u)
	item.rarity = Item.Rarity.MYTHIC
	# Splice one extra random affix on top of the unique's fixed roll.
	var pool: Array[Dictionary] = _prefixes if (randi() % 2 == 0) else _suffixes
	if not pool.is_empty():
		var bonus: Dictionary = _roll_affix(pool)
		bonus["name"] = "Mythic " + String(bonus.get("name", ""))
		item.extra_affixes.append(bonus)
	return item


func _make_sigil_item(monster_level: int) -> Item:
	var item: Item = Item.new()
	item.base_id = "sigil_echo"
	item.base_name = "Echo Sigil"
	item.slot = "sigil"
	item.rarity = Item.Rarity.RARE
	item.item_level = maxi(1, monster_level)
	item.display_name_override = "Echo Sigil"
	item.flavor = "Click in inventory to deepen your next Echo run."
	return item


func _make_gem_item(g: Dictionary, monster_level: int) -> Item:
	var item: Item = Item.new()
	item.base_id = String(g.get("id", ""))
	item.base_name = String(g.get("name", ""))
	item.slot = "gem"
	item.base_damage = 0
	item.item_level = maxi(1, monster_level)
	item.rarity = Item.Rarity.MAGIC
	item.display_name_override = item.base_name
	item.flavor = "Insert into a socketed item to bind its power."
	item.extra_affixes = [{
		"id": item.base_id,
		"name": item.base_name,
		"stat": String(g.get("stat", "")),
		"value": int(g.get("value", 0)),
	}]
	return item


func _find_base_by_id(id: String) -> Dictionary:
	for w: Dictionary in _weapons:
		if String(w.get("id", "")) == id:
			return w
	if not _weapons.is_empty():
		return _weapons[0]
	return {}


func imbue(items: Array[Item]) -> Item:
	# Spec §4.4: "Sacrifice 3 magic items of same slot → 1 rare of that slot."
	# We accept any 3 items as long as they share a slot, and produce one
	# Magic-or-better roll at the highest item-level among the sacrifices.
	if items.size() < 3:
		return null
	var slot_key: String = items[0].slot
	var max_ilevel: int = 0
	for it: Item in items:
		if it == null or it.slot != slot_key:
			return null
		max_ilevel = maxi(max_ilevel, it.item_level)
	# At least Magic; small chance of Rare for the dopamine.
	var min_rar: int = Item.Rarity.RARE if randf() < 0.4 else Item.Rarity.MAGIC
	return roll(max_ilevel, 0.0, min_rar)


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
