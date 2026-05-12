extends Control

signal selection_finished(indices: Array[int])
signal cancelled()
signal closed()

@onready var title_label: Label = $MarginContainer/VBox/Title
@onready var prompt_label: Label = $MarginContainer/VBox/Prompt
@onready var grid: GridContainer = $MarginContainer/VBox/ScrollContainer/GridContainer
@onready var buttons_container: HBoxContainer = $MarginContainer/VBox/Buttons
@onready var confirm_button: Button = $MarginContainer/VBox/Buttons/ConfirmButton
@onready var cancel_button: Button = $MarginContainer/VBox/Buttons/CancelButton

const GEM_VIEW_SCENE = preload("res://scenes/components/gem_view.tscn")

var mode: String = "remove" # "remove", "select", "view"
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
			buttons_container.visible = true
		"select":
			title_label.text = "SELECT GEMS"
			prompt_label.text = "Select %d gem(s)" % max_count
			buttons_container.visible = true
		"view":
			title_label.text = "CURRENT DECK"
			prompt_label.text = "Total Gems: %d" % run_state.master_deck.size()
			_setup_view_only_ui()
			
	_refresh_grid()
	if mode != "view":
		_update_buttons()

func _setup_view_only_ui() -> void:
	# Hide edit buttons and show a simple CLOSE button
	confirm_button.visible = false
	cancel_button.visible = false
	
	if not buttons_container.has_node("CloseButton"):
		var close_btn = Button.new()
		close_btn.name = "CloseButton"
		close_btn.text = "CLOSE"
		close_btn.custom_minimum_size = Vector2(300, 70)
		close_btn.add_theme_font_size_override("font_size", 32)
		close_btn.pressed.connect(func(): closed.emit())
		buttons_container.add_child(close_btn)

func _refresh_grid() -> void:
	for child in grid.get_children():
		child.queue_free()
	
	for i in range(run_state.master_deck.size()):
		var gem = run_state.master_deck[i]
		var view = GEM_VIEW_SCENE.instantiate()
		grid.add_child(view)
		
		view.setup_gem(gem)
		if mode != "view":
			view.gui_input.connect(_on_gem_gui_input.bind(i, view))
			
			if selected_indices.has(i):
				view.modulate = Color(1, 0.3, 0.3)
			else:
				view.modulate = Color.WHITE
		else:
			# In view mode, maybe highlight special gems slightly?
			if gem.coat_ids.size() > 0:
				view.modulate = Color(1.2, 1.2, 1.2) # Brighten special gems

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
