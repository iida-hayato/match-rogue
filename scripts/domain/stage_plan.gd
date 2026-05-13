extends RefCounted

var stage_index: int
var target_score: int
var move_limit: int
var obstacle_rate: float # 0.0 to 1.0

func _init(idx: int) -> void:
	stage_index = idx
	var curve = [125, 200, 300, 450, 650, 950, 1375, 2000, 3000, 4500, 7000, 10500, 16000, 25000]
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
