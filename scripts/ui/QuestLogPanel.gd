extends PanelContainer
class_name QuestLogPanel

## QuestLogPanel — toggleable list of every known quest with its status. Uses
## QuestLog as the single source of truth and refreshes on `quest_advanced`,
## so a quest auto-updates the moment the gameplay event fires (e.g. the
## moment you click the Smith, "Tools of the Trade" flips to ✓).

const PANEL_BG: Color = Color(0.04, 0.04, 0.06, 0.95)
const PANEL_BORDER: Color = Color(0.45, 0.4, 0.32)
const COLOR_HIDDEN: String = "#555555"
const COLOR_ACTIVE: String = "#ffd97a"
const COLOR_COMPLETE: String = "#7aff8a"

var _label: RichTextLabel = null


func _ready() -> void:
	_apply_panel_style()
	custom_minimum_size = Vector2(360, 280)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override(&"separation", 6)
	add_child(vb)
	var title: Label = Label.new()
	title.text = "Quests"
	title.add_theme_font_size_override(&"font_size", 18)
	vb.add_child(title)
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.custom_minimum_size = Vector2(330, 250)
	vb.add_child(_label)
	QuestLog.quest_advanced.connect(_on_quest_advanced)
	_refresh()


func _apply_panel_style() -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.border_color = PANEL_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(12)
	add_theme_stylebox_override(&"panel", sb)


func _on_quest_advanced(_id: String, _status: int) -> void:
	_refresh()


func _refresh() -> void:
	if _label == null:
		return
	var lines: PackedStringArray = []
	for q: Dictionary in QuestLog.all_quests():
		var qid: String = String(q["id"])
		var status: int = QuestLog.get_status(qid)
		var color: String = COLOR_HIDDEN
		var prefix: String = "•"
		if status == QuestLog.Status.ACTIVE:
			color = COLOR_ACTIVE
			prefix = "▶"
		elif status == QuestLog.Status.COMPLETE:
			color = COLOR_COMPLETE
			prefix = "✓"
		var title: String = String(q.get("title", qid))
		var summary: String = String(q.get("summary", ""))
		if status == QuestLog.Status.HIDDEN:
			lines.append("[color=%s]%s ???[/color]" % [color, prefix])
		else:
			lines.append("[color=%s]%s [b]%s[/b][/color]" % [color, prefix, title])
			lines.append("[color=#bbbbbb]    %s[/color]" % summary)
		lines.append("")
	_label.text = "\n".join(lines)
