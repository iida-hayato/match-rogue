extends TextureRect

signal gem_clicked(pos: Vector2i)

@onready var effect_overlay: TextureRect = $EffectOverlay

var board_pos: Vector2i
var is_pressing = false

const TEXTURE_PATH = "res://assets/textures/gems/%s.svg"
const EFFECT_PATH = "res://assets/textures/gems/effect_%s.svg"

# Pre-cache textures to avoid frame drops
static var texture_cache = {}

func setup_gem(gem: Object) -> void:
	# Base texture
	var base_name = gem.definition_id
	texture = _get_cached_texture(TEXTURE_PATH % base_name)
	
	# Tooltip
	tooltip_text = _get_gem_description(gem)
	
	# Effect overlay
...
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
	effect_overlay.texture = null
	for coat in gem.coat_ids:
		# Check for primary effects that have visual overlays
		match coat:
			"rocket_v", "rocket_h", "bomb", "beam", "coin":
				effect_overlay.texture = _get_cached_texture(EFFECT_PATH % coat)
				break # Only one primary effect visual for MVP

func _get_cached_texture(path: String) -> Texture2D:
	if not texture_cache.has(path):
		if FileAccess.file_exists(path):
			texture_cache[path] = load(path)
		else:
			push_warning("Gem texture not found: " + path)
			return null
	return texture_cache[path]

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
