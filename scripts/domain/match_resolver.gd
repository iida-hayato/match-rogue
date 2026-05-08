class_name MatchResolver
extends RefCounted

static func find_matches(board) -> Array[Array]:
	var raw_groups = []

	# Horizontal matches
	for y in range(board.height):
		var x = 0
		while x < board.width:
			var gem = board.get_gem(x, y)
			if gem == null:
				x += 1
				continue
			var run = [Vector2i(x, y)]
			var scan_x = x + 1
			while scan_x < board.width:
				var next_gem = board.get_gem(scan_x, y)
				if next_gem != null and next_gem.definition_id == gem.definition_id:
					run.append(Vector2i(scan_x, y))
					scan_x += 1
				else:
					break
			if run.size() >= 3:
				raw_groups.append(run)
			x = scan_x
	
	# Vertical matches
	for x in range(board.width):
		var y = 0
		while y < board.height:
			var gem = board.get_gem(x, y)
			if gem == null:
				y += 1
				continue
			var run = [Vector2i(x, y)]
			var scan_y = y + 1
			while scan_y < board.height:
				var next_gem = board.get_gem(x, scan_y)
				if next_gem != null and next_gem.definition_id == gem.definition_id:
					run.append(Vector2i(x, scan_y))
					scan_y += 1
				else:
					break
			if run.size() >= 3:
				raw_groups.append(run)
			y = scan_y
				
	return merge_groups(raw_groups)

static func merge_groups(groups: Array) -> Array[Array]:
	if groups.is_empty():
		return []
	
	var merged: Array[Array] = []
	var remaining = groups.duplicate()
	
	while not remaining.is_empty():
		var current = remaining.pop_back()
		var changed = true
		while changed:
			changed = false
			for i in range(remaining.size() - 1, -1, -1):
				if _groups_overlap(current, remaining[i]):
					current = _merge_two_groups(current, remaining[i])
					remaining.remove_at(i)
					changed = true
		merged.append(current)
	return merged

static func _groups_overlap(a: Array, b: Array) -> bool:
	for pos_a in a:
		if pos_a in b:
			return true
	return false

static func _merge_two_groups(a: Array, b: Array) -> Array:
	var res = a.duplicate()
	for pos_b in b:
		if not pos_b in res:
			res.append(pos_b)
	return res

static func find_stone_breaks(board, cleared_positions: Array) -> Array[Vector2i]:
	var stones_to_break: Array[Vector2i] = []
	var seen_stones: Dictionary = {}
	
	for pos in cleared_positions:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0: continue
				
				var neighbor = Vector2i(pos.x + dx, pos.y + dy)
				if board.is_within_bounds(neighbor.x, neighbor.y):
					var gem = board.get_gem(neighbor.x, neighbor.y)
					if gem != null and gem.is_stone():
						if not seen_stones.has(neighbor):
							seen_stones[neighbor] = true
							stones_to_break.append(neighbor)
	
	return stones_to_break

static func find_effect_positions(board, cleared_positions: Array) -> Array[Vector2i]:
	var effect_positions: Array[Vector2i] = []
	var seen: Dictionary = {}
	var queue = cleared_positions.duplicate()
	var processed_special_gems: Dictionary = {}
	
	while not queue.is_empty():
		var pos = queue.pop_back()
		var gem = board.get_gem(pos.x, pos.y)
		if gem == null: continue
		
		# Check all coats for effects
		for effect in gem.coat_ids:
			var key = "%d,%d:%s" % [pos.x, pos.y, effect]
			if processed_special_gems.has(key): continue
			processed_special_gems[key] = true
			
			var pattern = []
			match effect:
				"rocket_v":
					for y in range(board.height): pattern.append(Vector2i(pos.x, y))
				"rocket_h":
					for x in range(board.width): pattern.append(Vector2i(x, pos.y))
				"bomb":
					for dy in range(-1, 2):
						for dx in range(-1, 2):
							pattern.append(Vector2i(pos.x + dx, pos.y + dy))
				"beam":
					for i in range(-max(board.width, board.height), max(board.width, board.height)):
						pattern.append(Vector2i(pos.x + i, pos.y + i))
						pattern.append(Vector2i(pos.x + i, pos.y - i))
			
			for p in pattern:
				if board.is_within_bounds(p.x, p.y) and not seen.has(p):
					seen[p] = true
					effect_positions.append(p)
					# If we hit another special gem, add it to queue to chain effects
					var next_gem = board.get_gem(p.x, p.y)
					if next_gem and next_gem.coat_ids.size() > 0:
						queue.append(p)
						
	return effect_positions
