extends Control

signal selection_finished(indices: Array[int])
signal cancelled()

@onready var title_label: Label = $MarginContainer/VBox/Title
@onready var prompt_label: Label = $MarginContainer/VBox/Prompt
@onready var grid: GridContainer = $MarginContainer/VBox/ScrollContainer/GridContainer
@onready var confirm_button: Button = $MarginContainer/VBox/Buttons/ConfirmButton
@onready var cancel_button: Button = $MarginContainer/VBox/Buttons/CancelButton

const GEM_VIEW_SCENE = preload("res://scenes/components/gem_view.tscn")

var mode: String = "remove"
var max_count: int = 1
var selected_indices: Array[int] = []
var run_state: Object

func initialize(run: Object, screen_mode: String, count: int) -> void:
	run_state = run
	mode = screen_mode
	max_count = count
	selected_indices = []
	
	match mode:
		"remove":
			title_label.text = "REMOVE GEMS"
			prompt_label.text = "Select %d gem(s) to remove from your deck" % max_count
		"select":
			title_label.text = "SELECT GEMS"
			prompt_label.text = "Select %d gem(s)" % max_count
			
	_refresh_grid()
	_update_buttons()

func _refresh_grid() -> void:
	for child in grid.get_children():
		child.queue_free()
	
	for i in range(run_state.master_deck.size()):
		var gem = run_state.master_deck[i]
		var view = GEM_VIEW_SCENE.instantiate()
		grid.add_child(view)
		
		# We need to customize GemView for selection
		view.setup_gem(gem)
		view.gui_input.connect(_on_gem_gui_input.bind(i, view))
		
		if selected_indices.has(i):
			view.modulate = Color(1, 0.3, 0.3) # Red tint for removal
		else:
			view.modulate = Color.WHITE

func _on_gem_gui_input(event: InputEvent, index: int, view: Control) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if selected_indices.has(index):
			selected_indices.erase(index)
		else:
			if selected_indices.size() < max_count:
				selected_indices.append(index)
			elif max_count == 1:
				selected_indices = [index]
		
		_refresh_grid()
		_update_buttons()

func _update_buttons() -> void:
	confirm_button.disabled = selected_indices.size() == 0
	confirm_button.text = "CONFIRM (%d/%d)" % [selected_indices.size(), max_count]

func _on_confirm_pressed() -> void:
	selection_finished.emit(selected_indices)

func _on_cancel_pressed() -> void:
	cancelled.emit()
