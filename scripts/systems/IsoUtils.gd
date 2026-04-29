extends Node

## IsoUtils — autoloaded singleton.
##
## All tile <-> world coordinate conversions for the 2:1 dimetric projection
## funnel through this file. Every iso project that doesn't centralize this
## math grows subtle off-by-half-tile bugs as the codebase expands.
##
## Math reference (2:1 dimetric, screen-y is down):
##   world_x = (tile_x - tile_y) * (TILE_W / 2)
##   world_y = (tile_x + tile_y) * (TILE_H / 2)
## Inverse:
##   a = world_x / (TILE_W / 2)   ; equals (tile_x - tile_y)
##   b = world_y / (TILE_H / 2)   ; equals (tile_x + tile_y)
##   tile_x = (a + b) / 2
##   tile_y = (b - a) / 2

## Tile footprint in pixels. Spec §4.1 expected 64×32 (pixel-art).
## Kenney "Isometric Miniature" tiles are rendered 3D at 256×128 — same 2:1
## ratio, just 4× scale. Adjust both constants together to switch art packs.
const TILE_W: int = 256
const TILE_H: int = 128


func tile_to_world(tile: Vector2i) -> Vector2:
	var hw: float = TILE_W / 2.0
	var hh: float = TILE_H / 2.0
	return Vector2(
		(tile.x - tile.y) * hw,
		(tile.x + tile.y) * hh
	)


func world_to_tile(world: Vector2) -> Vector2i:
	var hw: float = TILE_W / 2.0
	var hh: float = TILE_H / 2.0
	var a: float = world.x / hw
	var b: float = world.y / hh
	return Vector2i(
		int(floor((a + b) / 2.0)),
		int(floor((b - a) / 2.0))
	)


## 8-octant heading from src tile to dst tile, e.g. "n", "se", "w".
## Used by the player's animated sprite to pick the right facing.
func tile_heading(src: Vector2i, dst: Vector2i) -> String:
	var dx: int = dst.x - src.x
	var dy: int = dst.y - src.y
	if dx == 0 and dy == 0:
		return "s"
	var screen: Vector2 = Vector2(dx - dy, dx + dy)
	var angle_deg: float = rad_to_deg(screen.angle())
	var octant: int = int(round(angle_deg / 45.0)) % 8
	if octant < 0:
		octant += 8
	const NAMES: Array[String] = ["e", "se", "s", "sw", "w", "nw", "n", "ne"]
	return NAMES[octant]
