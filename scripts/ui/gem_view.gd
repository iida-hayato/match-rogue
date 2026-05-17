extends TextureRect

signal gem_clicked(pos: Vector2i)

const GemTextureManager = preload("res://scripts/ui/gem_texture_manager.gd")
const DescriptionService = preload("res://scripts/domain/description_service.gd")

@onready var effect_overlay: TextureRect = $EffectOverlay
@onready var value_label: Label = $ValueLabel

var board_pos: Vector2i
var is_pressing = false

func setup_gem(gem: Object) -> void:
	# Base texture from Manager (preloaded)
	texture = GemTextureManager.get_gem_texture(gem.definition_id)
	
	# Tooltip
	tooltip_text = DescriptionService.get_gem_description(gem)
	
	# Value badge
	var value_bonus = int(gem.value_bonus)
	if gem.has_method("is_stone") and gem.is_stone():
		value_label.text = ""
		value_label.visible = false
	elif value_bonus > 0:
		value_label.text = "+%d" % value_bonus
		value_label.visible = true
	else:
		value_label.text = ""
		value_label.visible = false
	
	# Effect overlay
	effect_overlay.texture = null
	for coat in gem.coat_ids:
		var tex = GemTextureManager.get_effect_texture(coat)
		if tex:
			effect_overlay.texture = tex
			break
	value_label.anchor_left = 0.0
	value_label.anchor_top = 0.0
	value_label.anchor_right = 1.0
	value_label.anchor_bottom = 0.5
	value_label.offset_left = -2.0
	value_label.offset_top = 2.0
	value_label.offset_right = -2.0
	value_label.offset_bottom = 18.0
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

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
