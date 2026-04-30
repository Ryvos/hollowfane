extends Node2D

## SpikeLevel — procedural floor + 1 enemy spawn for the v0.2.0 combat spike.
##
## Floor is still Sprite2D-based (TileMapLayer + TileSet.tres lands Week 5).
## Enemy spawns at tile (4,4) so the player at (0,0) can walk over and engage.

const FLOOR_SIZE: int = 8
const FLOOR_TEX_PATH: String = "res://assets/tiles/kenney_iso_miniature_dungeon/Isometric/dirt_E.png"
const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/Enemy.tscn")
const ENEMY_SPAWN_TILE: Vector2i = Vector2i(4, 4)


func _ready() -> void:
	y_sort_enabled = true
	var tex: Texture2D = load(FLOOR_TEX_PATH)
	if tex == null:
		push_error("SpikeLevel: failed to load floor tile at %s" % FLOOR_TEX_PATH)
		return
	for x: int in range(FLOOR_SIZE):
		for y: int in range(FLOOR_SIZE):
			var s: Sprite2D = Sprite2D.new()
			s.texture = tex
			s.centered = true
			s.offset = Vector2(0, -128)
			s.position = IsoUtils.tile_to_world(Vector2i(x, y))
			add_child(s)
	var enemy: CharacterBody2D = ENEMY_SCENE.instantiate()
	enemy.position = IsoUtils.tile_to_world(ENEMY_SPAWN_TILE)
	add_child(enemy)
