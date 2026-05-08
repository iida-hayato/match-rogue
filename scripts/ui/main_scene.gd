extends Control

func _ready() -> void:
	var play_screen = preload("res://scenes/screens/stage_play_screen.tscn").instantiate()
	add_child(play_screen)
	# Make it fill the screen
	play_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
