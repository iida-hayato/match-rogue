extends Control

signal shop_finished()

@onready var gold_label: Label = $VBox/GoldLabel
@onready var next_stage_info: Label = $VBox/NextStageInfo
@onready var next_button: Button = $VBox/NextButton

var run_state

func _ready() -> void:
	next_button.pressed.connect(_on_next_button_pressed)
	if get_tree().current_scene == self:
		var mock_run = RunState.new()
		var mock_plan = StageMaster.create_plan(0)
		initialize_shop(mock_run, mock_plan)

func initialize_shop(run: Object, next_plan: Object) -> void:
	run_state = run
	gold_label.text = "Gold: %d" % run_state.gold
	var obstacle_text = ""
	if next_plan.obstacle_rate > 0:
		obstacle_text = " (Obstacle: Stone Gem %d%%)" % int(next_plan.obstacle_rate * 100)
	
	next_stage_info.text = "Next Stage: %s (Target: %d)%s" % [
		run_state.get_current_stage_name(),
		next_plan.target_score,
		obstacle_text
	]

func _on_next_button_pressed() -> void:
	shop_finished.emit()
