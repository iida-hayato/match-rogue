extends Control

const RunState = preload("res://scripts/domain/run_state.gd")
const StageMaster = preload("res://scripts/domain/stage_master.gd")
const GemInstance = preload("res://scripts/domain/gem_instance.gd")
const DeckState = preload("res://scripts/domain/deck_state.gd")

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
	play_screen.stage_finished.connect(_on_stage_finished)

func _on_stage_finished(success: bool) -> void:
	if success:
		run_state.stage_index += 1
		if run_state.stage_index < run_state.max_stages:
			# For MVP, go straight to next stage or show a simple transition
			print("Moving to stage %d" % run_state.stage_index)
			load_stage(run_state.stage_index)
		else:
			print("Run Completed!")
			# Show result screen
	else:
		print("Game Over!")
		# Show game over screen
