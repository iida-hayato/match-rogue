extends Control

signal restart_requested()

@onready var stats_label: Label = $VBox/StatsLabel
@onready var restart_button: Button = $VBox/RestartButton

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)

func initialize_result(run: Object) -> void:
	stats_label.text = "Total Gold Earned: %d" % run.total_gold_earned

func _on_restart_pressed() -> void:
	restart_requested.emit()
