extends Resource
class_name Item

## Item — runtime + persistable representation of a single inventory item.
##
## Modeled as a `Resource` (not a Dictionary) so it survives Godot's save/load
## (`ResourceSaver` / `ResourceLoader`) — which the Week 11 save system will
## use without rewrites. Affixes are stored as plain Dictionaries because they
## are pure data rolled at runtime; promoting them to their own Resource will
## happen if/when affixes need behaviors beyond stat-totals.

enum Rarity { COMMON, MAGIC, RARE, UNIQUE, MYTHIC }

const RARITY_NAMES: Dictionary = {
	Rarity.COMMON: "Common",
	Rarity.MAGIC: "Magic",
	Rarity.RARE: "Rare",
	Rarity.UNIQUE: "Unique",
	Rarity.MYTHIC: "Mythic",
}

const RARITY_COLORS: Dictionary = {
	Rarity.COMMON: Color(0.85, 0.85, 0.85),
	Rarity.MAGIC: Color(0.45, 0.65, 1.0),
	Rarity.RARE: Color(1.0, 0.95, 0.25),
	Rarity.UNIQUE: Color(0.95, 0.6, 0.15),
	Rarity.MYTHIC: Color(0.95, 0.2, 0.2),
}

@export var base_id: String = ""
@export var base_name: String = ""
@export var slot: String = "weapon"
@export var rarity: int = Rarity.COMMON
@export var base_damage: int = 0
@export var item_level: int = 1
@export var prefix: Dictionary = {}
@export var suffix: Dictionary = {}
@export var extra_affixes: Array[Dictionary] = []
# Inventory cell footprint. Spec §6.2: 1×1 rings, 2×2 boots, 2×4 two-handers.
# v0.4.0 only ships 1×1; multi-cell layout lands later alongside crafting.
@export var cell_w: int = 1
@export var cell_h: int = 1
# v0.8.0: sockets + uniques. Sockets count and which gems are in them; the
# socket-install UI lands Week 9. `display_name_override` is set for unique
# items so their flavor name ("Crusher of Kings") survives prefix/suffix logic.
# `flavor` is a one-line italic blurb shown in the tooltip for uniques.
@export var sockets: int = 0
@export var socketed_gems: Array[Dictionary] = []
@export var display_name_override: String = ""
@export var flavor: String = ""


func get_display_name() -> String:
	if display_name_override != "":
		return display_name_override
	var pre: String = String(prefix.get("name", ""))
	var suf: String = String(suffix.get("name", ""))
	var parts: PackedStringArray = []
	if pre != "":
		parts.append(pre)
	parts.append(base_name)
	if suf != "":
		parts.append(suf)
	return " ".join(parts)


func get_all_affixes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not prefix.is_empty():
		out.append(prefix)
	if not suffix.is_empty():
		out.append(suffix)
	for a: Dictionary in extra_affixes:
		out.append(a)
	for g: Dictionary in socketed_gems:
		out.append({
			"id": String(g.get("id", "")),
			"name": "Gem: %s" % String(g.get("name", "")),
			"stat": g.get("stat", ""),
			"value": int(g.get("value", 0)),
		})
	return out


func get_stat_total(stat_name: String) -> int:
	var total: int = 0
	if stat_name == "damage_flat":
		total += base_damage
	for a: Dictionary in get_all_affixes():
		if String(a.get("stat", "")) == stat_name:
			total += int(a.get("value", 0))
	return total


func get_total_damage() -> int:
	return get_stat_total("damage_flat")


func get_color() -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)


func get_rarity_name() -> String:
	return RARITY_NAMES.get(rarity, "Common")


func to_dict() -> Dictionary:
	# Save-format snapshot. Used by SaveSystem; round-trips through
	# `Item.from_dict()`. Plain Dictionaries (no Resources) so JSON.stringify
	# handles it without custom encoders.
	return {
		"base_id": base_id,
		"base_name": base_name,
		"slot": slot,
		"rarity": rarity,
		"base_damage": base_damage,
		"item_level": item_level,
		"prefix": prefix,
		"suffix": suffix,
		"extra_affixes": extra_affixes,
		"cell_w": cell_w,
		"cell_h": cell_h,
		"sockets": sockets,
		"socketed_gems": socketed_gems,
		"display_name_override": display_name_override,
		"flavor": flavor,
	}


static func from_dict(d: Dictionary) -> Item:
	if d.is_empty():
		return null
	var it: Item = Item.new()
	it.base_id = String(d.get("base_id", ""))
	it.base_name = String(d.get("base_name", ""))
	it.slot = String(d.get("slot", "weapon"))
	it.rarity = int(d.get("rarity", Rarity.COMMON))
	it.base_damage = int(d.get("base_damage", 0))
	it.item_level = int(d.get("item_level", 1))
	it.prefix = d.get("prefix", {})
	it.suffix = d.get("suffix", {})
	var ea: Array[Dictionary] = []
	for a: Dictionary in d.get("extra_affixes", []):
		ea.append(a)
	it.extra_affixes = ea
	it.cell_w = int(d.get("cell_w", 1))
	it.cell_h = int(d.get("cell_h", 1))
	it.sockets = int(d.get("sockets", 0))
	var gems: Array[Dictionary] = []
	for g: Dictionary in d.get("socketed_gems", []):
		gems.append(g)
	it.socketed_gems = gems
	it.display_name_override = String(d.get("display_name_override", ""))
	it.flavor = String(d.get("flavor", ""))
	return it
