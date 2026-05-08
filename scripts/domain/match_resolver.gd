class_name MatchResolver
extends RefCounted

static func find_matches(board) -> Array[Array]:
	var matches: Array[Array] = []

	# Horizontal matches
	for y in range(board.height):
		for x in range(board.width - 2):
			var gem = board.get_gem(x, y)
			if gem == null: continue
			
			var match_group = [Vector2i(x, y)]
			var next_x = x + 1
			while next_x < board.width:
				var next_gem = board.get_gem(next_x, y)
				if next_gem != null and next_gem.definition_id == gem.definition_id:
					match_group.append(Vector2i(next_x, y))
					next_x += 1
				else:
					break
			
			if match_group.size() >= 3:
				matches.append(match_group)
				x = next_x - 1 # Skip checked gems
	
	# Vertical matches
	for x in range(board.width):
		for y in range(board.height - 2):
			var gem = board.get_gem(x, y)
			if gem == null: continue
			
			var match_group = [Vector2i(x, y)]
			var next_y = y + 1
			while next_y < board.height:
				var next_gem = board.get_gem(x, next_y)
				if next_gem != null and next_gem.definition_id == gem.definition_id:
					match_group.append(Vector2i(x, next_y))
					next_y += 1
				else:
					break
			
			if match_group.size() >= 3:
				matches.append(match_group)
				y = next_y - 1 # Skip checked gems
				
	return matches
