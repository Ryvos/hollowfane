extends CharacterBody2D

## Player — click-to-move on the iso grid.
##
## Click a tile → store target_tile → in _physics_process lerp toward the
## tile's world center → on arrival, snap and idle. AnimatedSprite2D plays
## "idle" or "run" depending on whether a target is active.

const SPEED_PIXELS_PER_SEC: float = 320.0
const ARRIVAL_EPSILON: float = 4.0
const SPRITE_SCALE: float = 0.4

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _target_tile: Vector2i
var _has_target: bool = false


func _ready() -> void:
	_setup_animation_frames()
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	# Kenney sprites are 256x512 anchored at center; offset shifts feet to origin.
	_sprite.offset = Vector2(0, -200 * SPRITE_SCALE)
	_sprite.play("idle")
	global_position = IsoUtils.tile_to_world(Vector2i.ZERO)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_target_tile = IsoUtils.world_to_tile(get_global_mouse_position())
			_has_target = true
			if _sprite.animation != &"run":
				_sprite.play("run")


func _physics_process(delta: float) -> void:
	if not _has_target:
		return
	var target_world: Vector2 = IsoUtils.tile_to_world(_target_tile)
	var to_target: Vector2 = target_world - global_position
	var dist: float = to_target.length()
	if dist <= ARRIVAL_EPSILON:
		global_position = target_world
		_has_target = false
		_sprite.play("idle")
		return
	var step: float = minf(SPEED_PIXELS_PER_SEC * delta, dist)
	global_position += to_target.normalized() * step


## Build SpriteFrames at runtime from the Kenney character PNGs. Doing this
## in code keeps the .tscn minimal and lets us swap variants by changing one
## constant. Move to authored SpriteFrames in Week 2+ when we have variety.
func _setup_animation_frames() -> void:
	const CHAR_DIR: String = "res://assets/tiles/kenney_iso_miniature_dungeon/Characters/Male/"
	const VARIANT: int = 0
	var frames: SpriteFrames = SpriteFrames.new()

	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", 1.0)
	var idle_path: String = "%sMale_%d_Idle0.png" % [CHAR_DIR, VARIANT]
	var idle_tex: Texture2D = load(idle_path)
	if idle_tex != null:
		frames.add_frame(&"idle", idle_tex)

	frames.add_animation(&"run")
	frames.set_animation_loop(&"run", true)
	frames.set_animation_speed(&"run", 12.0)
	for i: int in range(10):
		var run_path: String = "%sMale_%d_Run%d.png" % [CHAR_DIR, VARIANT, i]
		var run_tex: Texture2D = load(run_path)
		if run_tex != null:
			frames.add_frame(&"run", run_tex)

	_sprite.sprite_frames = frames
