extends Control

signal start_requested()

@onready var start_button: Button = $VBox/StartButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	start_requested.emit()
