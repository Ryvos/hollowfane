extends Control

## HPBar — small ColorRect-style bar drawn via _draw().
##
## Used as a child of CharacterBody2D actors (player + enemies). Positioned
## above the sprite by the parent's .tscn. Color shifts green → yellow → red
## as HP drops, so even at a glance the player can read enemy danger.

const WIDTH: float = 60.0
const HEIGHT: float = 6.0

var _hp: int = 1
var _hp_max: int = 1


func _ready() -> void:
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	# Background (black)
	draw_rect(Rect2(Vector2.ZERO, Vector2(WIDTH, HEIGHT)), Color(0.05, 0.05, 0.05, 0.85))
	var denom: int = maxi(_hp_max, 1)
	var ratio: float = clampf(float(_hp) / float(denom), 0.0, 1.0)
	var fill_w: float = WIDTH * ratio
	var color: Color = Color(0.2, 0.85, 0.3)  # green
	if ratio < 0.3:
		color = Color(0.9, 0.2, 0.2)  # red
	elif ratio < 0.6:
		color = Color(0.95, 0.85, 0.2)  # yellow
	draw_rect(Rect2(Vector2.ZERO, Vector2(fill_w, HEIGHT)), color)
	# Border
	draw_rect(Rect2(Vector2.ZERO, Vector2(WIDTH, HEIGHT)), Color(0, 0, 0, 0.9), false, 1.0)


func set_hp(current: int, maximum: int) -> void:
	_hp = current
	_hp_max = maximum
	queue_redraw()
