extends RefCounted

const GemInstance_ = preload("res://scripts/domain/gem_instance.gd")
const BASE_BOARD_WIDTH := 8
const BASE_BOARD_HEIGHT := 8
const MAX_BOARD_MULTIPLIER := 2

var stage_index: int = 0
var max_stages: int = 14
var master_deck: Array = [] # Array[GemInstance_]
var relic_ids: Array[String] = []
var gold: int = 0
var total_gold_earned: int = 0

# Cumulative stats
var total_score: int = 0
var total_gems_cleared: int = 0
var max_chain: int = 0
var largest_clear: int = 0
var board_width: int = BASE_BOARD_WIDTH
var board_height: int = BASE_BOARD_HEIGHT

var is_endless: bool = false
var run_seed: int

func _init() -> void:
	run_seed = randi()
	seed(run_seed)

func add_relic(relic_id: String) -> void:
	if not relic_ids.has(relic_id):
		relic_ids.append(relic_id)

func get_base_board_width() -> int:
	return BASE_BOARD_WIDTH

func get_base_board_height() -> int:
	return BASE_BOARD_HEIGHT

func get_max_board_width() -> int:
	return BASE_BOARD_WIDTH * MAX_BOARD_MULTIPLIER

func get_max_board_height() -> int:
	return BASE_BOARD_HEIGHT * MAX_BOARD_MULTIPLIER

func can_expand_width() -> bool:
	return board_width < get_max_board_width()

func can_expand_height() -> bool:
	return board_height < get_max_board_height()

func expand_width() -> bool:
	if not can_expand_width():
		return false
	board_width += 1
	return true

func expand_height() -> bool:
	if not can_expand_height():
		return false
	board_height += 1
	return true

func get_current_stage_name() -> String:
	var world = int(floor(stage_index / 4.0)) + 1
	var stage = (stage_index % 4) + 1
	return "%d-%d" % [world, stage]
