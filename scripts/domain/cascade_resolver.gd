class_name CascadeResolver
extends RefCounted

const GemInstance = preload("res://scripts/domain/gem_instance.gd")

static func apply_gravity(board) -> Array:
	var movements = [] # Array of {from: Vector2i, to: Vector2i}
	for x in range(board.width):
		var empty_slots = 0
		for y in range(board.height - 1, -1, -1):
			if board.get_gem(x, y) == null:
				empty_slots += 1
			elif empty_slots > 0:
				var gem = board.get_gem(x, y)
				board.set_gem(x, y, null)
				board.set_gem(x, y + empty_slots, gem)
				movements.append({"from": Vector2i(x, y), "to": Vector2i(x, y + empty_slots)})
	return movements

static func refill_random(board, gem_definitions: Array[String]) -> Array:
	var new_gems = [] # Array of {pos: Vector2i, definition_id: String}
	for x in range(board.width):
		for y in range(board.height):
			if board.get_gem(x, y) == null:
				var def_id = gem_definitions[randi() % gem_definitions.size()]
				var gem = GemInstance.new(def_id)
				board.set_gem(x, y, gem)
				new_gems.append({"pos": Vector2i(x, y), "gem": gem})
	return new_gems

static func refill_from_deck(board, deck) -> Array:
	var new_gems = [] # Array of {pos: Vector2i, gem: GemInstance}
	for x in range(board.width):
		for y in range(board.height):
			if board.get_gem(x, y) == null:
				var gem = deck.draw_one()
				if gem:
					board.set_gem(x, y, gem)
					new_gems.append({"pos": Vector2i(x, y), "gem": gem})
	return new_gems
