extends RefCounted

static func calculate_score(cleared_gems: Array, chain_index: int, relic_ids: Array[String] = []) -> Dictionary:
	var total_base_value = 0
	var matching_gem_count = 0
	for gem in cleared_gems:
		if gem.is_stone():
			continue
		
		total_base_value += 5 + int(gem.value_bonus)
		matching_gem_count += 1
	
	var count_multiplier = _get_clear_count_multiplier(matching_gem_count)
	if relic_ids.has("relic_mining") and matching_gem_count >= 6:
		count_multiplier += 0.3 # Large Excavation Emblem
	
	var chain_multiplier = _get_chain_multiplier(chain_index)
	if relic_ids.has("relic_chain"):
		chain_multiplier += chain_index * 0.05 # Chain Gear
	
	var final_score = int(total_base_value * count_multiplier * chain_multiplier)
	
	return {
		"delta": final_score,
		"base": total_base_value,
		"count_multiplier": count_multiplier,
		"chain_multiplier": chain_multiplier
	}

static func _get_clear_count_multiplier(clear_count: int) -> float:
	match clear_count:
		0, 1, 2, 3:
			return 1.0
		4:
			return 1.10
		5:
			return 1.25
		6:
			return 1.45
		7:
			return 1.70
		8:
			return 2.0
		_:
			return 2.0 + (max(0, clear_count - 8) * 0.10)

static func _get_chain_multiplier(chain_index: int) -> float:
	match chain_index:
		0:
			return 1.0
		1:
			return 1.10
		2:
			return 1.20
		3:
			return 1.35
		4:
			return 1.50
		_:
			return 1.50 + (max(0, chain_index - 4) * 0.15)
