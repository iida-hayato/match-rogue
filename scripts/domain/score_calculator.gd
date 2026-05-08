class_name ScoreCalculator
extends RefCounted

static func calculate_score(cleared_gems: Array, chain_index: int) -> Dictionary:
	var total_base_value = 0
	for gem in cleared_gems:
		# For MVP, all gems have base value 10
		total_base_value += 10
	
	var count_multiplier = 1.0 + (max(0, cleared_gems.size() - 3) * 0.5)
	var chain_multiplier = 1.0 + (chain_index * 0.2)
	
	var final_score = int(total_base_value * count_multiplier * chain_multiplier)
	
	return {
		"delta": final_score,
		"base": total_base_value,
		"count_multiplier": count_multiplier,
		"chain_multiplier": chain_multiplier
	}
