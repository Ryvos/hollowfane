extends Node2D

## Catacombs — first procedural biome. Generates a BSP dungeon, renders floor +
## wall sprites, places the player at the entrance, scatters enemies in the
## remaining rooms, and lights the scene with one PointLight2D per room plus a
## CanvasModulate for the cold-blue ambient (spec §4.5: "Catacombs cold blue").
##
## v0.5.0 still uses Sprite2D rendering rather than a real `TileSet.tres`. Hand-
## authoring isometric TileSet resources outside the editor is brittle (atlas
## metadata + per-cell offsets) — the proper TileSet lands Week 6 alongside the
## hand-authored Whitestone hub, where the editor-driven asset pipeline is the
## natural place to bring it in.

const DUNGEON_W_TILES: int = 28
const DUNGEON_H_TILES: int = 28
const FLOOR_TEX_PATH: String = "res://assets/tiles/kenney_iso_miniature_dungeon/Isometric/dirt_E.png"
const WALL_TEX_PATH: String = "res://assets/tiles/kenney_iso_miniature_dungeon/Isometric/stoneWallAged_E.png"
const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/Enemy.tscn")
const PORTAL_SCENE: PackedScene = preload("res://scenes/actors/ScenePortal.tscn")
const HUB_SCENE_PATH: String = "res://scenes/main/Main.tscn"
const BISHOP_HP: int = 280
const BISHOP_DMG: int = 25
const BISHOP_ITEM_LEVEL: int = 5
const BISHOP_DROPS: int = 4
const BISHOP_DROP_MIN_RARITY: int = 1  # Item.Rarity.MAGIC
const FLOOR_SPRITE_OFFSET: Vector2 = Vector2(0, -128)
const WALL_SPRITE_OFFSET: Vector2 = Vector2(0, -256)
const AMBIENT_TINT: Color = Color(0.18, 0.22, 0.32)
const ROOM_LIGHT_COLOR: Color = Color(0.95, 0.85, 0.55)
const ROOM_LIGHT_RANGE_PX: float = 480.0
const ROOM_LIGHT_ENERGY: float = 1.6
const ENEMIES_PER_ROOM: int = 1
const MAX_ENEMIES: int = 6
const RNG_SEED_DEFAULT: int = 0xC47AC0


@export var rng_seed: int = RNG_SEED_DEFAULT

var _dungeon: Dictionary = {}
var _light_texture: Texture2D = null


func _ready() -> void:
	y_sort_enabled = true
	_light_texture = _make_light_texture()
	_generate(rng_seed if rng_seed != 0 else int(Time.get_unix_time_from_system()))
	_render_floor()
	_render_walls()
	_add_canvas_modulate()
	_add_room_lights()
	_spawn_return_portal()
	_spawn_boss()
	# Defer player placement so it runs after every sibling _ready (the Player
	# may not have added itself to the "player" group yet if Catacombs runs
	# first in Main's child order).
	call_deferred(&"_place_player")
	call_deferred(&"_spawn_enemies")
	_log_validation()


func _spawn_return_portal() -> void:
	var entrance: Vector2i = _dungeon.get("entrance", Vector2i.ZERO)
	var portal: ScenePortal = PORTAL_SCENE.instantiate()
	portal.target_scene = HUB_SCENE_PATH
	portal.label_text = "← Whitestone"
	portal.quest_complete_id = ""
	portal.portal_color = Color(0.85, 0.65, 0.35, 0.85)
	# Place the portal one tile north of the entrance so the player isn't
	# standing on it the moment they arrive.
	portal.position = IsoUtils.tile_to_world(entrance + Vector2i(0, -1))
	add_child(portal)


