extends RefCounted

enum MatchShape {
	NONE,
	LINE_3,
	LINE_4,
	LINE_5,
	L_SHAPE,
	T_SHAPE,
	CROSS,
	BOX_4
}

static func find_matches(board, include_boxes: bool = false) -> Array[Dictionary]:
	var raw_groups = []
...
	var merged_groups = merge_groups(raw_groups)
	
	# Detect Boxes if enabled
	if include_boxes:
		var boxes = find_box_matches(board)
		# Merge boxes into groups if they overlap, or add as new groups
		for box in boxes:
			var merged_into_existing = false
			for group in merged_groups:
				if _groups_overlap(box, group):
					group.append_array(box) # _dedupe will happen in analyze_shape
					merged_into_existing = true
					break
			if not merged_into_existing:
				merged_groups.append(box)

	var results: Array[Dictionary] = []
	for group in merged_groups:
		var deduped = _dedupe_positions(group)
		results.append({
			"positions": deduped,
			"shape": analyze_shape(board, deduped)
		})
	return results

static func _dedupe_positions(group: Array) -> Array[Vector2i]:
	var deduped: Array[Vector2i] = []
	var seen = {}
	for pos in group:
		if not seen.has(pos):
			seen[pos] = true
			deduped.append(pos)
	return deduped

static func analyze_shape(board, positions: Array[Vector2i]) -> MatchShape:
	if positions.size() < 3: return MatchShape.NONE
	
	# Check for Box 4 (2x2)
	if positions.size() == 4:
		var min_x = 99; var max_x = -1
		var min_y = 99; var max_y = -1
		for p in positions:
			min_x = min(min_x, p.x); max_x = max(max_x, p.x)
			min_y = min(min_y, p.y); max_y = max(max_y, p.y)
		if (max_x - min_x) == 1 and (max_y - min_y) == 1:
			return MatchShape.BOX_4

	# Calculate spans
	var xs = {}; var ys = {}
	for p in positions:
		xs[p.x] = xs.get(p.x, 0) + 1
		ys[p.y] = ys.get(p.y, 0) + 1
	
	var max_h_run = 0; for v in xs.values(): max_h_run = max(max_h_run, v)
	var max_v_run = 0; for v in ys.values(): max_v_run = max(max_v_run, v)
	
	# Cross / T / L logic
	var multi_line = (xs.size() > 1 and ys.size() > 1)
	
	if multi_line:
		# Check for intersections
		var intersections = 0
		for x in xs:
			if xs[x] >= 3:
				for y in ys:
					if ys[y] >= 3 and Vector2i(x, y) in positions:
						intersections += 1
		
		if intersections > 0:
			# It's a complex shape
			# CROSS: center of a 5+ match
			# T-SHAPE: intersection is not at an end
			# L-SHAPE: intersection is at an end
			# For now, let's simplify: if it has 5+ gems and is multi-line, it's at least a T or Cross
			if positions.size() >= 5:
				return MatchShape.CROSS if intersections > 1 or positions.size() >= 6 else MatchShape.T_SHAPE
			return MatchShape.L_SHAPE
			
	# Straight lines
	if positions.size() >= 5: return MatchShape.LINE_5
	if positions.size() >= 4: return MatchShape.LINE_4
	
	return MatchShape.LINE_3

static func find_box_matches(board) -> Array[Array]:
	var boxes = []
	for y in range(board.height - 1):
		for x in range(board.width - 1):
			var g1 = board.get_gem(x, y)
			var g2 = board.get_gem(x+1, y)
			var g3 = board.get_gem(x, y+1)
			var g4 = board.get_gem(x+1, y+1)
			if g1 and g2 and g3 and g4:
				if g1.definition_id == g2.definition_id and \
				   g1.definition_id == g3.definition_id and \
				   g1.definition_id == g4.definition_id:
					boxes.append([Vector2i(x,y), Vector2i(x+1,y), Vector2i(x,y+1), Vector2i(x+1,y+1)])
	return boxes

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
