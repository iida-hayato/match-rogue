extends Control

signal back_to_title_requested()

@onready var master_slider = $VBox/Options/Master/Slider
@onready var bgm_slider = $VBox/Options/BGM/Slider
@onready var se_slider = $VBox/Options/SE/Slider
@onready var speed_slider = $VBox/Options/AnimSpeed/Slider

func _on_back_pressed() -> void:
	back_to_title_requested.emit()

func _on_master_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_bgm_value_changed(value: float) -> void:
	# Future: handle BGM bus
	pass

func _on_se_value_changed(value: float) -> void:
	# Future: handle SE bus
	pass
