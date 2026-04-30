extends Node2D

## EchoDungeon — endless, tier-scaled dungeon (spec §4.7 "The Echo").
##
## Picks one of the three campaign biome themes per visit (Catacombs cold-blue
## / Frostvein pale teal / Cinderfall ember-orange), scales enemy HP and damage
## by `EchoState.tier_hp_multiplier()` / `tier_dmg_multiplier()`, and bumps
## the magic-find applied to every drop by `tier_magic_find()` so high-tier
## runs visibly drop more uniques + mythics.
##
## At tiers that are multiples of `EchoState.PINNACLE_INTERVAL` (every 3 by
## default), the boss in the exit room is the **Pinnacle** — a tier-scaled
## meta-boss that drops a guaranteed Unique (with a Mythic chance bonus from
## the magic-find scaling). Killing a Pinnacle completes the
## `slay_pinnacle` quest, which unlocks Sealwarden.
##
## v0.10.0 deliberately ships this as one more biome script rather than
## extracting a `BiomeBase` parent. The refactor lands Week 11 alongside the
## save system, where touching every biome at once is unavoidable anyway.

const DUNGEON_W_TILES: int = 32
const DUNGEON_H_TILES: int = 32
const FLOOR_TEX_PATH: String = "res://assets/tiles/kenney_iso_miniature_dungeon/Isometric/dirt_E.png"
const WALL_TEX_PATH: String = "res://assets/tiles/kenney_iso_miniature_dungeon/Isometric/stoneWallAged_E.png"
const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/Enemy.tscn")
const PORTAL_SCENE: PackedScene = preload("res://scenes/actors/ScenePortal.tscn")
const HUB_SCENE_PATH: String = "res://scenes/main/Main.tscn"
const FLOOR_SPRITE_OFFSET: Vector2 = Vector2(0, -128)
const WALL_SPRITE_OFFSET: Vector2 = Vector2(0, -256)
const ROOM_LIGHT_RANGE_PX: float = 480.0
const ROOM_LIGHT_ENERGY: float = 1.5
const ENEMIES_PER_ROOM: int = 1
const MAX_ENEMIES: int = 10

const THEMES: Array[Dictionary] = [
	{
		"name": "Catacombs",
		"ambient": Color(0.18, 0.22, 0.32),
		"light":   Color(0.95, 0.85, 0.55),
		"tile_modulate": Color(1.0, 1.0, 1.0),
	},
	{
		"name": "Frostvein",
		"ambient": Color(0.30, 0.40, 0.55),
		"light":   Color(0.80, 0.95, 1.10),
		"tile_modulate": Color(0.80, 0.95, 1.15),
	},
	{
		"name": "Cinderfall",
		"ambient": Color(0.45, 0.18, 0.10),
		"light":   Color(1.0, 0.55, 0.25),
		"tile_modulate": Color(1.20, 0.85, 0.65),
	},
]

const PINNACLE_BASE_HP: int = 600
const PINNACLE_BASE_DMG: int = 40
const PINNACLE_BASE_DROPS: int = 8
const PINNACLE_SPRITE_VARIANT: int = 7
const REGULAR_BOSS_BASE_HP: int = 280
const REGULAR_BOSS_BASE_DMG: int = 28
const REGULAR_BOSS_BASE_DROPS: int = 4
const REGULAR_BOSS_SPRITE_VARIANT: int = 5
const TRASH_BASE_HP: int = 90
const TRASH_BASE_DMG: int = 14
const TRASH_BASE_ITEM_LEVEL: int = 6


var _dungeon: Dictionary = {}
var _light_texture: Texture2D = null
var _theme: Dictionary = THEMES[0]


func _ready() -> void:
	y_sort_enabled = true
	EchoState.start_first_run()
	_pick_theme()
	_light_texture = _make_light_texture()
	_generate(int(Time.get_unix_time_from_system()) ^ EchoState.current_tier)
	_render_floor()
	_render_walls()
	_add_canvas_modulate()
	_add_room_lights()
	_spawn_return_portal()
	_spawn_boss()
	call_deferred(&"_place_player")
	call_deferred(&"_spawn_enemies")
	_log_validation()


func _pick_theme() -> void:
	# Deterministic per tier so a given run is always one biome.
	var idx: int = (EchoState.current_tier - 1) % THEMES.size()
	_theme = THEMES[idx]


func _generate(seed_val: int) -> void:
	_dungeon = BSPDungeon.generate(seed_val, DUNGEON_W_TILES, DUNGEON_H_TILES)


func _render_floor() -> void:
	var tex: Texture2D = load(FLOOR_TEX_PATH)
	if tex == null:
		push_error("EchoDungeon: missing floor tex %s" % FLOOR_TEX_PATH)
		return
	var floor_tiles: Dictionary = _dungeon.get("floor_tiles", {})
	var modulate: Color = _theme["tile_modulate"]
	for tile: Vector2i in floor_tiles.keys():
		var s: Sprite2D = Sprite2D.new()
		s.texture = tex
		s.centered = true
		s.offset = FLOOR_SPRITE_OFFSET
		s.modulate = modulate
		s.position = IsoUtils.tile_to_world(tile)
		add_child(s)


func _render_walls() -> void:
	var tex: Texture2D = load(WALL_TEX_PATH)
	if tex == null:
		push_error("EchoDungeon: missing wall tex %s" % WALL_TEX_PATH)
		return
	var floor_tiles: Dictionary = _dungeon.get("floor_tiles", {})
	var modulate: Color = _theme["tile_modulate"]
	var wall_set: Dictionary = {}
	for tile: Vector2i in floor_tiles.keys():
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = tile + d
			if not floor_tiles.has(n):
				wall_set[n] = true
	for wt: Vector2i in wall_set.keys():
		var s: Sprite2D = Sprite2D.new()
		s.texture = tex
		s.centered = true
		s.offset = WALL_SPRITE_OFFSET
		s.modulate = modulate
		s.position = IsoUtils.tile_to_world(wt)
		s.y_sort_enabled = true
		add_child(s)


