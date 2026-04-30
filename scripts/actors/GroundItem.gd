extends Area2D
class_name GroundItem

## GroundItem — a single dropped item rendered on the floor as a colored gem
## with a name label, clickable to pick up and equip.
##
## Implementation notes:
##   - Area2D + CollisionShape2D so Godot's input system fires `mouse_entered`
##     / `mouse_exited` (drives the Tooltip) and `input_event` (drives the
##     pickup click).
##   - `get_viewport().set_input_as_handled()` consumes the click so the
##     Player's `_unhandled_input` doesn't also try to walk to that tile.
##   - On equip-replace, the previously equipped item gets dropped back onto
##     the ground at this position with a small jitter — keeps progress
##     reversible without an inventory grid (which arrives Week 4).

const ITEM_PIXEL_SIZE: float = 18.0
const LABEL_OFFSET: Vector2 = Vector2(0, -34)
const REPLACE_JITTER_PX: float = 32.0

@export var item: Item = null

@onready var _gem: ColorRect = $Gem
@onready var _label: Label = $Label


func _ready() -> void:
	add_to_group(&"ground_item")
	monitoring = false
	monitorable = false
	input_pickable = true
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_refresh_visual()


func set_item(it: Item) -> void:
	item = it
	if is_inside_tree():
		_refresh_visual()


func _refresh_visual() -> void:
	if item == null:
		return
	if _gem != null:
		_gem.color = item.get_color()
	if _label != null:
		_label.text = item.get_display_name()
		_label.modulate = item.get_color()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_on_clicked()
			get_viewport().set_input_as_handled()


func _on_clicked() -> void:
	if item == null:
		queue_free()
		return
	var prev: Item = PlayerStats.equip(item)
	var here: Vector2 = global_position
	var parent: Node = get_parent()
	Tooltip.hide_tip()
	queue_free()
	if prev != null and parent != null:
		var ground_scene: PackedScene = preload("res://scenes/actors/GroundItem.tscn")
		var dropped: GroundItem = ground_scene.instantiate()
		dropped.item = prev
		dropped.position = here + Vector2(
			randf_range(-REPLACE_JITTER_PX, REPLACE_JITTER_PX),
			randf_range(-REPLACE_JITTER_PX, REPLACE_JITTER_PX)
		)
		parent.call_deferred(&"add_child", dropped)


func _on_mouse_entered() -> void:
	Tooltip.show_for(item)


func _on_mouse_exited() -> void:
	Tooltip.hide_tip()
