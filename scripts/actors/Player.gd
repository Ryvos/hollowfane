extends CharacterBody2D

## Player — click-to-move + click-to-attack on the iso grid.
##
## Left-click rules:
##   - if click world-pos is within ATTACK_REACH_PX of an enemy → attack closest
##   - else → walk to clicked tile (existing v0.1.0 behavior)
##
## HP/death/respawn: damage from enemies decrements _hp; on HP=0 the player
## resets to spawn and refills (10% XP-debt is a placeholder for v0.3.0+).

const SPEED_PIXELS_PER_SEC: float = 320.0
const ARRIVAL_EPSILON: float = 4.0
const SPRITE_SCALE: float = 0.4
const HP_MAX: int = 100
const ATTACK_DAMAGE: int = 25
const ATTACK_REACH_PX: float = 240.0  # world-space click tolerance for enemy hit

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hp_bar: Control = $HPBar

var _target_tile: Vector2i
var _has_target: bool = false
var _hp: int = HP_MAX
var _spawn_position: Vector2 = Vector2.ZERO

signal hp_changed(current: int, maximum: int)
signal died()


func _ready() -> void:
	add_to_group(&"player")
	_setup_animation_frames()
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_sprite.offset = Vector2(0, -200 * SPRITE_SCALE)
	_sprite.play(&"idle")
	_spawn_position = IsoUtils.tile_to_world(Vector2i.ZERO)
	global_position = _spawn_position
	hp_changed.connect(_on_hp_changed)
	hp_changed.emit(_hp, HP_MAX)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var click_world: Vector2 = get_global_mouse_position()
			var enemy: Node = _find_enemy_near(click_world, ATTACK_REACH_PX)
			if enemy != null:
				_attack(enemy)
			else:
				_target_tile = IsoUtils.world_to_tile(click_world)
				_has_target = true
				if _sprite.animation != &"run":
					_sprite.play(&"run")


func _physics_process(delta: float) -> void:
	if not _has_target:
		return
	var target_world: Vector2 = IsoUtils.tile_to_world(_target_tile)
	var to_target: Vector2 = target_world - global_position
	var dist: float = to_target.length()
	if dist <= ARRIVAL_EPSILON:
		global_position = target_world
		_has_target = false
		_sprite.play(&"idle")
		return
	var step: float = minf(SPEED_PIXELS_PER_SEC * delta, dist)
	global_position += to_target.normalized() * step


func _find_enemy_near(pos: Vector2, reach: float) -> Node:
	var enemies: Array[Node] = get_tree().get_nodes_in_group(&"enemy")
	var closest: Node = null
	var closest_dist: float = reach
	for e: Node in enemies:
		if not is_instance_valid(e):
			continue
		var d: float = (e.global_position - pos).length()
		if d < closest_dist:
			closest_dist = d
			closest = e
	return closest


func _attack(enemy: Node) -> void:
	# Stop moving + flash to idle so the swing reads (animation polish later).
	_has_target = false
	_sprite.play(&"idle")
	if enemy.has_method(&"take_damage"):
		enemy.take_damage(ATTACK_DAMAGE)


func take_damage(amount: int) -> void:
	_hp = maxi(0, _hp - amount)
	DamageNumbers.spawn(amount, global_position, Color(1.0, 0.3, 0.3))
	hp_changed.emit(_hp, HP_MAX)
	if _hp <= 0:
		_respawn()


func _respawn() -> void:
	# Spec §4.6: 10% XP debt placeholder — wired when XP exists in v0.3.0+.
	_hp = HP_MAX
	global_position = _spawn_position
	_has_target = false
	_sprite.play(&"idle")
	hp_changed.emit(_hp, HP_MAX)
	died.emit()


func _on_hp_changed(current: int, maximum: int) -> void:
	if _hp_bar and _hp_bar.has_method(&"set_hp"):
		_hp_bar.set_hp(current, maximum)


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
