extends Node

## bot_play — randomized-input crash harness (spec §11 DoD: "Bot-play harness
## runs 1 hour of randomized inputs without a crash").
##
## This is a Node, not a SceneTree script — running it via `-s` would skip
## autoload registration, so we attach it to a real scene instead. Use:
##
##   godot --headless --quit-after=3600 res://tools/bot_main.tscn
##
## The companion `tools/bot_main.tscn` instances the WhitestoneHub level,
## the Player, and this driver. The driver fires randomized inputs every
## ACTION_INTERVAL_S seconds (mouse clicks, hotbar keys, panel toggles,
## quick save/load) until `duration_s` elapses, then calls `get_tree().quit()`.

@export var duration_s: int = 60
const HEARTBEAT_INTERVAL_S: float = 10.0
const ACTION_INTERVAL_S: float = 0.05

var _start_ms: int = 0
var _last_heartbeat_ms: int = 0
var _next_action_ms: int = 0
var _actions_fired: int = 0


func _ready() -> void:
	_start_ms = Time.get_ticks_msec()
	_last_heartbeat_ms = _start_ms
	for a: String in OS.get_cmdline_args():
		if a.begins_with("--duration="):
			duration_s = maxi(1, int(a.substr(11)))
	print("bot_play: starting %d-second harness" % duration_s)


func _process(_delta: float) -> void:
	var now_ms: int = Time.get_ticks_msec()
	var elapsed_s: float = (now_ms - _start_ms) / 1000.0
	if elapsed_s >= float(duration_s):
		print("bot_play: clean run — %.1fs / %d actions, no crashes" % [elapsed_s, _actions_fired])
		get_tree().quit(0)
		return
	if (now_ms - _last_heartbeat_ms) >= int(HEARTBEAT_INTERVAL_S * 1000.0):
		_last_heartbeat_ms = now_ms
		print("bot_play: %.0fs elapsed, %d actions fired" % [elapsed_s, _actions_fired])
	if now_ms >= _next_action_ms:
		_fire_random_action()
		_actions_fired += 1
		_next_action_ms = now_ms + int(ACTION_INTERVAL_S * 1000.0)


func _fire_random_action() -> void:
	var roll: int = randi() % 8
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var screen: Vector2 = vp.get_visible_rect().size
	var pos: Vector2 = Vector2(randf() * screen.x, randf() * screen.y)
	match roll:
		0, 1, 2:
			_inject_mouse_click(pos)
		3:
			_inject_key([KEY_1, KEY_2, KEY_3, KEY_4][randi() % 4])
		4:
			_inject_key([KEY_I, KEY_C, KEY_Q][randi() % 3])
		5:
			_inject_key(KEY_ESCAPE)
		6:
			_inject_key(KEY_F5)
		7:
			_inject_key(KEY_F9)


func _inject_mouse_click(pos: Vector2) -> void:
	var down: InputEventMouseButton = InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = pos
	down.global_position = pos
	Input.parse_input_event(down)
	var up: InputEventMouseButton = InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = pos
	up.global_position = pos
	Input.parse_input_event(up)


func _inject_key(keycode: int) -> void:
	var k_down: InputEventKey = InputEventKey.new()
	k_down.keycode = keycode
	k_down.pressed = true
	Input.parse_input_event(k_down)
	var k_up: InputEventKey = InputEventKey.new()
	k_up.keycode = keycode
	k_up.pressed = false
	Input.parse_input_event(k_up)
