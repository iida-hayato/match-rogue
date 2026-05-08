class_name ScoreCalculator
extends RefCounted

static func calculate_score(cleared_gems: Array, chain_index: int, relic_ids: Array[String] = []) -> Dictionary:
	var total_base_value = 0
	var matching_gem_count = 0
	for gem in cleared_gems:
		if gem.is_stone():
			continue
		
		# For MVP, all gems have base value 10
		total_base_value += 10
		matching_gem_count += 1
	
	var count_mult_step = 0.5
	if relic_ids.has("relic_mining") and matching_gem_count >= 6:
		count_mult_step += 0.3 # Large Excavation Emblem
		
	var count_multiplier = 1.0 + (max(0, matching_gem_count - 3) * count_mult_step)
	
	var chain_mult_step = 0.2
	if relic_ids.has("relic_chain"):
		chain_mult_step += 0.05 # Chain Gear
		
	var chain_multiplier = 1.0 + (chain_index * chain_mult_step)
	
	var final_score = int(total_base_value * count_multiplier * chain_multiplier)
	
	return {
		"delta": final_score,
		"base": total_base_value,
		"count_multiplier": count_multiplier,
		"chain_multiplier": chain_multiplier
	}
