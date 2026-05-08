extends TextureRect

signal gem_clicked(pos: Vector2i)

@onready var placeholder_rect: ColorRect = $PlaceholderRect
var board_pos: Vector2i

func set_gem_color(color: Color) -> void:
	placeholder_rect.color = color

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		gem_clicked.emit(board_pos)

func set_highlight(active: bool) -> void:
	if active:
		placeholder_rect.border_width = 2 # This property doesn't exist on ColorRect, I should use a ReferenceRect or something
		# For now, let's just change alpha or add a child
		modulate.a = 0.5
	else:
		modulate.a = 1.0
