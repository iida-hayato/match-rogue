extends RefCounted

static func apply_gravity(board) -> Array:
	var movements = [] # Array of {from: Vector2i, to: Vector2i}
	for x in range(board.width):
		var target_y = board.height - 1
		for y in range(board.height - 1, -1, -1):
			var gem = board.get_gem(x, y)
			if gem != null:
				if y != target_y:
					board.set_gem(x, y, null)
					board.set_gem(x, target_y, gem)
					movements.append({"from": Vector2i(x, y), "to": Vector2i(x, target_y)})
				target_y -= 1
	return movements

static func refill_from_deck(board, deck, obstacle_rate: float = 0.0) -> Array:
	var GemInstance_ = load("res://scripts/domain/gem_instance.gd")
	var spawns = [] # Array of {from: Vector2i, to: Vector2i, gem: GemInstance}
	var empty_positions: Array[Vector2i] = _get_refill_order(board)
	var spawn_counts_by_column: Dictionary = {}
	for pos in empty_positions:
		var gem = null
		if randf() < obstacle_rate:
			gem = GemInstance_.new("stone")
		else:
			gem = deck.draw_one()
		
		if gem == null:
			break
		
		board.set_gem(pos.x, pos.y, gem)
		var spawn_count = int(spawn_counts_by_column.get(pos.x, 0)) + 1
		spawn_counts_by_column[pos.x] = spawn_count
		spawns.append({
			"from": Vector2i(pos.x, -spawn_count),
			"to": pos,
			"gem": gem
		})
	return spawns

static func _get_refill_order(board) -> Array[Vector2i]:
	var ordered: Array[Vector2i] = []
	for y in range(board.height - 1, -1, -1):
		var row_positions: Array[Vector2i] = []
		for x in range(board.width):
			if board.get_gem(x, y) == null:
				row_positions.append(Vector2i(x, y))
		row_positions.sort_custom(func(a: Vector2i, b: Vector2i):
			var dist_a = _center_distance(a.x, board.width)
			var dist_b = _center_distance(b.x, board.width)
			if dist_a == dist_b:
				return a.x < b.x
			return dist_a < dist_b
		)
		ordered.append_array(row_positions)
	return ordered

static func _center_distance(x: int, width: int) -> float:
	var center = (width - 1) / 2.0
	return abs(x - center)
