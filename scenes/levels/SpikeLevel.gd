extends Node2D

## SpikeLevel — procedural 8×8 floor of Sprite2D children for the v0.1.0 spike.
##
## We don't use TileMapLayer + TileSet.tres yet. Authoring a TileSet resource
## as raw text is finicky outside the Godot editor; the spike's job is to
## prove iso math works, which placing Sprite2D children at IsoUtils-derived
## positions demonstrates equally well. TileMapLayer authoring lands Week 2+.

const FLOOR_SIZE: int = 8
const FLOOR_TEX_PATH: String = "res://assets/tiles/kenney_iso_miniature_dungeon/Isometric/dirt_E.png"


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
			# Kenney iso tile texture is 256x512 with the floor face occupying
			# the bottom half. Shift up by ~half the height so the floor-face
			# center sits at the IsoUtils tile center.
			s.offset = Vector2(0, -128)
			s.position = IsoUtils.tile_to_world(Vector2i(x, y))
			add_child(s)
