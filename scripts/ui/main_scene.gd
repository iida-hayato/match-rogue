extends Control

var run_state: RunState
var current_screen: Control

func _ready() -> void:
	load_title_screen()

func load_title_screen() -> void:
	if current_screen:
		current_screen.queue_free()
	
	var title_screen_scene = load("res://scenes/screens/title_screen.tscn")
	var title_screen = title_screen_scene.instantiate()
	add_child(title_screen)
	title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_screen = title_screen
	
	title_screen.start_requested.connect(start_new_run)
	title_screen.add_child(create_options_button(title_screen))

func create_options_button(_parent: Control) -> Button:
	var btn = Button.new()
	btn.text = "Options"
	btn.position = Vector2(20, 20)
	btn.pressed.connect(load_options_screen)
	return btn

func load_options_screen() -> void:
	# Hide current screen if needed, or just layer on top
	var options_scene = load("res://scenes/screens/options_screen.tscn")
	var options = options_scene.instantiate()
	add_child(options)
	options.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	options.back_to_title_requested.connect(func(): options.queue_free())

func start_new_run() -> void:
	run_state = RunState.new()
	setup_initial_deck()
	load_stage_intro(run_state.stage_index)
func setup_initial_deck() -> void:
	run_state.master_deck = []
	var gem_definitions = ["red", "blue", "green", "yellow", "purple"]
	for def_id in gem_definitions:
		for i in range(20):
			run_state.master_deck.append(GemInstance.new(def_id))

func load_stage_intro(stage_index: int) -> void:
	if current_screen:
		remove_child(current_screen)
		current_screen.queue_free()
	
	var plan = StageMaster.create_plan(stage_index)
	var intro_scene = load("res://scenes/screens/stage_intro_screen.tscn")
	var intro = intro_scene.instantiate()
	add_child(intro)
	intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_screen = intro
	
	intro.initialize(run_state.get_current_stage_name(), plan)
	intro.start_requested.connect(load_stage.bind(stage_index))

func load_stage(stage_index: int) -> void:
	print("[MainScene] Loading stage %d" % stage_index)
	if current_screen:
		remove_child(current_screen)
		current_screen.queue_free()

	# Create a fresh DeckState from the master_deck for this stage
	var stage_gems: Array[GemInstance] = []
	for gem in run_state.master_deck:
		stage_gems.append(gem.duplicate())
	var stage_deck = DeckState.new(stage_gems)

	var plan = StageMaster.create_plan(stage_index)
	print("[MainScene] Stage Plan: Target=%d, Moves=%d" % [plan.target_score, plan.move_limit])
	var play_screen_scene = load("res://scenes/screens/stage_play_screen.tscn")
	var play_screen = play_screen_scene.instantiate()
	add_child(play_screen)
	play_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_screen = play_screen

	play_screen.initialize_stage(run_state, stage_deck, plan)
	play_screen.stage_finished.connect(_on_stage_finished.bind(plan))


func _on_stage_finished(success: bool, plan: Object) -> void:
	if success:
		var stage_state = current_screen.stage_state
		var breakdown = ShopService.calculate_gold_reward_breakdown(stage_state, plan.target_score)
		
		# Record rewards
		run_state.gold += breakdown.total
		run_state.total_gold_earned += breakdown.total
		
		load_stage_clear_screen(run_state.get_current_stage_name(), stage_state, plan.target_score, breakdown)
	else:
		load_result_screen()

func load_stage_clear_screen(stage_name: String, stage_state: Object, target_score: int, breakdown: Dictionary) -> void:
	if current_screen:
		remove_child(current_screen)
		current_screen.queue_free()
	
	var clear_screen_scene = load("res://scenes/screens/stage_clear_screen.tscn")
	var clear_screen = clear_screen_scene.instantiate()
	add_child(clear_screen)
	clear_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_screen = clear_screen
	
	clear_screen.initialize(stage_name, stage_state, target_score, breakdown)
	clear_screen.continue_requested.connect(_on_clear_continue_pressed)

func _on_clear_continue_pressed() -> void:
	run_state.stage_index += 1
	if run_state.stage_index < run_state.max_stages:
		load_shop()
	else:
		load_result_screen()

func load_result_screen() -> void:
	if current_screen:
		current_screen.queue_free()
	
	var result_screen_scene = load("res://scenes/screens/result_screen.tscn")
	var result_screen = result_screen_scene.instantiate()
	add_child(result_screen)
	result_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_screen = result_screen
	result_screen.initialize_result(run_state)
	result_screen.restart_requested.connect(load_title_screen)
	result_screen.endless_requested.connect(_on_endless_requested)

func _on_endless_requested() -> void:
	run_state.is_endless = true
	# Stage index is already at 14 (end of normal run), 
	# so load_shop will prepare for stage 14 (first endless stage)
	load_shop()

func load_shop() -> void:
	if current_screen:
		remove_child(current_screen)
		current_screen.queue_free()

	var next_plan = StageMaster.create_plan(run_state.stage_index)
	var inventory = ShopGenerator.generate_shop_inventory(run_state.stage_index, run_state.relic_ids)

	var shop_screen_scene = load("res://scenes/screens/shop_screen.tscn")

	var shop_screen = shop_screen_scene.instantiate()
	add_child(shop_screen)
	shop_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_screen = shop_screen

	shop_screen.initialize_shop(run_state, next_plan, inventory)
	shop_screen.shop_finished.connect(_on_shop_finished)
	shop_screen.remove_gem_requested.connect(load_deck_edit_screen.bind("remove", 1))


func _on_shop_finished() -> void:
	load_stage_intro(run_state.stage_index)

func load_deck_edit_screen(mode: String, count: int) -> void:
	var previous_screen = current_screen
	
	var edit_scene = load("res://scenes/screens/deck_edit_screen.tscn")
	var edit_screen = edit_scene.instantiate()
	add_child(edit_screen)
	edit_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_screen = edit_screen
	
	if previous_screen:
		previous_screen.visible = false
	
	edit_screen.initialize(run_state, mode, count)
	
	edit_screen.selection_finished.connect(func(indices):
		_handle_deck_edit_result(mode, indices)
		edit_screen.queue_free()
		current_screen = previous_screen
		if current_screen:
			current_screen.visible = true
			if current_screen.has_method("update_ui"):
				current_screen.update_ui(StageMaster.create_plan(run_state.stage_index))
	)
	
	edit_screen.cancelled.connect(func():
		edit_screen.queue_free()
		current_screen = previous_screen
		if current_screen:
			current_screen.visible = true
	)

func _handle_deck_edit_result(mode: String, indices: Array[int]) -> void:
	match mode:
		"remove":
			var sorted_indices = indices.duplicate()
			sorted_indices.sort()
			sorted_indices.reverse()
			for i in sorted_indices:
				run_state.master_deck.remove_at(i)
			print("[MainScene] Removed %d gems from master deck." % indices.size())
