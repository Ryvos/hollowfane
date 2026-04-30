extends RefCounted
class_name BSPDungeon

## BSPDungeon — pure-data binary-space-partition dungeon generator (spec §4.5).
##
## generate(seed, width, height) returns a Dictionary with:
##   - rooms: Array[Rect2i]            — leaf rooms (8–12 typical)
##   - corridors: Array[PackedVector2Array]
##                                     — tile paths connecting sibling rooms
##   - floor_tiles: Dictionary         — Vector2i → true (every walkable tile)
##   - entrance: Vector2i              — first room's center (spawn point)
##   - exit: Vector2i                  — last room's center
##   - room_centers: Array[Vector2i]
##   - seed: int                       — echoed back for save-loading
##
## Algorithm:
##   1. Recursively split the bounding rect on the longer axis until depth or
##      size limits are hit. Random split offset within MIN_ROOM padding.
##   2. Each leaf gets a randomly-sized room placed inside its rect with at
##      least ROOM_PADDING between rooms.
##   3. For each internal node, drop an L-corridor between the centers of
##      its left and right subtrees. This guarantees the whole tree is
##      connected before flood-fill validation runs.
##
## All randomness is driven by a seeded RandomNumberGenerator so the same
## seed reproduces the same dungeon — a hard requirement for spec §8 saves.

const MIN_ROOM_W: int = 5
const MIN_ROOM_H: int = 5
const MAX_DEPTH: int = 4
const ROOM_PADDING: int = 1
const ROOM_SHRINK_MIN: int = 1
const ROOM_SHRINK_MAX: int = 3


static func generate(seed_val: int, width: int, height: int) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val
	var root: Dictionary = _make_node(Rect2i(0, 0, width, height))
	_partition(root, 0, rng)
	var leaves: Array[Dictionary] = []
	_collect_leaves(root, leaves)
	var rooms: Array[Rect2i] = []
	var room_centers: Array[Vector2i] = []
	var floor_tiles: Dictionary = {}
	for leaf: Dictionary in leaves:
		_place_room(leaf, rng)
		var r: Rect2i = leaf["room"]
		rooms.append(r)
		room_centers.append(r.position + Vector2i(r.size.x / 2, r.size.y / 2))
		for x: int in range(r.position.x, r.end.x):
			for y: int in range(r.position.y, r.end.y):
				floor_tiles[Vector2i(x, y)] = true
	var corridors: Array[PackedVector2Array] = []
	_build_corridors(root, corridors, floor_tiles, rng)
	var entrance: Vector2i = Vector2i.ZERO
	var dungeon_exit: Vector2i = Vector2i.ZERO
	if room_centers.size() >= 1:
		entrance = room_centers[0]
		dungeon_exit = room_centers[room_centers.size() - 1]
	return {
		"rooms": rooms,
		"corridors": corridors,
		"floor_tiles": floor_tiles,
		"entrance": entrance,
		"exit": dungeon_exit,
		"room_centers": room_centers,
		"seed": seed_val,
	}


static func _make_node(rect: Rect2i) -> Dictionary:
	return {"rect": rect, "left": null, "right": null, "room": Rect2i()}


static func _partition(node: Dictionary, depth: int, rng: RandomNumberGenerator) -> void:
	if depth >= MAX_DEPTH:
		return
	var rect: Rect2i = node["rect"]
	var w: int = rect.size.x
	var h: int = rect.size.y
	var can_split_x: bool = w >= (MIN_ROOM_W + ROOM_PADDING) * 2
	var can_split_y: bool = h >= (MIN_ROOM_H + ROOM_PADDING) * 2
	if not can_split_x and not can_split_y:
		return
	var split_h: bool
	if can_split_x and can_split_y:
		split_h = rng.randf() < 0.5 if absi(w - h) < 4 else h > w
	else:
		split_h = can_split_y
	if split_h:
		var sy: int = rng.randi_range(MIN_ROOM_H + ROOM_PADDING, h - MIN_ROOM_H - ROOM_PADDING)
		node["left"] = _make_node(Rect2i(rect.position.x, rect.position.y, w, sy))
		node["right"] = _make_node(Rect2i(rect.position.x, rect.position.y + sy, w, h - sy))
	else:
		var sx: int = rng.randi_range(MIN_ROOM_W + ROOM_PADDING, w - MIN_ROOM_W - ROOM_PADDING)
		node["left"] = _make_node(Rect2i(rect.position.x, rect.position.y, sx, h))
		node["right"] = _make_node(Rect2i(rect.position.x + sx, rect.position.y, w - sx, h))
	_partition(node["left"], depth + 1, rng)
	_partition(node["right"], depth + 1, rng)


