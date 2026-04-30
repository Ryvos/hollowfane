extends Node

## DamageNumbers — autoloaded singleton.
##
## Spawns a floating Label at a world position that tweens up + fades, then
## frees itself. Called from Player.gd / Enemy.gd whenever damage lands.
## Kept dead simple for v0.2.0; Week 8's balance pass may add crit highlights,
## resist labels, etc.

const RISE_PX: float = 80.0
const DURATION_S: float = 0.8


func spawn(amount: int, world_pos: Vector2, color: Color = Color.WHITE) -> void:
	var label: Label = Label.new()
	label.text = str(amount)
	label.modulate = color
	label.z_index = 100
	label.add_theme_font_size_override(&"font_size", 36)
	label.position = world_pos - Vector2(20, 40)
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		label.free()
		return
	tree.current_scene.add_child(label)
	var tween: Tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - RISE_PX, DURATION_S)
	tween.tween_property(label, "modulate:a", 0.0, DURATION_S)
	tween.chain().tween_callback(label.queue_free)
