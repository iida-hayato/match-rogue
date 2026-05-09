class_name RunState
extends RefCounted

var stage_index: int = 0
var max_stages: int = 14
var master_deck: Array[GemInstance] = []
var relic_ids: Array[String] = []
var gold: int = 0
var total_gold_earned: int = 0

# Cumulative stats
var total_score: int = 0
var total_gems_cleared: int = 0
var max_chain: int = 0
var largest_clear: int = 0

var run_seed: int

func _init() -> void:
	run_seed = randi()
	seed(run_seed)

func add_relic(relic_id: String) -> void:
	if not relic_ids.has(relic_id):
		relic_ids.append(relic_id)

func get_current_stage_name() -> String:
	var world = (stage_index / 4) + 1
	var stage = (stage_index % 4) + 1
	return "%d-%d" % [world, stage]
