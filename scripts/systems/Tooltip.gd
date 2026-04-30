extends CanvasLayer

## Tooltip — autoload. A single floating panel that follows the cursor and
## displays the current hovered Item, with side-by-side compare to whatever is
## already in that slot. Implemented as a CanvasLayer at high `layer` so it
## always renders above gameplay regardless of y-sort.
##
## Why one global panel rather than a tooltip-per-item: hovers fire fast and
## frequently in ARPGs (loot piles, ground items, eventually inventory grid),
## and reusing one Control + RichTextLabel avoids GC churn from create/free
## cycles each hover. The hovered item just calls `show_for(item)` /
## `hide_tip()`.

const PANEL_OFFSET: Vector2 = Vector2(20, 20)
const TOOLTIP_LAYER: int = 100
const PANEL_BG: Color = Color(0.05, 0.05, 0.08, 0.92)
const PANEL_BORDER: Color = Color(0.45, 0.45, 0.55)
const COLOR_GAIN: String = "#66ff66"
const COLOR_LOSS: String = "#ff6666"
const COLOR_NEUTRAL: String = "#bbbbbb"
const COLOR_SUBHEAD: String = "#999999"
const COLOR_AFFIX: String = "#bbbbff"

var _panel: PanelContainer = null
var _label: RichTextLabel = null


func _ready() -> void:
	layer = TOOLTIP_LAYER
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.border_color = PANEL_BORDER
	sb.set_border_width_all(1)
	sb.set_content_margin_all(8)
	_panel.add_theme_stylebox_override(&"panel", sb)
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.custom_minimum_size = Vector2(280, 0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_label)
	add_child(_panel)


func _process(_delta: float) -> void:
	if not _panel.visible:
		return
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var mp: Vector2 = vp.get_mouse_position()
	var screen: Vector2 = vp.get_visible_rect().size
	var pos: Vector2 = mp + PANEL_OFFSET
	var size: Vector2 = _panel.size
	if pos.x + size.x > screen.x:
		pos.x = mp.x - size.x - PANEL_OFFSET.x
	if pos.y + size.y > screen.y:
		pos.y = screen.y - size.y - 4
	pos.x = maxf(0.0, pos.x)
	pos.y = maxf(0.0, pos.y)
	_panel.global_position = pos


func show_for(it: Item) -> void:
	if it == null:
		hide_tip()
		return
	var equipped: Item = PlayerStats.get_equipped(it.slot)
	_label.text = _build_text(it, equipped)
	_panel.visible = true


func hide_tip() -> void:
	_panel.visible = false


func _color_hex(c: Color) -> String:
	return "#%02x%02x%02x" % [int(c.r * 255), int(c.g * 255), int(c.b * 255)]


func _build_text(it: Item, equipped: Item) -> String:
	var hex: String = _color_hex(it.get_color())
	var lines: PackedStringArray = []
	lines.append("[color=%s][b]%s[/b][/color]" % [hex, it.get_display_name()])
	lines.append("[color=%s][i]%s[/i][/color]" % [hex, it.get_rarity_name()])
	lines.append("[color=%s]Item Level %d  ·  %s[/color]" % [COLOR_SUBHEAD, it.item_level, it.slot.capitalize()])
	lines.append("")
	lines.append("Damage: [b]%d[/b]" % it.get_total_damage())
	var hp_bonus: int = it.get_stat_total("max_hp")
	if hp_bonus > 0:
		lines.append("Max HP: [b]+%d[/b]" % hp_bonus)
	var affixes: Array[Dictionary] = it.get_all_affixes()
	if not affixes.is_empty():
		lines.append("")
		for a: Dictionary in affixes:
			var stat_label: String = String(a.get("stat", "")).replace("_", " ")
			lines.append("[color=%s]+%d %s[/color]" % [COLOR_AFFIX, int(a.get("value", 0)), stat_label])
	if equipped != null and equipped != it:
		lines.append("")
		lines.append("[color=%s]— vs equipped: %s —[/color]" % [COLOR_SUBHEAD, equipped.get_display_name()])
		lines.append(_diff_line("Damage", it.get_total_damage() - equipped.get_total_damage()))
		lines.append(_diff_line("Max HP", it.get_stat_total("max_hp") - equipped.get_stat_total("max_hp")))
	return "\n".join(lines)


func _diff_line(label: String, diff: int) -> String:
	if diff > 0:
		return "[color=%s]%s: +%d[/color]" % [COLOR_GAIN, label, diff]
	if diff < 0:
		return "[color=%s]%s: %d[/color]" % [COLOR_LOSS, label, diff]
	return "[color=%s]%s: 0[/color]" % [COLOR_NEUTRAL, label]
