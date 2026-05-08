extends TextureRect

signal gem_clicked(pos: Vector2i)

@onready var placeholder_rect: ColorRect = $PlaceholderRect
var board_pos: Vector2i
var is_pressing = false

func set_gem_color(color: Color) -> void:
	placeholder_rect.color = color

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_pressing = true
			gem_clicked.emit(board_pos)
		else:
			is_pressing = false
	
	if event is InputEventMouseMotion and is_pressing:
		# If moved significantly while pressing, treat as drag intent
		# In Godot, for simple adjacency drag, we can just emit when entering another cell
		# but here we are inside the cell. Let's rely on the parent's _input or sibling detection.
		# For now, we'll let the parent handle the "target" of the drag.
		pass

func set_highlight(active: bool) -> void:
	if active:
		# For now, just change alpha for highlight
		modulate.a = 0.5
	else:
		modulate.a = 1.0
