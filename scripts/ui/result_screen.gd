extends Control

signal restart_requested()

@onready var stats_label: Label = $MarginContainer/VBox/StatsLabel
@onready var restart_button: Button = $MarginContainer/VBox/RestartButton

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	if get_tree().current_scene == self:
		var mock_run = RunState.new()
		mock_run.total_gold_earned = 1234
		initialize_result(mock_run)

func initialize_result(run: Object) -> void:
	stats_label.text = "Total Gold Earned: %d" % run.total_gold_earned

func _on_restart_pressed() -> void:
	restart_requested.emit()
