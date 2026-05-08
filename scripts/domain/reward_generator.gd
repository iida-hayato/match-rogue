class_name RewardGenerator
extends RefCounted

static func generate_rewards(_stage_index: int) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	# For MVP, just hardcode some rewards
	rewards.append({"id": "gold_50", "display_name": "50 Gold", "type": "gold", "value": 50})
	rewards.append({"id": "upgrade_red", "display_name": "Red Gem +5", "type": "upgrade", "gem_id": "red", "value": 5})
	rewards.append({"id": "add_bomb", "display_name": "Add Bomb Gem", "type": "special_gem", "effect": "bomb"})
	return rewards
