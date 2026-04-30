extends Node

## Hotbar — autoload. 4 slots; each holds a skill_id String or "" for empty.
## The Player listens for `skill_activated(slot)` and resolves the skill.
##
## Default state: slot 0 is auto-bound to `basic_attack` so the v0.4.0 spike
## works out of the box without forcing the player into the bind UI on first
## boot. The bind-skill flow rebinds via `set_slot(slot, skill_id)` from the
## Character panel popup.

const SLOTS: int = 4

var _slots: PackedStringArray = PackedStringArray()

signal changed
signal skill_activated(slot: int, skill_id: String)


func _ready() -> void:
	_slots.resize(SLOTS)
	for i: int in range(SLOTS):
		_slots[i] = ""
	_slots[0] = "basic_attack"
	changed.emit()


func set_slot(slot: int, skill_id: String) -> void:
	if slot < 0 or slot >= SLOTS:
		return
	if skill_id != "" and not SkillBook.has_skill(skill_id):
		return
	_slots[slot] = skill_id
	changed.emit()


func clear_slot(slot: int) -> void:
	set_slot(slot, "")


func get_slot(slot: int) -> String:
	if slot < 0 or slot >= SLOTS:
		return ""
	return _slots[slot]


func activate(slot: int) -> void:
	var sid: String = get_slot(slot)
	if sid == "":
		return
	skill_activated.emit(slot, sid)
