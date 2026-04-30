extends Node

## QuestLog — autoload. Tracks the 3 main Act I quests for v0.6.0. Quest IDs
## are referenced from gameplay code (NPC dialogs, scene-change hooks, boss
## death) which call `complete(id)` to advance them. Autoload survives scene
## transitions so progress persists between Whitestone ↔ Catacombs.
##
## Status flow: HIDDEN → ACTIVE → COMPLETE. The first quest starts ACTIVE on
## boot ("Speak to the Smith"); subsequent quests unlock as their predecessor
## is completed (a tiny chain that proves the system without needing a full
## quest editor — that arrives with the Codex in Week 9).

enum Status { HIDDEN, ACTIVE, COMPLETE }

const QUESTS: Array[Dictionary] = [
	{
		"id": "speak_to_smith",
		"title": "Tools of the Trade",
		"summary": "Speak to the Smith in Whitestone.",
		"unlocks": "investigate_catacombs",
	},
	{
		"id": "investigate_catacombs",
		"title": "Beneath the Stones",
		"summary": "Step into the Catacombs entrance.",
		"unlocks": "slay_hollow_bishop",
	},
	{
		"id": "slay_hollow_bishop",
		"title": "The Hollow Bishop",
		"summary": "Defeat the Hollow Bishop in the depths.",
		"unlocks": "slay_worm_mother",
	},
	{
		"id": "slay_worm_mother",
		"title": "The Worm-Mother",
		"summary": "Descend into the Frostvein. End her brood.",
		"unlocks": "confront_pact_bearer",
	},
	{
		"id": "confront_pact_bearer",
		"title": "The Pact-Bearer",
		"summary": "Climb the Cinderfall Spire. End the pact.",
		"unlocks": "",
	},
]

var _status: Dictionary = {}  # id -> Status

signal quest_advanced(id: String, status: int)


func _ready() -> void:
	for q: Dictionary in QUESTS:
		_status[String(q["id"])] = Status.HIDDEN
	# Boot quest is active by default.
	_status[String(QUESTS[0]["id"])] = Status.ACTIVE


func get_status(id: String) -> int:
	return int(_status.get(id, Status.HIDDEN))


func is_active(id: String) -> bool:
	return get_status(id) == Status.ACTIVE


func is_complete(id: String) -> bool:
	return get_status(id) == Status.COMPLETE


func complete(id: String) -> void:
	if not _status.has(id):
		return
	if _status[id] == Status.COMPLETE:
		return
	_status[id] = Status.COMPLETE
	quest_advanced.emit(id, Status.COMPLETE)
	# Unlock the next quest in the chain.
	for q: Dictionary in QUESTS:
		if String(q["id"]) == id:
			var next_id: String = String(q.get("unlocks", ""))
			if next_id != "" and _status.get(next_id, Status.HIDDEN) == Status.HIDDEN:
				_status[next_id] = Status.ACTIVE
				quest_advanced.emit(next_id, Status.ACTIVE)
			break


func all_quests() -> Array[Dictionary]:
	return QUESTS