func _add_canvas_modulate() -> void:
	var cm: CanvasModulate = CanvasModulate.new()
	cm.color = _theme["ambient"]
	add_child(cm)


func _add_room_lights() -> void:
	var centers: Array[Vector2i] = _dungeon.get("room_centers", [])
	for c: Vector2i in centers:
		var pl: PointLight2D = PointLight2D.new()
		pl.texture = _light_texture
		pl.color = _theme["light"]
		pl.energy = ROOM_LIGHT_ENERGY
		pl.texture_scale = ROOM_LIGHT_RANGE_PX / 128.0
		pl.position = IsoUtils.tile_to_world(c)
		pl.shadow_enabled = false
		add_child(pl)


func _spawn_return_portal() -> void:
	var entrance: Vector2i = _dungeon.get("entrance", Vector2i.ZERO)
	var portal: ScenePortal = PORTAL_SCENE.instantiate()
	portal.target_scene = HUB_SCENE_PATH
	portal.label_text = "← Whitestone"
	portal.quest_complete_id = ""
	portal.portal_color = Color(0.8, 0.7, 1.0, 0.85)
	portal.position = IsoUtils.tile_to_world(entrance + Vector2i(0, -1))
	add_child(portal)


func _spawn_boss() -> void:
	var dungeon_exit: Vector2i = _dungeon.get("exit", Vector2i.ZERO)
	var entrance: Vector2i = _dungeon.get("entrance", Vector2i.ZERO)
	if dungeon_exit == entrance:
		return
	var boss: CharacterBody2D = ENEMY_SCENE.instantiate()
	var hp_mult: float = EchoState.tier_hp_multiplier()
	var dmg_mult: float = EchoState.tier_dmg_multiplier()
	if EchoState.is_pinnacle_tier():
		boss.hp_max = int(PINNACLE_BASE_HP * hp_mult)
		boss.attack_damage = int(PINNACLE_BASE_DMG * dmg_mult)
		boss.drops_count = PINNACLE_BASE_DROPS
		boss.drops_min_rarity = Item.Rarity.UNIQUE  # guaranteed unique
		boss.boss_name = "Pinnacle (Tier %d)" % EchoState.current_tier
		boss.quest_on_death = "slay_pinnacle"
		boss.sprite_variant = PINNACLE_SPRITE_VARIANT
	else:
		boss.hp_max = int(REGULAR_BOSS_BASE_HP * hp_mult)
		boss.attack_damage = int(REGULAR_BOSS_BASE_DMG * dmg_mult)
		boss.drops_count = REGULAR_BOSS_BASE_DROPS
		boss.drops_min_rarity = Item.Rarity.RARE
		boss.boss_name = "%s Echo (Tier %d)" % [String(_theme["name"]), EchoState.current_tier]
		boss.sprite_variant = REGULAR_BOSS_SPRITE_VARIANT
	boss.is_boss = true
	boss.item_level = 8 + EchoState.current_tier
	boss.position = IsoUtils.tile_to_world(dungeon_exit)
	add_child(boss)


func _place_player() -> void:
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player == null:
		return
	var entrance: Vector2i = _dungeon.get("entrance", Vector2i.ZERO)
	if player.has_method(&"set_spawn_tile"):
		player.set_spawn_tile(entrance)
	else:
		player.global_position = IsoUtils.tile_to_world(entrance)


func _spawn_enemies() -> void:
	var centers: Array[Vector2i] = _dungeon.get("room_centers", [])
	if centers.size() <= 1:
		return
	var hp_mult: float = EchoState.tier_hp_multiplier()
	var dmg_mult: float = EchoState.tier_dmg_multiplier()
	var spawned: int = 0
	for i: int in range(1, centers.size() - 1):
		if spawned >= MAX_ENEMIES:
			break
		for j: int in range(ENEMIES_PER_ROOM):
			if spawned >= MAX_ENEMIES:
				break
			var enemy: CharacterBody2D = ENEMY_SCENE.instantiate()
			enemy.hp_max = int(TRASH_BASE_HP * hp_mult)
			enemy.attack_damage = int(TRASH_BASE_DMG * dmg_mult)
			enemy.item_level = TRASH_BASE_ITEM_LEVEL + EchoState.current_tier
			enemy.sprite_variant = (EchoState.current_tier % 4) + 4
			var jitter: Vector2i = Vector2i(j, 0)
			enemy.position = IsoUtils.tile_to_world(centers[i] + jitter)
			add_child(enemy)
			spawned += 1


func _log_validation() -> void:
	var floor_tiles: Dictionary = _dungeon.get("floor_tiles", {})
	var entrance: Vector2i = _dungeon.get("entrance", Vector2i.ZERO)
	var unreachable: int = FloodFill.unreachable_count(entrance, floor_tiles)
	var rooms: Array = _dungeon.get("rooms", [])
	if unreachable > 0:
		push_warning("EchoDungeon T%d (%s): %d unreachable tiles across %d rooms" % [
			EchoState.current_tier, String(_theme["name"]), unreachable, rooms.size()
		])
	else:
		print("EchoDungeon T%d (%s): %d rooms, %d tiles, fully connected, pinnacle=%s" % [
			EchoState.current_tier,
			String(_theme["name"]),
			rooms.size(),
			floor_tiles.size(),
			"yes" if EchoState.is_pinnacle_tier() else "no",
		])


func _make_light_texture() -> Texture2D:
	var grad: Gradient = Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var gt: GradientTexture2D = GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 256
	gt.height = 256
	return gt