func _spawn_boss() -> void:
	if QuestLog.is_complete("slay_hollow_bishop"):
		# The bishop is dead and stays dead — even if the dungeon regenerates.
		return
	var dungeon_exit: Vector2i = _dungeon.get("exit", Vector2i.ZERO)
	var entrance: Vector2i = _dungeon.get("entrance", Vector2i.ZERO)
	if dungeon_exit == entrance:
		return  # single-room dungeon edge case
	var bishop: CharacterBody2D = ENEMY_SCENE.instantiate()
	bishop.hp_max = BISHOP_HP
	bishop.attack_damage = BISHOP_DMG
	bishop.item_level = BISHOP_ITEM_LEVEL
	bishop.is_boss = true
	bishop.boss_name = "The Hollow Bishop"
	bishop.quest_on_death = "slay_hollow_bishop"
	bishop.drops_count = BISHOP_DROPS
	bishop.drops_min_rarity = BISHOP_DROP_MIN_RARITY
	bishop.sprite_variant = 2  # Male_2 — a third silhouette for the boss
	bishop.position = IsoUtils.tile_to_world(dungeon_exit)
	add_child(bishop)


func _generate(seed_val: int) -> void:
	_dungeon = BSPDungeon.generate(seed_val, DUNGEON_W_TILES, DUNGEON_H_TILES)


func _render_floor() -> void:
	var tex: Texture2D = load(FLOOR_TEX_PATH)
	if tex == null:
		push_error("Catacombs: missing floor tex %s" % FLOOR_TEX_PATH)
		return
	var floor_tiles: Dictionary = _dungeon.get("floor_tiles", {})
	for tile: Vector2i in floor_tiles.keys():
		var s: Sprite2D = Sprite2D.new()
		s.texture = tex
		s.centered = true
		s.offset = FLOOR_SPRITE_OFFSET
		s.position = IsoUtils.tile_to_world(tile)
		add_child(s)


func _render_walls() -> void:
	var tex: Texture2D = load(WALL_TEX_PATH)
	if tex == null:
		push_error("Catacombs: missing wall tex %s" % WALL_TEX_PATH)
		return
	var floor_tiles: Dictionary = _dungeon.get("floor_tiles", {})
	# Walls sit on every tile that is *adjacent* to a floor tile but not itself
	# walkable. That gives a tight outline of the rooms + corridors.
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
		s.position = IsoUtils.tile_to_world(wt)
		s.y_sort_enabled = true
		add_child(s)


func _add_canvas_modulate() -> void:
	var cm: CanvasModulate = CanvasModulate.new()
	cm.color = AMBIENT_TINT
	add_child(cm)


func _add_room_lights() -> void:
	var centers: Array[Vector2i] = _dungeon.get("room_centers", [])
	for c: Vector2i in centers:
		var pl: PointLight2D = PointLight2D.new()
		pl.texture = _light_texture
		pl.color = ROOM_LIGHT_COLOR
		pl.energy = ROOM_LIGHT_ENERGY
		pl.texture_scale = ROOM_LIGHT_RANGE_PX / 128.0
		pl.position = IsoUtils.tile_to_world(c)
		pl.shadow_enabled = false
		add_child(pl)


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
	var dungeon_exit: Vector2i = _dungeon.get("exit", Vector2i.ZERO)
	var spawned: int = 0
	# Skip room 0 (entrance) so the player gets a moment before the first
	# fight; skip the exit room because the boss lives there.
	for i: int in range(1, centers.size() - 1):
		if spawned >= MAX_ENEMIES:
			break
		for j: int in range(ENEMIES_PER_ROOM):
			if spawned >= MAX_ENEMIES:
				break
			var enemy: CharacterBody2D = ENEMY_SCENE.instantiate()
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
		push_warning("Catacombs seed=%d: %d unreachable tiles across %d rooms" % [
			int(_dungeon.get("seed", 0)), unreachable, rooms.size()
		])
	else:
		print("Catacombs seed=%d: %d rooms, %d tiles, fully connected." % [
			int(_dungeon.get("seed", 0)), rooms.size(), floor_tiles.size()
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
