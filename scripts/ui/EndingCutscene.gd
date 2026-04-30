extends ColorRect
class_name EndingCutscene

## EndingCutscene — full-screen overlay shown when the Pact-Bearer falls.
## Auto-shows on `QuestLog.quest_advanced("confront_pact_bearer", COMPLETE)`.
## Click anywhere or press any key to dismiss.
##
## v0.9.0 ships text-only with rarity-flavored typography. The full per-class
## ending variants (Spec §10 Week 9 "ending cutscene") + voice-over land in
## v1.1; this one is the same prose for any class so the campaign has a true
## end-state.

const BG: Color = Color(0.03, 0.02, 0.05, 0.94)
const TITLE_COLOR: String = "#ffd97a"
const BODY_COLOR: String = "#dddddd"
const HINT_COLOR: String = "#888888"

const ENDING_TEXT: String = """[center][color=%s][b]The pact, undone.[/b][/color]

[color=%s]The Pact-Bearer falls. The hollow chord that bound the kingdom in its long bargain unspools, ringing once, then silent. Whatever was kept by the pact is loosed; whatever was paid is owed.

You walk back through Whitestone in a quieter air. The Smith does not lift his head. The Imbuer does not greet you. Only the Stash speaks, in a voice that is not quite hers — *what is yours, take. What is the kingdom's, leave with us.*

The Echo opens. You step toward it.[/color]

[color=%s]— Press any key to continue.[/color][/center]"""

var _label: RichTextLabel = null


func _ready() -> void:
	color = BG
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.custom_minimum_size = Vector2(720, 360)
	_label.position = Vector2(-360, -180)
	_label.text = ENDING_TEXT % [TITLE_COLOR, BODY_COLOR, HINT_COLOR]
	add_child(_label)
	visible = false
	QuestLog.quest_advanced.connect(_on_quest_advanced)


func _on_quest_advanced(id: String, status: int) -> void:
	if id == "confront_pact_bearer" and status == QuestLog.Status.COMPLETE:
		# Defer to the next idle frame so the boss death animation + drop have
		# a beat to land before the screen takes over.
		await get_tree().create_timer(1.0).timeout
		visible = true


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var dismiss: bool = false
	if event is InputEventKey and event.pressed and not event.echo:
		dismiss = true
	elif event is InputEventMouseButton and event.pressed:
		dismiss = true
	if dismiss:
		visible = false
		get_viewport().set_input_as_handled()
