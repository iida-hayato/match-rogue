class_name RunState
extends RefCounted

const DeckState = preload("res://scripts/domain/deck_state.gd")

var stage_index: int = 0
var max_stages: int = 14
var deck: DeckState
var gold: int = 0
var total_gold_earned: int = 0
var run_seed: int

func _init() -> void:
	run_seed = randi()
	seed(run_seed)

func get_current_stage_name() -> String:
	var world = (stage_index / 4) + 1
	var stage = (stage_index % 4) + 1
	return "%d-%d" % [world, stage]
