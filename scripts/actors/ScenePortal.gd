extends Area2D
class_name ScenePortal

## ScenePortal — clickable tile that swaps the whole scene via
## `change_scene_to_file`. Used to travel between Whitestone hub and the
## Catacombs dungeon. Autoloads (PlayerStats, Inventory, QuestLog, Hotbar,
## HUD, Tooltip) survive the transition; the Player itself is destroyed and
## re-instantiated with full HP, which is acceptable spike behavior — a
## proper save+resume with HP persistence lands Week 11.
##
## The portal also fires `quest_complete_id` on use, so e.g. stepping into
## the Catacombs portal advances the "investigate_catacombs" quest.

const BG: Color = Color(0.6, 0.5, 0.85, 0.85)
const BORDER: Color = Color(0.95, 0.85, 0.55)

@export var target_scene: String = ""
@export var label_text: String = "Travel"
@export var quest_complete_id: String = ""
@export var portal_color: Color = Color(0.6, 0.5, 0.85, 0.85)

var _label: Label = null
var _glow: ColorRect = null


func _ready() -> void:
	add_to_group(&"scene_portal")
	monitoring = false
	monitorable = false
	input_pickable = true
	input_event.connect(_on_input_event)
	_build_visual()


func _build_visual() -> void:
	_glow = ColorRect.new()
	_glow.size = Vector2(96, 56)
	_glow.position = Vector2(-48, -56)
	_glow.color = portal_color
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glow)
	_label = Label.new()
	_label.text = label_text
	_label.position = Vector2(-80, -88)
	_label.size = Vector2(160, 22)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override(&"font_size", 14)
	_label.add_theme_color_override(&"font_color", Color.WHITE)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	var collision: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(96, 56)
	collision.shape = rect
	collision.position = Vector2(0, -28)
	add_child(collision)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_travel()
			get_viewport().set_input_as_handled()


func _travel() -> void:
	if target_scene == "":
		return
	if quest_complete_id != "":
		QuestLog.complete(quest_complete_id)
	get_tree().change_scene_to_file(target_scene)
