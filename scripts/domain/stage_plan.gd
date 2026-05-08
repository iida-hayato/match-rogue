class_name StagePlan
extends RefCounted

var stage_index: int
var target_score: int
var move_limit: int
var obstacle_rate: float # 0.0 to 1.0

func _init(idx: int) -> void:
	stage_index = idx
	# Scaling formula
	target_score = 1000 + (stage_index * 500)
	move_limit = 20 - (stage_index / 4) # Slightly fewer moves as we progress
	
	# Obstacle Rate progression
	if stage_index == 0:
		obstacle_rate = 0.0
	elif stage_index < 4:
		obstacle_rate = 0.03
	elif stage_index < 9:
		obstacle_rate = 0.05
	elif stage_index < 13:
		obstacle_rate = 0.08
	else:
		obstacle_rate = 0.10
