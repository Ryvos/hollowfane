extends PanelContainer
class_name SettingsPanel

## SettingsPanel — Esc-toggled menu. Save/Load buttons drive SaveSystem; the
## form rows below mirror Settings autoload state. Each control writes back to
## Settings immediately on change so the UI never has a "Save & Apply" lag.

const PANEL_BG: Color = Color(0.04, 0.04, 0.06, 0.95)
const PANEL_BORDER: Color = Color(0.55, 0.45, 0.32)


func _ready() -> void:
	_apply_panel_style()
	custom_minimum_size = Vector2(440, 480)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override(&"separation", 8)
	add_child(vb)

	var title: Label = Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override(&"font_size", 20)
	vb.add_child(title)

	var save_btn: Button = Button.new()
	save_btn.text = "Save Game"
	save_btn.focus_mode = Control.FOCUS_NONE
	save_btn.pressed.connect(SaveSystem.save_game)
	vb.add_child(save_btn)

	var load_btn: Button = Button.new()
	load_btn.text = "Load Game"
	load_btn.focus_mode = Control.FOCUS_NONE
	load_btn.disabled = not SaveSystem.has_save()
	load_btn.pressed.connect(SaveSystem.load_game)
	vb.add_child(load_btn)

	vb.add_child(_section_label("Audio"))
	vb.add_child(_volume_row())

	vb.add_child(_section_label("Display"))
	vb.add_child(_fullscreen_row())

	vb.add_child(_section_label("Accessibility"))
	vb.add_child(_color_blind_row())
	vb.add_child(_font_scale_row())

	vb.add_child(_section_label("Hardcore"))
	vb.add_child(_hardcore_row())

	SaveSystem.save_completed.connect(func(_ok: bool) -> void: load_btn.disabled = not SaveSystem.has_save())
	SaveSystem.load_completed.connect(func(_ok: bool) -> void: pass)


func _apply_panel_style() -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.border_color = PANEL_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(14)
	add_theme_stylebox_override(&"panel", sb)


func _section_label(text: String) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override(&"font_size", 14)
	l.add_theme_color_override(&"font_color", Color(0.85, 0.78, 0.45))
	return l


func _volume_row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	var label: Label = Label.new()
	label.text = "Master Volume"
	label.custom_minimum_size = Vector2(150, 0)
	row.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.custom_minimum_size = Vector2(180, 0)
	slider.min_value = -40.0
	slider.max_value = 6.0
	slider.step = 1.0
	slider.value = Settings.master_volume_db
	slider.value_changed.connect(Settings.set_master_volume_db)
	row.add_child(slider)
	return row


func _fullscreen_row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	var label: Label = Label.new()
	label.text = "Fullscreen"
	label.custom_minimum_size = Vector2(150, 0)
	row.add_child(label)
	var cb: CheckBox = CheckBox.new()
	cb.button_pressed = Settings.fullscreen
	cb.toggled.connect(Settings.set_fullscreen)
	row.add_child(cb)
	return row


func _color_blind_row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	var label: Label = Label.new()
	label.text = "Color-Blind"
	label.custom_minimum_size = Vector2(150, 0)
	row.add_child(label)
	var opt: OptionButton = OptionButton.new()
	opt.add_item("Off", 0)
	opt.add_item("Deuteranopia", 1)
	opt.add_item("Protanopia", 2)
	opt.add_item("Tritanopia", 3)
	var current_idx: int = ["none", "deuteranopia", "protanopia", "tritanopia"].find(Settings.color_blind)
	opt.selected = current_idx if current_idx >= 0 else 0
	opt.item_selected.connect(_on_color_blind_changed)
	row.add_child(opt)
	return row


func _on_color_blind_changed(idx: int) -> void:
	var ids: Array[String] = ["none", "deuteranopia", "protanopia", "tritanopia"]
	if idx >= 0 and idx < ids.size():
		Settings.set_color_blind(ids[idx])


func _font_scale_row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	var label: Label = Label.new()
	label.text = "Font Scale"
	label.custom_minimum_size = Vector2(150, 0)
	row.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.custom_minimum_size = Vector2(180, 0)
	slider.min_value = 0.8
	slider.max_value = 1.5
	slider.step = 0.05
	slider.value = Settings.font_scale
	slider.value_changed.connect(Settings.set_font_scale)
	row.add_child(slider)
	return row


func _hardcore_row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	var label: Label = Label.new()
	label.text = "Hardcore Mode"
	label.custom_minimum_size = Vector2(150, 0)
	row.add_child(label)
	var cb: CheckBox = CheckBox.new()
	cb.button_pressed = Settings.hardcore
	cb.toggled.connect(Settings.set_hardcore)
	row.add_child(cb)
	var hint: Label = Label.new()
	hint.text = "Save deletes on death."
	hint.add_theme_color_override(&"font_color", Color(0.85, 0.5, 0.5))
	hint.add_theme_font_size_override(&"font_size", 12)
	row.add_child(hint)
	return row
