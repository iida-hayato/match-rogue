extends RefCounted

const MAX_DROP_CHARGES := 4

var target_score: int = 1000
var score: int = 0
var moves_remaining: int = 20
var chain_index: int = 0
var obstacle_rate: float = 0.0
var gold_earned: int = 0
var drop_charges_remaining: int = MAX_DROP_CHARGES

func is_cleared() -> bool:
	return score >= target_score

func is_game_over() -> bool:
	return moves_remaining <= 0 and drop_charges_remaining <= 0 and score < target_score
