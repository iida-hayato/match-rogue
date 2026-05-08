class_name BoardState
extends RefCounted

var width: int = 8
var height: int = 8
var cells: Array = [] # 2D array [y][x]

func _init(w: int = 8, h: int = 8) -> void:
	width = w
	height = h
	cells.resize(height)
	for y in range(height):
		cells[y] = []
		cells[y].resize(width)
		for x in range(width):
			cells[y][x] = null

func get_gem(x: int, y: int):
	if is_within_bounds(x, y):
		return cells[y][x]
	return null

func set_gem(x: int, y: int, gem) -> void:
	if is_within_bounds(x, y):
		cells[y][x] = gem

func is_within_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

func swap_gems(x1: int, y1: int, x2: int, y2: int) -> void:
	var temp = cells[y1][x1]
	cells[y1][x1] = cells[y2][x2]
	cells[y2][x2] = temp
