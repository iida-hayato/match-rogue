class_name CascadeResolver
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
	var spawns = [] # Array of {from: Vector2i, to: Vector2i, gem: GemInstance}
	for x in range(board.width):
		var empty_count = 0
		for y in range(board.height - 1, -1, -1):
			if board.get_gem(x, y) == null:
				empty_count += 1
		
		var current_empty = empty_count
		for y in range(board.height - 1, -1, -1):
			if board.get_gem(x, y) == null:
				var gem = null
				if randf() < obstacle_rate:
					gem = GemInstance.new("stone")
				else:
					gem = deck.draw_one()
				
				if gem:
					board.set_gem(x, y, gem)
					var from_y = -current_empty
					spawns.append({"from": Vector2i(x, from_y), "to": Vector2i(x, y), "gem": gem})
					current_empty -= 1
	return spawns
