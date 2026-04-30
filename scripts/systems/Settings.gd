extends Node

## Settings — autoload. Holds all persistable user-preference state. Spec §6.3
## lists Graphics / Audio / Gameplay / Accessibility / Controls; v0.11.0 ships
## the subset that's testable now (volume, fullscreen, color-blind preset,
## font-scale). Each setting applies live via `_apply_*` methods so the UI
## doesn't need a "Save & Apply" button.
##
## Color-blind: the preset doesn't yet remap every in-game color (that's a
## QA-validation pass) — for v0.11.0 it adjusts the rarity color palette
## (the most visible color-coding) via Item.RARITY_COLORS lookups.

const COLOR_BLIND_NONE: String = "none"
const COLOR_BLIND_DEUTER: String = "deuteranopia"
const COLOR_BLIND_PROTAN: String = "protanopia"
const COLOR_BLIND_TRITAN: String = "tritanopia"

var master_volume_db: float = 0.0
var fullscreen: bool = false
var color_blind: String = COLOR_BLIND_NONE
var font_scale: float = 1.0
var hardcore: bool = false

signal changed


func _ready() -> void:
	_apply_audio()
	_apply_window()


func set_master_volume_db(v: float) -> void:
	master_volume_db = clampf(v, -40.0, 6.0)
	_apply_audio()
	changed.emit()


func set_fullscreen(b: bool) -> void:
	fullscreen = b
	_apply_window()
	changed.emit()


func set_color_blind(preset: String) -> void:
	color_blind = preset
	changed.emit()


func set_font_scale(s: float) -> void:
	font_scale = clampf(s, 0.8, 1.5)
	changed.emit()


func set_hardcore(b: bool) -> void:
	hardcore = b
	changed.emit()


func _apply_audio() -> void:
	var bus: int = AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	AudioServer.set_bus_volume_db(bus, master_volume_db)


func _apply_window() -> void:
	var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func serialize() -> Dictionary:
	return {
		"master_volume_db": master_volume_db,
		"fullscreen": fullscreen,
		"color_blind": color_blind,
		"font_scale": font_scale,
		"hardcore": hardcore,
	}


func deserialize(d: Dictionary) -> void:
	master_volume_db = float(d.get("master_volume_db", 0.0))
	fullscreen = bool(d.get("fullscreen", false))
	color_blind = String(d.get("color_blind", COLOR_BLIND_NONE))
	font_scale = float(d.get("font_scale", 1.0))
	hardcore = bool(d.get("hardcore", false))
	_apply_audio()
	_apply_window()
	changed.emit()
