extends Node2D

## WhitestoneHub — Act I village. Spec §5.3 calls it the place "where you
## start and return between dives". This v0.6.0 build is intentionally a
## skeleton: a small dirt floor with the four canonical NPCs (Smith, Imbuer,
## Stash, Quest Board) and one Catacombs portal. Each NPC is a clickable
## placeholder; their real mechanics ship Weeks 7–9 alongside the systems
## they need (gear sales, imbuement crafting, bottomless stash, quest
## acceptance UI).

const FLOOR_SIZE: int = 7
const FLOOR_TEX_PATH: String = "res://assets/tiles/kenney_iso_miniature_dungeon/Isometric/dirt_E.png"
const NPC_SCENE: PackedScene = preload("res://scenes/actors/NPC.tscn")
const PORTAL_SCENE: PackedScene = preload("res://scenes/actors/ScenePortal.tscn")
const SPAWN_TILE: Vector2i = Vector2i(3, 3)
const CATACOMBS_PORTAL_TARGET: String = "res://scenes/main/Main_Catacombs.tscn"
const FROSTVEIN_PORTAL_TARGET: String = "res://scenes/main/Main_Frostvein.tscn"
const CINDERFALL_PORTAL_TARGET: String = "res://scenes/main/Main_Cinderfall.tscn"

const NPCS: Array[Dictionary] = [
	{
		"id": "smith",
		"name": "Brask the Smith",
		"role": "I forge, mend, and sharpen — when the trade arrives next moon. (Coming Week 8.)",
		"tile": Vector2i(1, 2),
		"color": Color(0.55, 0.35, 0.15),
		"quest_complete": "speak_to_smith",
	},
	{
		"id": "imbuer",
		"name": "Veska the Imbuer",
		"role": "Bring me three trinkets of one shape; I will make them sing as one.",
		"tile": Vector2i(5, 2),
		"color": Color(0.55, 0.25, 0.55),
		"quest_complete": "",
		"panel": "imbue",
	},
	{
		"id": "stash",
		"name": "The Stash",
		"role": "Whatever you cannot carry, leave with me. (Coming Week 8.)",
		"tile": Vector2i(1, 4),
		"color": Color(0.35, 0.35, 0.55),
		"quest_complete": "",
	},
	{
		"id": "quest_board",
		"name": "Quest Board",
		"role": "Three notes are pinned. Read them with [b]Q[/b]. (Coming Week 9.)",
		"tile": Vector2i(5, 4),
		"color": Color(0.55, 0.50, 0.20),
		"quest_complete": "",
	},
]


func _ready() -> void:
	y_sort_enabled = true
	_render_floor()
	_spawn_npcs()
	_spawn_portal()
	call_deferred(&"_place_player")


func _render_floor() -> void:
	var tex: Texture2D = load(FLOOR_TEX_PATH)
	if tex == null:
		push_error("WhitestoneHub: missing floor tex %s" % FLOOR_TEX_PATH)
		return
	for x: int in range(FLOOR_SIZE):
		for y: int in range(FLOOR_SIZE):
			var s: Sprite2D = Sprite2D.new()
			s.texture = tex
			s.centered = true
			s.offset = Vector2(0, -128)
			s.position = IsoUtils.tile_to_world(Vector2i(x, y))
			add_child(s)


func _spawn_npcs() -> void:
	for entry: Dictionary in NPCS:
		var npc: NPC = NPC_SCENE.instantiate()
		npc.npc_id = String(entry["id"])
		npc.display_name = String(entry["name"])
		npc.role_text = String(entry["role"])
		npc.body_color = entry["color"]
		npc.quest_complete_id = String(entry["quest_complete"])
		npc.panel_id = String(entry.get("panel", ""))
		npc.position = IsoUtils.tile_to_world(entry["tile"])
		add_child(npc)


func _spawn_portal() -> void:
	var portal: ScenePortal = PORTAL_SCENE.instantiate()
	portal.target_scene = CATACOMBS_PORTAL_TARGET
	portal.label_text = "→ Catacombs"
	portal.quest_complete_id = "investigate_catacombs"
	portal.portal_color = Color(0.5, 0.45, 0.85, 0.85)
	portal.position = IsoUtils.tile_to_world(Vector2i(2, 6))
	add_child(portal)
	# Frostvein portal opens once the bishop is dead. Pre-bishop the portal is
	# present but quietly does nothing so Furyborn class-test players can still
	# travel without the gate (set target_scene unconditionally — the gate is
	# narrative, not mechanical, in v0.7.0).
	var frost_portal: ScenePortal = PORTAL_SCENE.instantiate()
	frost_portal.target_scene = FROSTVEIN_PORTAL_TARGET
	frost_portal.label_text = "→ Frostvein"
	frost_portal.quest_complete_id = ""
	frost_portal.portal_color = Color(0.55, 0.80, 0.95, 0.85)
	frost_portal.position = IsoUtils.tile_to_world(Vector2i(4, 6))
	add_child(frost_portal)
	var cinder_portal: ScenePortal = PORTAL_SCENE.instantiate()
	cinder_portal.target_scene = CINDERFALL_PORTAL_TARGET
	cinder_portal.label_text = "→ Cinderfall Spire"
	cinder_portal.quest_complete_id = ""
	cinder_portal.portal_color = Color(1.0, 0.55, 0.30, 0.90)
	cinder_portal.position = IsoUtils.tile_to_world(Vector2i(6, 6))
	add_child(cinder_portal)


func _place_player() -> void:
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player == null:
		return
	if player.has_method(&"set_spawn_tile"):
		player.set_spawn_tile(SPAWN_TILE)
	else:
		player.global_position = IsoUtils.tile_to_world(SPAWN_TILE)
