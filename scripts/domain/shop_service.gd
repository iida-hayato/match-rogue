class_name ShopService
extends RefCounted

static func calculate_gold_reward(stage_score: int, target_score: int) -> int:
	# Basic reward: 10 + 10% of excess score
	var excess = max(0, stage_score - target_score)
	return 10 + (excess / 100)

static func remove_gem(run_state: RunState, _gem_index: int) -> bool:
	var cost = 50
	if run_state.gold >= cost:
		run_state.gold -= cost
		# logic to remove gem from deck
		return true
	return false
