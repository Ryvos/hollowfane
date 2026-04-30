extends Control
class_name HPOrb

## HPOrb — circular HUD orb that fills from the bottom up like the D2 globe.
## Drawn in `_draw()` rather than a TextureProgressBar because we want the
## chord-clipped horizontal-line liquid effect: at any local y inside the
## circle, the filled span is the chord [center - sqrt(R²-dy²) ,
## center + sqrt(R²-dy²)]. Cheap, pixel-perfect, no shader required.

const RADIUS: float = 56.0
const FILL_BG: Color = Color(0.12, 0.04, 0.04, 0.92)
const FILL_HI: Color = Color(0.92, 0.18, 0.18)
const FILL_LO: Color = Color(0.55, 0.05, 0.05)
const RIM: Color = Color(0.45, 0.4, 0.32)
const LINE_STEP: float = 1.4
const RIM_WIDTH: float = 3.0

var _hp: int = 100
var _max: int = 100


func _ready() -> void:
	custom_minimum_size = Vector2(RADIUS * 2, RADIUS * 2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_hp(current: int, maximum: int) -> void:
	_hp = maxi(0, current)
	_max = maxi(1, maximum)
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = Vector2(RADIUS, RADIUS)
	draw_circle(center, RADIUS, FILL_BG)
	var ratio: float = clampf(float(_hp) / float(_max), 0.0, 1.0)
	if ratio > 0.0:
		var fill_top_y: float = (1.0 - ratio) * (RADIUS * 2.0)
		var y: float = fill_top_y
		while y < RADIUS * 2.0:
			var dy: float = y - RADIUS
			if absf(dy) <= RADIUS:
				var half_w: float = sqrt(RADIUS * RADIUS - dy * dy)
				var t: float = clampf((y / (RADIUS * 2.0)), 0.0, 1.0)
				var col: Color = FILL_LO.lerp(FILL_HI, t)
				draw_line(
					Vector2(RADIUS - half_w, y),
					Vector2(RADIUS + half_w, y),
					col,
					LINE_STEP
				)
			y += LINE_STEP
	draw_arc(center, RADIUS, 0.0, TAU, 64, RIM, RIM_WIDTH, true)
	# numeric readout
	var font: Font = ThemeDB.fallback_font
	var txt: String = "%d / %d" % [_hp, _max]
	var fsz: int = 16
	var sz: Vector2 = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fsz)
	draw_string_outline(font, center + Vector2(-sz.x * 0.5, sz.y * 0.3), txt, HORIZONTAL_ALIGNMENT_CENTER, -1.0, fsz, 4, Color.BLACK)
	draw_string(font, center + Vector2(-sz.x * 0.5, sz.y * 0.3), txt, HORIZONTAL_ALIGNMENT_CENTER, -1.0, fsz, Color.WHITE)
