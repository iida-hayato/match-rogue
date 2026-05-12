extends RefCounted

static func calculate_gold_reward_breakdown(stage_state: Object, target_score: int) -> Dictionary:
	var clear_bonus = 8
	var moves_bonus = stage_state.moves_remaining * 1
	var excess = max(0, stage_state.score - target_score)
	var over_score_bonus = excess / 500
	
	var coin_gem_bonus = stage_state.gold_earned
	
	var total = clear_bonus + moves_bonus + over_score_bonus + coin_gem_bonus
	
	return {
		"total": total,
		"clear_bonus": clear_bonus,
		"moves_bonus": moves_bonus,
		"over_score_bonus": over_score_bonus,
		"coin_gem_bonus": coin_gem_bonus
	}

static func remove_gem(run_state: RunState, _gem_index: int) -> bool:
	var cost = 50
	if run_state.gold >= cost:
		run_state.gold -= cost
		# logic to remove gem from deck
		return true
	return false
