extends TextureRect

signal gem_clicked(pos: Vector2i)

@onready var effect_overlay: TextureRect = $EffectOverlay

var board_pos: Vector2i
var is_pressing = false

func setup_gem(gem: Object) -> void:
	# Base texture from Manager (preloaded)
	texture = GemTextureManager.get_gem_texture(gem.definition_id)
	
	# Tooltip
	tooltip_text = _get_gem_description(gem)
	
	# Effect overlay
	effect_overlay.texture = null
	for coat in gem.coat_ids:
		var tex = GemTextureManager.get_effect_texture(coat)
		if tex:
			effect_overlay.texture = tex
			break

func _get_gem_description(gem: Object) -> String:
	var desc = "Color: %s" % gem.definition_id.capitalize()
	if gem.is_stone():
		return "Stone Gem: Does not match. Breaks when nearby gems are cleared."
	
	for coat in gem.coat_ids:
		match coat:
			"rocket_v": desc += "\nEffect: Vertical Rocket"
			"rocket_h": desc += "\nEffect: Horizontal Rocket"
			"bomb": desc += "\nEffect: Bomb"
			"beam": desc += "\nEffect: Diagonal Beam"
			"coin": desc += "\nEffect: Gold Coin (+1G)"
	return desc

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
