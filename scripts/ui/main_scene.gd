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

func start_new_run() -> void:
	run_state = RunState.new()
	setup_initial_deck()
	load_stage(run_state.stage_index)
func setup_initial_deck() -> void:
	run_state.master_deck = []
	var gem_definitions = ["red", "blue", "green", "yellow", "purple"]
	for def_id in gem_definitions:
		for i in range(20):
			run_state.master_deck.append(GemInstance.new(def_id))

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
		# Calculate gold reward
		var stage_state = current_screen.stage_state
		var reward = ShopService.calculate_gold_reward(stage_state.score, plan.target_score)
		run_state.gold += reward
		run_state.total_gold_earned += reward
		
		run_state.stage_index += 1
		if run_state.stage_index < run_state.max_stages:
			load_reward_select()
		else:
			load_result_screen()
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

func load_reward_select() -> void:
	if current_screen:
		current_screen.queue_free()
	
	var rewards = RewardGenerator.generate_rewards(run_state.stage_index)
	var reward_screen_scene = load("res://scenes/screens/reward_select_screen.tscn")
	var reward_screen = reward_screen_scene.instantiate()
	add_child(reward_screen)
	reward_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_screen = reward_screen
	
	reward_screen.initialize_rewards(rewards)
	reward_screen.reward_chosen.connect(_on_reward_chosen)

func _on_reward_chosen(reward: Dictionary) -> void:
	apply_reward(reward)
	load_shop()

func apply_reward(reward: Dictionary) -> void:
	match reward.type:
		"gold":
			run_state.gold += reward.value
		"upgrade":
			# Placeholder for upgrade logic
			print("Upgraded %s gem" % reward.gem_id)
		"special_gem":
			# Placeholder for adding special gem
			print("Added %s gem" % reward.effect)

func load_shop() -> void:
	if current_screen:
		current_screen.queue_free()
	
	var next_plan = StageMaster.create_plan(run_state.stage_index)
	var shop_screen_scene = load("res://scenes/screens/shop_screen.tscn")
	var shop_screen = shop_screen_scene.instantiate()
	add_child(shop_screen)
	shop_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_screen = shop_screen
	
	shop_screen.initialize_shop(run_state, next_plan)
	shop_screen.shop_finished.connect(_on_shop_finished)

func _on_shop_finished() -> void:
	load_stage(run_state.stage_index)
