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

const GemTextureManager_ = preload("res://scripts/ui/gem_texture_manager.gd")
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
			title_label.text = "YOUR BUILD"
			prompt_label.text = "Current Deck & Relics"
			_setup_view_only_ui()
			
	_refresh_grid()
	_refresh_relics()
	if mode != "view":
		_update_buttons()

func _setup_view_only_ui() -> void:
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
			if gem.coat_ids.size() > 0:
				view.modulate = Color(1.2, 1.2, 1.2)

func _refresh_relics() -> void:
	if mode != "view": return
	
	var vbox = $MarginContainer/VBox
	var relic_label = vbox.get_node_or_null("RelicLabel")
	if not relic_label:
		relic_label = Label.new()
		relic_label.name = "RelicLabel"
		relic_label.text = "Acquired Relics"
		relic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		relic_label.add_theme_font_size_override("font_size", 32)
		vbox.add_child(relic_label)
		vbox.move_child(relic_label, 2) # After prompt
		
		var relic_container = HBoxContainer.new()
		relic_container.name = "RelicContainer"
		relic_container.alignment = BoxContainer.ALIGNMENT_CENTER
		relic_container.add_theme_constant_override("separation", 20)
		vbox.add_child(relic_container)
		vbox.move_child(relic_container, 3)
		
		var separator = HSeparator.new()
		separator.name = "BuildSeparator"
		vbox.add_child(separator)
		vbox.move_child(separator, 4)
		
	var container = vbox.get_node("RelicContainer")
	for child in container.get_children(): child.queue_free()
	
	for rid in run_state.relic_ids:
		var tex = TextureRect.new()
		tex.custom_minimum_size = Vector2(80, 80)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.texture = GemTextureManager_.get_relic_texture(rid)
		tex.tooltip_text = _get_relic_description(rid)
		container.add_child(tex)

func _get_relic_description(id: String) -> String:
	match id:
		"relic_mining": return "Mining Emblem: Clear 6+ gems to get huge bonus multipliers."
		"relic_chain": return "Chain Gear: Increases chain multiplier bonus per step."
		"relic_shop": return "Member Card: 15% discount on all shop items."
		"relic_box_match": return "Magic Box: Allows matching 2x2 squares of the same color."
	return "No description available."

func _on_gem_gui_input(event: InputEvent, index: int, _view: Control) -> void:
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
