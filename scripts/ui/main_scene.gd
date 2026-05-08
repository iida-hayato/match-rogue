extends Control

const RunState = preload("res://scripts/domain/run_state.gd")
const StageMaster = preload("res://scripts/domain/stage_master.gd")
const GemInstance = preload("res://scripts/domain/gem_instance.gd")
const DeckState = preload("res://scripts/domain/deck_state.gd")

const ShopService = preload("res://scripts/domain/shop_service.gd")

var run_state: RunState
var current_screen: Control

func _ready() -> void:
	start_new_run()

func start_new_run() -> void:
	run_state = RunState.new()
	setup_initial_deck()
	load_stage(run_state.stage_index)

func setup_initial_deck() -> void:
	var initial_gems: Array[GemInstance] = []
	var gem_definitions = ["red", "blue", "green", "yellow", "purple"]
	for def_id in gem_definitions:
		for i in range(20):
			initial_gems.append(GemInstance.new(def_id))
	run_state.deck = DeckState.new(initial_gems)

func load_stage(stage_index: int) -> void:
	if current_screen:
		current_screen.queue_free()
	
	var plan = StageMaster.create_plan(stage_index)
	var play_screen_scene = load("res://scenes/screens/stage_play_screen.tscn")
	var play_screen = play_screen_scene.instantiate()
	add_child(play_screen)
	play_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_screen = play_screen
	
	play_screen.initialize_stage(run_state, plan)
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
			load_shop()
		else:
			print("Run Completed!")
	else:
		print("Game Over!")

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
