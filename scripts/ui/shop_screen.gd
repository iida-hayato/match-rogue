extends Control

signal shop_finished()

@onready var gold_label: Label = $VBox/GoldLabel
@onready var next_stage_info: Label = $VBox/NextStageInfo
@onready var next_button: Button = $VBox/NextButton

var run_state

func _ready() -> void:
	next_button.pressed.connect(_on_next_button_pressed)

func initialize_shop(run: Object, next_plan: Object) -> void:
	run_state = run
	gold_label.text = "Gold: %d" % run_state.gold
	next_stage_info.text = "Next Stage: %s (Target: %d)" % [
		run_state.get_current_stage_name(),
		next_plan.target_score
	]

func _on_next_button_pressed() -> void:
	shop_finished.emit()
