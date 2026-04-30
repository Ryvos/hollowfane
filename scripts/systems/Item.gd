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
