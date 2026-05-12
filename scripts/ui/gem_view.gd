extends TextureRect

signal gem_clicked(pos: Vector2i)

const GemTextureManager = preload("res://scripts/ui/gem_texture_manager.gd")
const DescriptionService = preload("res://scripts/domain/description_service.gd")

@onready var effect_overlay: TextureRect = $EffectOverlay

var board_pos: Vector2i
var is_pressing = false

func setup_gem(gem: Object) -> void:
	# Base texture from Manager (preloaded)
	texture = GemTextureManager.get_gem_texture(gem.definition_id)
	
	# Tooltip
	tooltip_text = DescriptionService.get_gem_description(gem)
	
	# Effect overlay
	effect_overlay.texture = null
	for coat in gem.coat_ids:
		var tex = GemTextureManager.get_effect_texture(coat)
		if tex:
			effect_overlay.texture = tex
			break

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_pressing = true
			gem_clicked.emit(board_pos)
		else:
			is_pressing = false

func set_highlight(active: bool) -> void:
	if active:
		modulate.a = 0.5
	else:
		modulate.a = 1.0
