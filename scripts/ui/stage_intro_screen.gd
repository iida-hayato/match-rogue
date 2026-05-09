extends Control

signal start_requested()

@onready var title_label: Label = $MarginContainer/VBox/Title
@onready var target_label: Label = $MarginContainer/VBox/Stats/TargetLabel
@onready var moves_label: Label = $MarginContainer/VBox/Stats/MovesLabel
@onready var obstacle_label: Label = $MarginContainer/VBox/Stats/ObstacleLabel

func initialize(stage_name: String, plan: Object) -> void:
	title_label.text = "Stage %s" % stage_name
	target_label.text = "Target Score: %d" % plan.target_score
	moves_label.text = "Moves: %d" % plan.move_limit
	
	if plan.obstacle_rate > 0:
		obstacle_label.text = "Obstacle: Stone Gem %d%%" % int(plan.obstacle_rate * 100)
		obstacle_label.visible = true
	else:
		obstacle_label.visible = false

func _on_start_pressed() -> void:
	start_requested.emit()
