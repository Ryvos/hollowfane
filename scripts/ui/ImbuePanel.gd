extends PanelContainer
class_name ImbuePanel

## ImbuePanel — Imbuer NPC interaction. Sacrifice 3 inventory items of the
## same slot → produce one Magic-or-Rare item of that slot at the highest
## item-level among the three (spec §4.4 "Imbuement"). The actual roll lives
## in `LootRoller.imbue()` so this panel is just selection + UX feedback.
##
## Selection model: click a cell to toggle. The Imbue button enables only when
## exactly 3 cells are selected AND every selected item shares the same slot.
## Mismatched slots show a hint at the bottom; this is the most common
## first-time mistake (mixing a gem with two weapons).

const CELL_SIZE: Vector2 = Vector2(48, 48)
const CELL_BG: Color = Color(0.08, 0.08, 0.10, 0.92)
const CELL_SELECTED: Color = Color(1.0, 0.85, 0.45)
const PANEL_BG: Color = Color(0.04, 0.04, 0.06, 0.95)
const PANEL_BORDER: Color = Color(0.55, 0.45, 0.32)
const HINT_OK: Color = Color(0.4, 0.95, 0.4)
const HINT_WARN: Color = Color(1.0, 0.55, 0.55)

var _grid: GridContainer = null
var _buttons: Array[Button] = []
var _selected: Array[int] = []  # inventory indices
var _imbue_button: Button = null
var _hint_label: Label = null


func _ready() -> void:
	_apply_panel_style()
	custom_minimum_size = Vector2(560, 320)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override(&"separation", 8)
	add_child(vb)
	var title: Label = Label.new()
	title.text = "Imbue — sacrifice 3 of the same slot for a fresh Magic or Rare"
	title.add_theme_font_size_override(&"font_size", 16)
	vb.add_child(title)
	_grid = GridContainer.new()
	_grid.columns = Inventory.GRID_W
	_grid.add_theme_constant_override(&"h_separation", 4)
	_grid.add_theme_constant_override(&"v_separation", 4)
	vb.add_child(_grid)
	for i: int in range(Inventory.TOTAL_CELLS):
		var b: Button = Button.new()
		b.custom_minimum_size = CELL_SIZE
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_on_cell_pressed.bind(i))
		b.mouse_entered.connect(_on_cell_hover.bind(i))
		b.mouse_exited.connect(_on_cell_unhover)
		_grid.add_child(b)
		_buttons.append(b)
	_hint_label = Label.new()
	_hint_label.text = "Pick 3 items of matching slot."
	_hint_label.add_theme_font_size_override(&"font_size", 13)
	vb.add_child(_hint_label)
	_imbue_button = Button.new()
	_imbue_button.text = "Imbue"
	_imbue_button.disabled = true
	_imbue_button.focus_mode = Control.FOCUS_NONE
	_imbue_button.pressed.connect(_on_imbue_pressed)
	vb.add_child(_imbue_button)
	Inventory.changed.connect(_refresh)
	visibility_changed.connect(_on_visibility_changed)
	_refresh()


func _apply_panel_style() -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.border_color = PANEL_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(12)
	add_theme_stylebox_override(&"panel", sb)


func _refresh() -> void:
	for i: int in range(_buttons.size()):
		var it: Item = Inventory.get_at(i)
		_style_cell(_buttons[i], it, i)
	_update_imbue_state()


func _style_cell(btn: Button, it: Item, idx: int) -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	var is_sel: bool = idx in _selected
	if it == null:
		sb.bg_color = CELL_BG
		btn.text = ""
	else:
		sb.bg_color = it.get_color() * Color(0.4, 0.4, 0.4, 1.0)
		sb.bg_color.a = 0.95
		btn.text = it.base_name.substr(0, 4)
	sb.border_color = CELL_SELECTED if is_sel else (Color(0.30, 0.28, 0.22) if it == null else it.get_color())
	sb.set_border_width_all(3 if is_sel else 2)
	sb.set_corner_radius_all(3)
	btn.add_theme_stylebox_override(&"normal", sb)
	btn.add_theme_stylebox_override(&"hover", sb)
	btn.add_theme_stylebox_override(&"pressed", sb)


func _on_cell_pressed(idx: int) -> void:
	var it: Item = Inventory.get_at(idx)
	if it == null:
		return
	if idx in _selected:
		_selected.erase(idx)
	else:
		if _selected.size() >= 3:
			return
		_selected.append(idx)
	_refresh()


func _on_cell_hover(idx: int) -> void:
	var it: Item = Inventory.get_at(idx)
	if it != null:
		Tooltip.show_for(it)


func _on_cell_unhover() -> void:
	Tooltip.hide_tip()


func _update_imbue_state() -> void:
	if _selected.size() != 3:
		_imbue_button.disabled = true
		_hint_label.text = "Pick %d of 3 items." % _selected.size()
		_hint_label.add_theme_color_override(&"font_color", HINT_WARN if _selected.size() > 0 else Color.WHITE)
		return
	var first_slot: String = ""
	for idx: int in _selected:
		var it: Item = Inventory.get_at(idx)
		if it == null:
			_imbue_button.disabled = true
			_hint_label.text = "One of the picked cells is empty."
			_hint_label.add_theme_color_override(&"font_color", HINT_WARN)
			return
		if first_slot == "":
			first_slot = it.slot
		elif it.slot != first_slot:
			_imbue_button.disabled = true
			_hint_label.text = "Mismatched slots — must all be %s." % first_slot
			_hint_label.add_theme_color_override(&"font_color", HINT_WARN)
			return
	_imbue_button.disabled = false
	_hint_label.text = "Ready. Imbue 3 %s items." % first_slot
	_hint_label.add_theme_color_override(&"font_color", HINT_OK)


func _on_imbue_pressed() -> void:
	if _selected.size() != 3:
		return
	var sacrificed: Array[Item] = []
	# Sort indices descending so removal doesn't shift later indices.
	var sorted_indices: Array[int] = _selected.duplicate()
	sorted_indices.sort()
	for idx: int in sorted_indices:
		sacrificed.append(Inventory.get_at(idx))
	var result: Item = LootRoller.imbue(sacrificed)
	if result == null:
		_hint_label.text = "Imbuement failed."
		_hint_label.add_theme_color_override(&"font_color", HINT_WARN)
		return
	for idx: int in sorted_indices:
		Inventory.remove_at(idx)
	if not Inventory.add(result):
		# Inventory full edge-case: drop on the ground at the player's feet.
		var player: Node = get_tree().get_first_node_in_group(&"player")
		if player != null and player.get_parent() != null:
			var ground_scene: PackedScene = preload("res://scenes/actors/GroundItem.tscn")
			var dropped: GroundItem = ground_scene.instantiate()
			dropped.item = result
			dropped.global_position = player.global_position
			player.get_parent().call_deferred(&"add_child", dropped)
	_selected.clear()
	_refresh()


func _on_visibility_changed() -> void:
	if not visible:
		_selected.clear()
		_refresh()
