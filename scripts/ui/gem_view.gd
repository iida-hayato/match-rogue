extends TextureRect

@onready var placeholder_rect: ColorRect = $PlaceholderRect

func set_gem_color(color: Color) -> void:
	placeholder_rect.color = color
