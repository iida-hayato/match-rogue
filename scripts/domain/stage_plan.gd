extends RefCounted

var stage_index: int
var target_score: int
var move_limit: int
var obstacle_rate: float # 0.0 to 1.0

func _init(idx: int) -> void:
	stage_index = idx
	# Scaling formula based on 08_open_questions_and_tuning.md
	var curve = [500, 800, 1200, 1800, 2600, 3800, 5500, 8000, 12000, 18000, 28000, 42000, 64000, 100000]
	if stage_index < curve.size():
		target_score = curve[stage_index]
	else:
		# Endless Mode: Exponential growth (e.g., 50% increase per stage)
		var base_endless = curve.back()
		var endless_idx = stage_index - curve.size() + 1
		target_score = int(base_endless * pow(1.5, endless_idx))
	
	move_limit = 15 # Start with 15 moves as per provisional spec
	if stage_index >= 10:
		move_limit = 12 # Harder stages
		
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
