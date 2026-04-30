extends Node2D

## CinderfallSpire — Act III biome (spec §10 Week 9). Reuses BSPDungeon with
## an ember-orange tint and the Pact-Bearer in the exit room. Same scaffolding
## as Catacombs / Frostvein for v0.9.0 — the BiomeBase refactor is rolled
## forward to Week 10/11 (the three-biome diff is finally concrete now).
##
## Pact-Bearer is the Act III final boss. Spec §4.4 puts Mythic items at
## "endgame only"; the Pact-Bearer drops at min-Rare for the campaign close,
## while Mythic drops light up Week 10 with the Echo endgame system.

const DUNGEON_W_TILES: int = 30
const DUNGEON_H_TILES: int = 30
const FLOOR_TEX_PATH: String = "res://assets/tiles/kenney_iso_miniature_dungeon/Isometric/dirt_E.png"
const WALL_TEX_PATH: String = "res://assets/tiles/kenney_iso_miniature_dungeon/Isometric/stoneWallAged_E.png"
const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/Enemy.tscn")
const PORTAL_SCENE: PackedScene = preload("res://scenes/actors/ScenePortal.tscn")
const HUB_SCENE_PATH: String = "res://scenes/main/Main.tscn"
const FLOOR_SPRITE_OFFSET: Vector2 = Vector2(0, -128)
const WALL_SPRITE_OFFSET: Vector2 = Vector2(0, -256)
const AMBIENT_TINT: Color = Color(0.45, 0.18, 0.10)
const ROOM_LIGHT_COLOR: Color = Color(1.0, 0.55, 0.25)
const ROOM_LIGHT_RANGE_PX: float = 480.0
const ROOM_LIGHT_ENERGY: float = 1.8
const TILE_MODULATE: Color = Color(1.20, 0.85, 0.65)
const ENEMIES_PER_ROOM: int = 1
const MAX_ENEMIES: int = 7
const RNG_SEED_DEFAULT: int = 0xC1ABE71
const PACT_BEARER_HP: int = 520
const PACT_BEARER_DMG: int = 36
const PACT_BEARER_ITEM_LEVEL: int = 9
const PACT_BEARER_DROPS: int = 6
const PACT_BEARER_DROP_MIN_RARITY: int = 2  # Rare floor
const PACT_BEARER_SPRITE_VARIANT: int = 5
const ENEMY_SPRITE_VARIANT: int = 6

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
	call_deferred(&"_place_player")
	call_deferred(&"_spawn_enemies")
	_log_validation()


func _generate(seed_val: int) -> void:
	_dungeon = BSPDungeon.generate(seed_val, DUNGEON_W_TILES, DUNGEON_H_TILES)


func _render_floor() -> void:
	var tex: Texture2D = load(FLOOR_TEX_PATH)
	if tex == null:
		push_error("CinderfallSpire: missing floor tex %s" % FLOOR_TEX_PATH)
		return
	var floor_tiles: Dictionary = _dungeon.get("floor_tiles", {})
	for tile: Vector2i in floor_tiles.keys():
		var s: Sprite2D = Sprite2D.new()
		s.texture = tex
		s.centered = true
		s.offset = FLOOR_SPRITE_OFFSET
		s.modulate = TILE_MODULATE
		s.position = IsoUtils.tile_to_world(tile)
		add_child(s)


func _render_walls() -> void:
	var tex: Texture2D = load(WALL_TEX_PATH)
	if tex == null:
		push_error("CinderfallSpire: missing wall tex %s" % WALL_TEX_PATH)
		return
	var floor_tiles: Dictionary = _dungeon.get("floor_tiles", {})
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
		s.modulate = TILE_MODULATE
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


func _spawn_return_portal() -> void:
	var entrance: Vector2i = _dungeon.get("entrance", Vector2i.ZERO)
	var portal: ScenePortal = PORTAL_SCENE.instantiate()
	portal.target_scene = HUB_SCENE_PATH
	portal.label_text = "← Whitestone"
	portal.quest_complete_id = ""
	portal.portal_color = Color(1.0, 0.55, 0.30, 0.90)
	portal.position = IsoUtils.tile_to_world(entrance + Vector2i(0, -1))
	add_child(portal)


func _spawn_boss() -> void:
	if QuestLog.is_complete("confront_pact_bearer"):
		return
	var dungeon_exit: Vector2i = _dungeon.get("exit", Vector2i.ZERO)
	var entrance: Vector2i = _dungeon.get("entrance", Vector2i.ZERO)
	if dungeon_exit == entrance:
		return
	var pb: CharacterBody2D = ENEMY_SCENE.instantiate()
	pb.hp_max = PACT_BEARER_HP
	pb.attack_damage = PACT_BEARER_DMG
	pb.item_level = PACT_BEARER_ITEM_LEVEL
	pb.is_boss = true
	pb.boss_name = "The Pact-Bearer"
	pb.quest_on_death = "confront_pact_bearer"
	pb.drops_count = PACT_BEARER_DROPS
	pb.drops_min_rarity = PACT_BEARER_DROP_MIN_RARITY
	pb.sprite_variant = PACT_BEARER_SPRITE_VARIANT
	pb.position = IsoUtils.tile_to_world(dungeon_exit)
	add_child(pb)


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
	var spawned: int = 0
	for i: int in range(1, centers.size() - 1):
		if spawned >= MAX_ENEMIES:
			break
		for j: int in range(ENEMIES_PER_ROOM):
			if spawned >= MAX_ENEMIES:
				break
			var enemy: CharacterBody2D = ENEMY_SCENE.instantiate()
			enemy.sprite_variant = ENEMY_SPRITE_VARIANT
			enemy.hp_max = 130
			enemy.attack_damage = 18
			enemy.item_level = 7
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
		push_warning("CinderfallSpire seed=%d: %d unreachable tiles across %d rooms" % [
			int(_dungeon.get("seed", 0)), unreachable, rooms.size()
		])
	else:
		print("CinderfallSpire seed=%d: %d rooms, %d tiles, fully connected." % [
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
