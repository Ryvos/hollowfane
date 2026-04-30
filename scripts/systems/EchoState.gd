extends Node

## EchoState — autoload. Tracks the current Echo tier (spec §4.7 endgame).
## Tier 0 is "no Echo run yet"; tier 1 is your first run; using a sigil bumps
## the tier by 1. Higher tier → tougher mobs, better drops, eventually Pinnacle
## boss spawns. Survives scene transitions.
##
## Persisting `max_tier_reached` lets the future save system show the player's
## record and lets the leaderboard stat be derived without re-walking every
## save file.

const TIER_HP_SCALE: float = 0.30  # +30% HP per tier
const TIER_DMG_SCALE: float = 0.20  # +20% damage per tier
const TIER_MAGIC_FIND: float = 0.15  # +0.15 mf per tier
const PINNACLE_INTERVAL: int = 3  # tier-multiples spawn the Pinnacle

var current_tier: int = 0
var max_tier_reached: int = 0

signal tier_changed(new_tier: int)


func start_first_run() -> void:
	if current_tier == 0:
		current_tier = 1
		_record_tier()


func bump_tier(amount: int = 1) -> void:
	current_tier += maxi(1, amount)
	_record_tier()


func reset() -> void:
	current_tier = 0
	tier_changed.emit(current_tier)


func is_pinnacle_tier() -> bool:
	return current_tier > 0 and (current_tier % PINNACLE_INTERVAL) == 0


func tier_hp_multiplier() -> float:
	return 1.0 + maxi(0, current_tier - 1) * TIER_HP_SCALE


func tier_dmg_multiplier() -> float:
	return 1.0 + maxi(0, current_tier - 1) * TIER_DMG_SCALE


func tier_magic_find() -> float:
	return maxi(0, current_tier - 1) * TIER_MAGIC_FIND


func _record_tier() -> void:
	if current_tier > max_tier_reached:
		max_tier_reached = current_tier
	tier_changed.emit(current_tier)
