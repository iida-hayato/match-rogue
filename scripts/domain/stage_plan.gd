class_name StagePlan
extends RefCounted

var stage_index: int
var target_score: int
var move_limit: int

func _init(idx: int) -> void:
	stage_index = idx
	# Scaling formula
	target_score = 1000 + (stage_index * 500)
	move_limit = 20 - (stage_index / 4) # Slightly fewer moves as we progress
