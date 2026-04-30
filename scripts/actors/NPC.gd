extends Area2D
class_name NPC

## NPC — clickable hub character. Shows a name plate above the body and on
## click pops a small dialog panel with the NPC's role + a one-line teaser.
## v0.6.0 only ships the four hub shells (Smith / Imbuer / Stash / Quest Board)
## as placeholders — their actual mechanics (gear sales, imbuement crafting,
## stash UI, quest acceptance) ship Weeks 7–9 alongside the systems they need.
##
## Some NPC clicks fire a quest hook (the Smith advances "Speak to the Smith");
## those are configured per instance via `quest_complete_id`.

const BG: Color = Color(0.06, 0.05, 0.08, 0.94)
const BORDER: Color = Color(0.55, 0.45, 0.32)

@export var npc_id: String = "smith"
@export var display_name: String = "Smith"
@export var role_text: String = "Coming in a later update."
@export var quest_complete_id: String = ""
@export var body_color: Color = Color(0.6, 0.4, 0.2)

var _name_label: Label = null
var _body: ColorRect = null
var _dialog: PanelContainer = null


func _ready() -> void:
	add_to_group(&"npc")
	monitoring = false
	monitorable = false
	input_pickable = true
	input_event.connect(_on_input_event)
	_build_visual()


func _build_visual() -> void:
	_body = ColorRect.new()
	_body.size = Vector2(48, 64)
	_body.position = Vector2(-24, -64)
	_body.color = body_color
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)
	_name_label = Label.new()
	_name_label.text = display_name
	_name_label.position = Vector2(-60, -90)
	_name_label.size = Vector2(120, 22)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override(&"font_size", 14)
	_name_label.add_theme_color_override(&"font_color", Color(1, 0.95, 0.8))
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)
	var collision: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(48, 64)
	collision.shape = rect
	collision.position = Vector2(0, -32)
	add_child(collision)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_open_dialog()
			get_viewport().set_input_as_handled()


func _open_dialog() -> void:
	if _dialog != null and is_instance_valid(_dialog):
		_dialog.queue_free()
		_dialog = null
		return
	_dialog = PanelContainer.new()
	_dialog.size = Vector2(280, 0)
	_dialog.position = Vector2(40, -130)
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = BG
	sb.border_color = BORDER
	sb.set_border_width_all(1)
	sb.set_content_margin_all(10)
	_dialog.add_theme_stylebox_override(&"panel", sb)
	var rt: RichTextLabel = RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.custom_minimum_size = Vector2(260, 0)
	rt.text = "[b]%s[/b]\n\n%s" % [display_name, role_text]
	_dialog.add_child(rt)
	add_child(_dialog)
	if quest_complete_id != "":
		QuestLog.complete(quest_complete_id)
