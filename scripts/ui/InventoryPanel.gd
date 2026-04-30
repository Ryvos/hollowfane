extends PanelContainer
class_name InventoryPanel

## InventoryPanel — 10×4 grid of cell buttons. Click a cell with an item to
## equip it (the previously equipped item bounces back into the inventory).
## Cells without an item are unresponsive.
##
## Drag-and-drop is intentionally deferred. The bind-skill flow already has a
## click-driven UX; making inventory the same keeps the codebase coherent and
## leaves drag-drop as a single Week 8 polish pass for crafting + sockets,
## where mis-clicks have higher cost.

const CELL_SIZE: Vector2 = Vector2(48, 48)
const CELL_BG: Color = Color(0.08, 0.08, 0.10, 0.92)
const CELL_BG_FILLED: Color = Color(0.12, 0.12, 0.16, 0.95)
const CELL_BORDER: Color = Color(0.30, 0.28, 0.22)
const PANEL_BG: Color = Color(0.04, 0.04, 0.06, 0.95)
const PANEL_BORDER: Color = Color(0.45, 0.4, 0.32)

var _grid: GridContainer = null
var _buttons: Array[Button] = []


func _ready() -> void:
	_apply_panel_style()
	custom_minimum_size = Vector2(540, 240)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override(&"separation", 6)
	add_child(vb)
	var title: Label = Label.new()
	title.text = "Inventory"
	title.add_theme_font_size_override(&"font_size", 18)
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
	Inventory.changed.connect(_refresh)
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
		_style_cell(_buttons[i], it)


func _style_cell(btn: Button, it: Item) -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	if it == null:
		sb.bg_color = CELL_BG
		btn.text = ""
	else:
		sb.bg_color = it.get_color() * Color(0.4, 0.4, 0.4, 1.0) + Color(0.05, 0.05, 0.05, 0.0)
		sb.bg_color.a = 0.95
		btn.text = it.base_name.substr(0, 4)
	sb.border_color = CELL_BORDER if it == null else it.get_color()
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	btn.add_theme_stylebox_override(&"normal", sb)
	btn.add_theme_stylebox_override(&"hover", sb)
	btn.add_theme_stylebox_override(&"pressed", sb)
	btn.add_theme_color_override(&"font_color", Color.WHITE if it != null else Color(1, 1, 1, 0))


func _on_cell_pressed(idx: int) -> void:
	var it: Item = Inventory.get_at(idx)
	if it == null:
		return
	# Gems can't be "equipped" from inventory click — they socket into items.
	# The socket-install UI lands Week 9; until then a gem click is a no-op.
	if it.slot == "gem":
		return
	# Equip: take it out, push prev back into the same slot.
	Inventory.remove_at(idx)
	var prev: Item = PlayerStats.equip(it)
	if prev != null:
		Inventory.add(prev)
	Tooltip.hide_tip()


func _on_cell_hover(idx: int) -> void:
	var it: Item = Inventory.get_at(idx)
	if it != null:
		Tooltip.show_for(it)


func _on_cell_unhover() -> void:
	Tooltip.hide_tip()