static func _collect_leaves(node: Dictionary, out: Array[Dictionary]) -> void:
	if node["left"] == null and node["right"] == null:
		out.append(node)
		return
	if node["left"] != null:
		_collect_leaves(node["left"], out)
	if node["right"] != null:
		_collect_leaves(node["right"], out)


static func _place_room(leaf: Dictionary, rng: RandomNumberGenerator) -> void:
	var rect: Rect2i = leaf["rect"]
	var shrink_l: int = rng.randi_range(ROOM_SHRINK_MIN, ROOM_SHRINK_MAX)
	var shrink_t: int = rng.randi_range(ROOM_SHRINK_MIN, ROOM_SHRINK_MAX)
	var shrink_r: int = rng.randi_range(ROOM_SHRINK_MIN, ROOM_SHRINK_MAX)
	var shrink_b: int = rng.randi_range(ROOM_SHRINK_MIN, ROOM_SHRINK_MAX)
	var room_w: int = maxi(MIN_ROOM_W, rect.size.x - shrink_l - shrink_r)
	var room_h: int = maxi(MIN_ROOM_H, rect.size.y - shrink_t - shrink_b)
	var room_x: int = rect.position.x + shrink_l
	var room_y: int = rect.position.y + shrink_t
	# Clamp to ensure room stays inside the partition rect.
	if room_x + room_w > rect.end.x:
		room_x = rect.end.x - room_w
	if room_y + room_h > rect.end.y:
		room_y = rect.end.y - room_h
	leaf["room"] = Rect2i(room_x, room_y, room_w, room_h)


static func _build_corridors(
	node: Dictionary,
	corridors: Array[PackedVector2Array],
	floor_tiles: Dictionary,
	rng: RandomNumberGenerator
) -> void:
	if node["left"] == null or node["right"] == null:
		return
	_build_corridors(node["left"], corridors, floor_tiles, rng)
	_build_corridors(node["right"], corridors, floor_tiles, rng)
	var a: Vector2i = _pick_room_center(node["left"], rng)
	var b: Vector2i = _pick_room_center(node["right"], rng)
	var path: PackedVector2Array = _l_corridor(a, b, rng)
	for v: Vector2 in path:
		var tile: Vector2i = Vector2i(int(v.x), int(v.y))
		floor_tiles[tile] = true
	corridors.append(path)


static func _pick_room_center(node: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	# Walk down a random child until we hit a leaf, then return its room center.
	while node["left"] != null or node["right"] != null:
		var go_left: bool = node["left"] != null and (node["right"] == null or rng.randf() < 0.5)
		node = node["left"] if go_left else node["right"]
	var r: Rect2i = node["room"]
	return r.position + Vector2i(r.size.x / 2, r.size.y / 2)


static func _l_corridor(a: Vector2i, b: Vector2i, rng: RandomNumberGenerator) -> PackedVector2Array:
	var path: PackedVector2Array = PackedVector2Array()
	# 50/50 horizontal-then-vertical or vertical-then-horizontal.
	var horiz_first: bool = rng.randf() < 0.5
	if horiz_first:
		var x_step: int = signi(b.x - a.x)
		if x_step != 0:
			for x: int in range(a.x, b.x + x_step, x_step):
				path.append(Vector2(x, a.y))
		var y_step: int = signi(b.y - a.y)
		if y_step != 0:
			for y: int in range(a.y, b.y + y_step, y_step):
				path.append(Vector2(b.x, y))
	else:
		var y_step2: int = signi(b.y - a.y)
		if y_step2 != 0:
			for y: int in range(a.y, b.y + y_step2, y_step2):
				path.append(Vector2(a.x, y))
		var x_step2: int = signi(b.x - a.x)
		if x_step2 != 0:
			for x: int in range(a.x, b.x + x_step2, x_step2):
				path.append(Vector2(x, b.y))
	return path
