extends Node

## Inventory — autoload. 10×4 backpack of Item refs. Cells are 1×1 for v0.4.0;
## the cell_w/cell_h fields on Item are already present so multi-cell layout
## (Week 8) doesn't need a save-format migration. Items are stored in a flat
## Array sized GRID_W * GRID_H, indexed `y * GRID_W + x`.

const GRID_W: int = 10
const GRID_H: int = 4
const TOTAL_CELLS: int = GRID_W * GRID_H

var _cells: Array[Item] = []

signal changed
signal pickup_failed(reason: String)


func _ready() -> void:
	_cells.resize(TOTAL_CELLS)
	for i: int in range(TOTAL_CELLS):
		_cells[i] = null


func add(item: Item) -> bool:
	if item == null:
		return false
	for i: int in range(TOTAL_CELLS):
		if _cells[i] == null:
			_cells[i] = item
			changed.emit()
			return true
	pickup_failed.emit("Inventory full")
	return false


func get_at(idx: int) -> Item:
	if idx < 0 or idx >= TOTAL_CELLS:
		return null
	return _cells[idx]


func remove_at(idx: int) -> Item:
	if idx < 0 or idx >= TOTAL_CELLS:
		return null
	var it: Item = _cells[idx]
	_cells[idx] = null
	if it != null:
		changed.emit()
	return it


func size() -> int:
	return TOTAL_CELLS


func free_count() -> int:
	var n: int = 0
	for it: Item in _cells:
		if it == null:
			n += 1
	return n


func is_full() -> bool:
	return free_count() == 0
