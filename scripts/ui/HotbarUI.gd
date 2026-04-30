extends HBoxContainer
class_name HotbarUI

## HotbarUI — 4 slot buttons centered above the orbs. Click a slot to open the
## bind picker (a native `PopupMenu` listing every known skill + Clear). Press
## 1/2/3/4 to fire the bound skill — that key handling lives in the Player so
## skill activation has access to world state (cursor pos, nearby enemies).

const SLOT_SIZE: Vector2 = Vector2(56, 56)
const SLOT_BG: Color = Color(0.10, 0.10, 0.13, 0.92)
const SLOT_BORDER: Color = Color(0.45, 0.4, 0.32)
const SLOT_BORDER_BOUND: Color = Color(0.95, 0.78, 0.45)
const KEY_LABELS: Array[String] = ["1", "2", "3", "4"]

var _buttons: Array[Button] = []
var _picker: PopupMenu = null
var _picker_target_slot: int = -1
var _picker_skill_ids: Array[String] = []


func _ready() -> void:
	add_theme_constant_override(&"separation", 8)
	mouse_filter = Control.MOUSE_FILTER_PASS
	for i: int in range(Hotbar.SLOTS):
		var b: Button = Button.new()
		b.custom_minimum_size = SLOT_SIZE
		b.toggle_mode = false
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_open_picker.bind(i))
		_apply_slot_style(b, false)
		add_child(b)
		_buttons.append(b)
	_picker = PopupMenu.new()
	_picker.id_pressed.connect(_on_picker_id_pressed)
	add_child(_picker)
	Hotbar.changed.connect(_refresh)
	_refresh()


func _apply_slot_style(btn: Button, bound: bool) -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = SLOT_BG
	sb.border_color = SLOT_BORDER_BOUND if bound else SLOT_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(4)
	btn.add_theme_stylebox_override(&"normal", sb)
	btn.add_theme_stylebox_override(&"hover", sb)
	btn.add_theme_stylebox_override(&"pressed", sb)


func _refresh() -> void:
	for i: int in range(_buttons.size()):
		var sid: String = Hotbar.get_slot(i)
		var bound: bool = sid != ""
		_apply_slot_style(_buttons[i], bound)
		if bound:
			var meta: Dictionary = SkillBook.get_skill(sid)
			var name: String = String(meta.get("name", sid))
			_buttons[i].text = "%s\n[%s]" % [KEY_LABELS[i], name]
		else:
			_buttons[i].text = "%s\n—" % KEY_LABELS[i]


func _open_picker(slot: int) -> void:
	_picker_target_slot = slot
	_picker.clear()
	_picker_skill_ids.clear()
	var ids: Array[String] = SkillBook.get_all_ids()
	for i: int in range(ids.size()):
		var sid: String = ids[i]
		var meta: Dictionary = SkillBook.get_skill(sid)
		_picker.add_item(String(meta.get("name", sid)), i)
		_picker_skill_ids.append(sid)
	_picker.add_separator()
	_picker.add_item("Clear", 9999)
	var btn_pos: Vector2 = _buttons[slot].global_position
	_picker.position = Vector2i(int(btn_pos.x), int(btn_pos.y - _picker.size.y - 8))
	_picker.popup()


func _on_picker_id_pressed(id: int) -> void:
	if _picker_target_slot < 0:
		return
	if id == 9999:
		Hotbar.clear_slot(_picker_target_slot)
	else:
		if id >= 0 and id < _picker_skill_ids.size():
			Hotbar.set_slot(_picker_target_slot, _picker_skill_ids[id])
	_picker_target_slot = -1
