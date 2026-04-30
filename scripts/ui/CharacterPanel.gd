extends PanelContainer
class_name CharacterPanel

## CharacterPanel — paper-doll showing all 10 equipment slots arranged in the
## classic D2 silhouette + a stat readout block. Click a paper-doll slot to
## unequip back into the inventory; if the inventory is full, the unequip is
## refused (and the toast/error path lands when the toast system arrives).
##
## Slots are positioned manually for the silhouette layout rather than a grid,
## because anatomically the slots aren't on a regular grid (rings flank the
## body, weapon and off-hand bracket below). The positions are tuned to a
## 240×320 panel; the full-fidelity character art ships with class portraits
## in Weeks 7–10.

const PANEL_BG: Color = Color(0.04, 0.04, 0.06, 0.95)
const PANEL_BORDER: Color = Color(0.45, 0.4, 0.32)
const SLOT_SIZE: Vector2 = Vector2(56, 56)
const SLOT_BG_EMPTY: Color = Color(0.08, 0.08, 0.10, 0.92)
const SLOT_BG_FILLED: Color = Color(0.16, 0.16, 0.20, 0.95)
const SLOT_BORDER: Color = Color(0.30, 0.28, 0.22)

# Slot id → (label, position relative to silhouette top-left).
const SLOT_LAYOUT: Dictionary = {
	"head":     {"label": "Head",     "pos": Vector2(120, 8)},
	"amulet":   {"label": "Amulet",   "pos": Vector2(192, 8)},
	"chest":    {"label": "Chest",    "pos": Vector2(120, 72)},
	"weapon":   {"label": "Weapon",   "pos": Vector2(48, 72)},
	"off_hand": {"label": "Off-Hand", "pos": Vector2(192, 72)},
	"gloves":   {"label": "Gloves",   "pos": Vector2(48, 136)},
	"belt":     {"label": "Belt",     "pos": Vector2(120, 136)},
	"ring_1":   {"label": "Ring",     "pos": Vector2(192, 136)},
	"ring_2":   {"label": "Ring",     "pos": Vector2(48, 200)},
	"boots":    {"label": "Boots",    "pos": Vector2(120, 200)},
}

var _slot_buttons: Dictionary = {}  # slot_key -> Button
var _stats_label: RichTextLabel = null


func _ready() -> void:
	_apply_panel_style()
	custom_minimum_size = Vector2(540, 320)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var hb: HBoxContainer = HBoxContainer.new()
	hb.add_theme_constant_override(&"separation", 16)
	add_child(hb)
	var paper_doll: Control = Control.new()
	paper_doll.custom_minimum_size = Vector2(280, 280)
	hb.add_child(paper_doll)
	for slot_key: String in SLOT_LAYOUT.keys():
		var entry: Dictionary = SLOT_LAYOUT[slot_key]
		var b: Button = Button.new()
		b.custom_minimum_size = SLOT_SIZE
		b.size = SLOT_SIZE
		b.position = entry["pos"]
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_on_slot_pressed.bind(slot_key))
		b.mouse_entered.connect(_on_slot_hover.bind(slot_key))
		b.mouse_exited.connect(_on_slot_unhover)
		paper_doll.add_child(b)
		_slot_buttons[slot_key] = b
	var stats_box: VBoxContainer = VBoxContainer.new()
	stats_box.custom_minimum_size = Vector2(220, 280)
	hb.add_child(stats_box)
	var title: Label = Label.new()
	title.text = "Character"
	title.add_theme_font_size_override(&"font_size", 18)
	stats_box.add_child(title)
	_stats_label = RichTextLabel.new()
	_stats_label.bbcode_enabled = true
	_stats_label.fit_content = true
	_stats_label.scroll_active = false
	_stats_label.custom_minimum_size = Vector2(220, 250)
	stats_box.add_child(_stats_label)
	PlayerStats.stats_changed.connect(_refresh)
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
	for slot_key: String in _slot_buttons.keys():
		var btn: Button = _slot_buttons[slot_key]
		var it: Item = PlayerStats.get_equipped(slot_key)
		_style_slot(btn, slot_key, it)
	if _stats_label != null:
		_stats_label.text = _build_stats_text()


func _style_slot(btn: Button, slot_key: String, it: Item) -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	if it == null:
		sb.bg_color = SLOT_BG_EMPTY
		sb.border_color = SLOT_BORDER
		btn.text = SLOT_LAYOUT[slot_key]["label"]
		btn.add_theme_color_override(&"font_color", Color(0.55, 0.55, 0.6))
	else:
		sb.bg_color = SLOT_BG_FILLED
		sb.border_color = it.get_color()
		btn.text = it.base_name.substr(0, 5)
		btn.add_theme_color_override(&"font_color", Color.WHITE)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	btn.add_theme_stylebox_override(&"normal", sb)
	btn.add_theme_stylebox_override(&"hover", sb)
	btn.add_theme_stylebox_override(&"pressed", sb)


func _build_stats_text() -> String:
	var lines: PackedStringArray = []
	lines.append("[b]Stats[/b]")
	lines.append("Damage: [b]%d[/b]" % PlayerStats.get_attack_damage())
	lines.append("Max HP: [b]%d[/b]" % PlayerStats.get_max_hp())
	lines.append("")
	var equipped_count: int = 0
	for slot_key: String in _slot_buttons.keys():
		if PlayerStats.get_equipped(slot_key) != null:
			equipped_count += 1
	lines.append("[color=#999999]Equipped: %d / 10[/color]" % equipped_count)
	lines.append("[color=#999999]Inv free: %d / %d[/color]" % [Inventory.free_count(), Inventory.TOTAL_CELLS])
	return "\n".join(lines)


func _on_slot_pressed(slot_key: String) -> void:
	var it: Item = PlayerStats.get_equipped(slot_key)
	if it == null:
		return
	if Inventory.is_full():
		return
	PlayerStats.unequip(slot_key)
	Inventory.add(it)
	Tooltip.hide_tip()


func _on_slot_hover(slot_key: String) -> void:
	var it: Item = PlayerStats.get_equipped(slot_key)
	if it != null:
		Tooltip.show_for(it)


func _on_slot_unhover() -> void:
	Tooltip.hide_tip()
