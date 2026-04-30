extends Node

## SkillBook — autoload. The catalog of every skill the player can know.
##
## v0.4.0 ships exactly one skill (`basic_attack`) so the bind-skill flow has
## something to bind. The 3-class skill trees per spec §4.2 land in Weeks
## 6–9 alongside their classes. Adding a skill = adding one entry to SKILLS.
##
## Each skill is a Dictionary so it can be JSON-loaded later (e.g. from
## `data/skills.json`) without changing the consumers.

const SKILLS: Dictionary = {
	"basic_attack": {
		"id": "basic_attack",
		"name": "Basic Strike",
		"icon_color": Color(0.85, 0.7, 0.4),
		"description": "Strike the nearest enemy in melee range.",
	},
}


func get_all_ids() -> Array[String]:
	var out: Array[String] = []
	for k: String in SKILLS.keys():
		out.append(k)
	return out


func get_skill(skill_id: String) -> Dictionary:
	return SKILLS.get(skill_id, {})


func has_skill(skill_id: String) -> bool:
	return SKILLS.has(skill_id)
