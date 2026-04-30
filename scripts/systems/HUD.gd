extends CanvasLayer

## HUD — autoload `CanvasLayer`. Owns the always-on bottom bar (HP orb +
## hotbar + resource-orb placeholder) and the toggleable Inventory and
## Character panels. Toggled via `I` and `C`; `Esc` closes any open panel.
##
## The HUD is an autoload so it survives scene reloads (player respawn, future
## level transitions) without losing inventory/equip state. The Player
## registers itself via `bind_player(player)` so the orb can subscribe to
## `hp_changed` instead of polling.

const HUD_LAYER: int = 50
const BOTTOM_PADDING: int = 24
const SIDE_PADDING: int = 24

var _root: Control = null
var _hp_orb: HPOrb = null
var _hotbar_ui: HotbarUI = null
var _resource_placeholder: Control = null
var _inventory_panel: InventoryPanel = null
var _character_panel: CharacterPanel = null
var _player: CharacterBody2D = null


func _ready() -> void:
	layer = HUD_LAYER
	_build_root()
	_build_bottom_bar()
	_build_panels()


func _build_root() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)


func _build_bottom_bar() -> void:
	var bar: HBoxContainer = HBoxContainer.new()
	bar.add_theme_constant_override(&"separation", 32)
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left = SIDE_PADDING
	bar.offset_right = -SIDE_PADDING
	bar.offset_top = -160
	bar.offset_bottom = -BOTTOM_PADDING
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bar)

	_hp_orb = HPOrb.new()
	bar.add_child(_hp_orb)

	var spacer_l: Control = Control.new()
	spacer_l.custom_minimum_size = Vector2(40, 0)
	bar.add_child(spacer_l)

	_hotbar_ui = HotbarUI.new()
	bar.add_child(_hotbar_ui)

	var spacer_r: Control = Control.new()
	spacer_r.custom_minimum_size = Vector2(40, 0)
	bar.add_child(spacer_r)

	_resource_placeholder = _build_resource_placeholder()
	bar.add_child(_resource_placeholder)


func _build_resource_placeholder() -> Control:
	# Spec §6.1 calls for a Resource orb (mana / fury / cold). Resource pools
	# arrive Weeks 7–9 with class skills; until then this is a dimmed mirror
	# of the HP orb so the layout reads correctly.
	var c: Control = Control.new()
	c.custom_minimum_size = Vector2(112, 112)
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.12, 0.6)
	sb.border_color = Color(0.3, 0.3, 0.35)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(56)
	var p: PanelContainer = PanelContainer.new()
	p.add_theme_stylebox_override(&"panel", sb)
	p.custom_minimum_size = Vector2(112, 112)
	p.modulate = Color(1, 1, 1, 0.4)
	var lbl: Label = Label.new()
	lbl.text = "RES"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override(&"font_color", Color(0.6, 0.6, 0.7))
	p.add_child(lbl)
	c.add_child(p)
	return c


func _build_panels() -> void:
	_inventory_panel = InventoryPanel.new()
	_inventory_panel.set_anchors_preset(Control.PRESET_CENTER)
	_inventory_panel.position = Vector2(-270, -260)
	_inventory_panel.visible = false
	_root.add_child(_inventory_panel)

	_character_panel = CharacterPanel.new()
	_character_panel.set_anchors_preset(Control.PRESET_CENTER)
	_character_panel.position = Vector2(-270, 20)
	_character_panel.visible = false
	_root.add_child(_character_panel)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k: InputEventKey = event
	if not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_I:
			_inventory_panel.visible = not _inventory_panel.visible
			get_viewport().set_input_as_handled()
		KEY_C:
			_character_panel.visible = not _character_panel.visible
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			if _inventory_panel.visible or _character_panel.visible:
				_inventory_panel.visible = false
				_character_panel.visible = false
				get_viewport().set_input_as_handled()


func bind_player(player: CharacterBody2D) -> void:
	_player = player
	if player.has_signal("hp_changed"):
		player.hp_changed.connect(_on_player_hp_changed)


func _on_player_hp_changed(current: int, maximum: int) -> void:
	if _hp_orb != null:
		_hp_orb.set_hp(current, maximum)
