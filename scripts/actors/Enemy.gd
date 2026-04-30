extends CharacterBody2D

## Enemy — basic melee chaser with a 4-state machine: IDLE / CHASE / ATTACK / DEAD.
##
## Finds the player by group lookup (lazily, since instantiation order isn't
## guaranteed). Chases when out of attack range, attacks on cooldown when
## adjacent, dies + frees on HP=0.

const SPEED_PIXELS_PER_SEC: float = 160.0
const SPRITE_SCALE: float = 0.4
const HP_MAX: int = 60
const ATTACK_DAMAGE: int = 10
const ATTACK_RANGE_PX: float = 180.0
const ATTACK_COOLDOWN_S: float = 1.0
const VARIANT: int = 1  # Male_1 — distinct from player's Male_0
const ITEM_LEVEL: int = 3
const GROUND_ITEM_SCENE: PackedScene = preload("res://scenes/actors/GroundItem.tscn")

enum State { IDLE, CHASE, ATTACK, DEAD }

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hp_bar: Control = $HPBar

var _hp: int = HP_MAX
var _state: State = State.IDLE
var _attack_cd: float = 0.0
var _player: Node = null

signal hp_changed(current: int, maximum: int)


func _ready() -> void:
	add_to_group(&"enemy")
	_setup_animation_frames()
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_sprite.offset = Vector2(0, -200 * SPRITE_SCALE)
	_sprite.play(&"idle")
	hp_changed.connect(_on_hp_changed)
	hp_changed.emit(_hp, HP_MAX)


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	if _player == null or not is_instance_valid(_player):
		var ps: Array[Node] = get_tree().get_nodes_in_group(&"player")
		if ps.is_empty():
			return
		_player = ps[0]
	_attack_cd = maxf(0.0, _attack_cd - delta)
	var to_player: Vector2 = _player.global_position - global_position
	var dist: float = to_player.length()
	if dist > ATTACK_RANGE_PX:
		_state = State.CHASE
		if _sprite.animation != &"run":
			_sprite.play(&"run")
		var step: float = SPEED_PIXELS_PER_SEC * delta
		global_position += to_player.normalized() * step
	else:
		_state = State.ATTACK
		if _sprite.animation != &"idle":
			_sprite.play(&"idle")
		if _attack_cd <= 0.0 and _player.has_method(&"take_damage"):
			_attack_cd = ATTACK_COOLDOWN_S
			_player.take_damage(ATTACK_DAMAGE)


func take_damage(amount: int) -> void:
	if _state == State.DEAD:
		return
	_hp = maxi(0, _hp - amount)
	DamageNumbers.spawn(amount, global_position, Color(1.0, 0.95, 0.2))
	hp_changed.emit(_hp, HP_MAX)
	if _hp <= 0:
		_die()


func _die() -> void:
	_state = State.DEAD
	_drop_loot()
	queue_free()


func _drop_loot() -> void:
	var item: Item = LootRoller.roll(ITEM_LEVEL)
	if item == null:
		return
	var parent: Node = get_parent()
	if parent == null:
		return
	var ground: GroundItem = GROUND_ITEM_SCENE.instantiate()
	ground.item = item
	ground.global_position = global_position
	parent.call_deferred(&"add_child", ground)


func _on_hp_changed(current: int, maximum: int) -> void:
	if _hp_bar and _hp_bar.has_method(&"set_hp"):
		_hp_bar.set_hp(current, maximum)


func _setup_animation_frames() -> void:
	const CHAR_DIR: String = "res://assets/tiles/kenney_iso_miniature_dungeon/Characters/Male/"
	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", 1.0)
	var idle_tex: Texture2D = load("%sMale_%d_Idle0.png" % [CHAR_DIR, VARIANT])
	if idle_tex != null:
		frames.add_frame(&"idle", idle_tex)
	frames.add_animation(&"run")
	frames.set_animation_loop(&"run", true)
	frames.set_animation_speed(&"run", 12.0)
	for i: int in range(10):
		var t: Texture2D = load("%sMale_%d_Run%d.png" % [CHAR_DIR, VARIANT, i])
		if t != null:
			frames.add_frame(&"run", t)
	_sprite.sprite_frames = frames
