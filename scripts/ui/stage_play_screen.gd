extends Control

signal stage_finished(success: bool)
signal view_deck_requested()

@onready var stage_label: Label = $MarginContainer/VBox/HUD/StageLabel
@onready var moves_label: Label = $MarginContainer/VBox/HUD/MovesLabel
@onready var gold_label: Label = $MarginContainer/VBox/HUD/GoldLabel
@onready var score_label: Label = $MarginContainer/VBox/ScoreContainer/ScoreLabel
@onready var score_gauge: ProgressBar = $MarginContainer/VBox/ScoreContainer/ScoreGauge
@onready var combo_label: Label = $MarginContainer/VBox/MainLayout/BoardArea/BoardStack/AnnouncementLayer/ComboLabel
@onready var combo_score_label: Label = $MarginContainer/VBox/MainLayout/BoardArea/BoardStack/AnnouncementLayer/ComboLabel/ComboScoreLabel
@onready var clear_count_label: Label = $MarginContainer/VBox/MainLayout/BoardArea/BoardStack/AnnouncementLayer/ClearCountLabel
@onready var tutorial_label: Label = $MarginContainer/VBox/MainLayout/BoardArea/BoardStack/AnnouncementLayer/TutorialLabel
@onready var board_view: Control = $MarginContainer/VBox/MainLayout/BoardArea/BoardStack/BoardView
@onready var draw_label: Label = $MarginContainer/VBox/MainLayout/RightPanel/DeckInfo/DrawPileLabel
@onready var discard_label: Label = $MarginContainer/VBox/MainLayout/RightPanel/DeckInfo/DiscardPileLabel
@onready var relics_container: GridContainer = $MarginContainer/VBox/MainLayout/RightPanel/RelicsContainer

const RunState_ = preload("res://scripts/domain/run_state.gd")
const GemInstance_ = preload("res://scripts/domain/gem_instance.gd")
const DeckState_ = preload("res://scripts/domain/deck_state.gd")
const StageMaster_ = preload("res://scripts/domain/stage_master.gd")
const BoardState_ = preload("res://scripts/domain/board_state.gd")
const StageState_ = preload("res://scripts/domain/stage_state.gd")
const MatchResolver_ = preload("res://scripts/domain/match_resolver.gd")
const CascadeResolver_ = preload("res://scripts/domain/cascade_resolver.gd")
const ScoreCalculator_ = preload("res://scripts/domain/score_calculator.gd")
const GemTextureManager_ = preload("res://scripts/ui/gem_texture_manager.gd")
const GEM_VIEW_SCENE = preload("res://scenes/components/gem_view.tscn")

var run_state
var board_state
var deck_state
var stage_state
var gem_views = [] # 2D array [y][x]
var selected_pos = null
var is_animating = false

const SWAP_DURATION = 0.15
const CLEAR_DURATION = 0.2
const FALL_DURATION = 0.2
const TILE_SIZE_ESTIMATE = 64.0
const MAX_CHAIN_STEPS = 50
const MAX_RESOLUTION_STEPS = 100

var gem_definitions: Array[String] = ["red", "blue", "green", "yellow", "purple"]
var color_map = {
	"red": Color.RED,
	"blue": Color.BLUE,
	"green": Color.GREEN,
	"yellow": Color.YELLOW,
	"purple": Color.PURPLE,
	"stone": Color.DARK_GRAY
}

func _ready() -> void:
	set_process_input(true)
	_setup_pause_overlay()
	$MarginContainer/VBox/MainLayout/RightPanel/ViewDeckButton.pressed.connect(_on_view_deck_pressed)
	# Standalone test
	if get_tree().current_scene == self:
		var mock_run = RunState_.new()
		var initial_gems: Array = []
		var defs = ["red", "blue", "green", "yellow", "purple"]
		for i in range(100):
			initial_gems.append(GemInstance_.new(defs[i % defs.size()]))
		var mock_deck = DeckState_.new(initial_gems)
		var mock_plan = StageMaster_.create_plan(0)
		initialize_stage(mock_run, mock_deck, mock_plan)

func _setup_pause_overlay() -> void:
	var overlay = ColorRect.new()
	overlay.name = "PauseOverlay"
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)
	
	var label = Label.new()
	label.text = "PAUSED - Press ESC to Resume"
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay.add_child(label)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var overlay = get_node("PauseOverlay")
		overlay.visible = !overlay.visible
		get_tree().paused = overlay.visible
		return

	if is_animating or selected_pos == null or get_tree().paused:
		return
	
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		var mouse_pos = board_view.get_local_mouse_position()
		var grid_pos = Vector2i(
			int(floor(mouse_pos.x / TILE_SIZE_ESTIMATE)),
			int(floor(mouse_pos.y / TILE_SIZE_ESTIMATE))
		)
		
		if grid_pos != selected_pos and is_within_bounds(grid_pos):
			if is_adjacent(selected_pos, grid_pos):
				var p1 = selected_pos
				var p2 = grid_pos
				gem_views[selected_pos.y][selected_pos.x].set_highlight(false)
				selected_pos = null
				await try_swap(p1, p2)

func is_within_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < 8 and pos.y >= 0 and pos.y < 8

func initialize_stage(run: Object, deck: Object, plan: Object) -> void:
	print("[StagePlayScreen] Initializing Stage: %d (Target Score: %d)" % [plan.stage_index, plan.target_score])
	run_state = run
	deck_state = deck
	board_state = BoardState_.new(8, 8)
	stage_state = StageState_.new()
	stage_state.target_score = plan.target_score
	stage_state.moves_remaining = plan.move_limit
	stage_state.obstacle_rate = plan.obstacle_rate
	
	selected_pos = null
	is_animating = false
	
	setup_board_views()
	initial_refill()
	update_hud()
	update_deck_ui()
	update_relics()
	
	if plan.stage_index == 0:
		tutorial_label.visible = true
		
	print("[StagePlayScreen] Initialization complete for stage %d." % plan.stage_index)

func update_deck_ui() -> void:
	draw_label.text = "Draw: %d" % deck_state.draw_pile.size()
	discard_label.text = "Discard: %d" % deck_state.discard_pile.size()

func update_hud() -> void:
	var obstacle_info = ""
	if stage_state.obstacle_rate > 0:
		obstacle_info = " (Obs: %d%%)" % int(stage_state.obstacle_rate * 100)
	stage_label.text = "Stage: %s%s" % [run_state.get_current_stage_name(), obstacle_info]
	score_label.text = "Score: %d / %d" % [stage_state.score, stage_state.target_score]
	moves_label.text = "Moves: %d" % stage_state.moves_remaining
	gold_label.text = "Gold: %d" % run_state.gold
	
	score_gauge.max_value = stage_state.target_score
	score_gauge.value = min(stage_state.score, stage_state.target_score)

func update_relics() -> void:
	for child in relics_container.get_children():
		child.queue_free()
	
	for relic_id in run_state.relic_ids:
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(48, 48)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture = GemTextureManager_.get_relic_texture(relic_id)
		
		# Tooltip
		tex_rect.tooltip_text = _get_relic_description(relic_id)
		relics_container.add_child(tex_rect)

func _get_relic_description(id: String) -> String:
	match id:
		"relic_mining": return "Mining Emblem: Clear 6+ gems to get huge bonus multipliers."
		"relic_chain": return "Chain Gear: Increases chain multiplier bonus per step."
		"relic_shop": return "Member Card: 15% discount on all shop items."
		"relic_box_match": return "Magic Box: Allows matching 2x2 squares of the same color."
	return "No description available."

func show_announcement(label: Label, text: String, sub_text: String = "") -> void:
	label.text = text
	label.visible = true
	label.modulate.a = 1.0
	label.scale = Vector2(0.5, 0.5)
	
	if label == combo_label:
		combo_score_label.text = sub_text
		combo_score_label.visible = sub_text != ""
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(label, "modulate:a", 0.0, 1.2).set_delay(0.5)
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	label.visible = false

func setup_board_views() -> void:
	for child in board_view.get_children():
		child.queue_free()
	
	gem_views = []
	gem_views.resize(8)
	for y in range(8):
		gem_views[y] = []
		gem_views[y].resize(8)
		for x in range(8):
			var gem_view = GEM_VIEW_SCENE.instantiate()
			board_view.add_child(gem_view)
			gem_view.board_pos = Vector2i(x, y)
			gem_view.gem_clicked.connect(_on_gem_clicked)
			gem_views[y][x] = gem_view

func initial_refill() -> void:
	print("[StagePlayScreen] Starting initial refill...")
	var max_iterations = 100
	var iterations = 0
	while iterations < max_iterations:
		iterations += 1
		CascadeResolver_.refill_from_deck(board_state, deck_state, stage_state.obstacle_rate)
		var matches = MatchResolver_.find_matches(board_state)
		if matches.size() == 0:
			break
		
		for m in matches:
			for pos in m.positions:
				var gem = board_state.get_gem(pos.x, pos.y)
				if gem:
					if not gem.is_stone():
						deck_state.discard(gem)
					board_state.set_gem(pos.x, pos.y, null)
	
	update_all_views()
	update_deck_ui()

func update_all_views() -> void:
	for y in range(8):
		for x in range(8):
			update_gem_view(x, y)

func update_gem_view(x: int, y: int) -> void:
	var gem = board_state.get_gem(x, y)
	var view = gem_views[y][x]
	if gem and view:
		view.setup_gem(gem)
		view.visible = true
		view.position = Vector2(x * TILE_SIZE_ESTIMATE, y * TILE_SIZE_ESTIMATE)
		view.board_pos = Vector2i(x, y)
	elif view:
		view.visible = false

func _on_gem_clicked(pos: Vector2i) -> void:
	if is_animating or get_tree().paused: return
	
	if selected_pos == null:
		selected_pos = pos
		gem_views[pos.y][pos.x].set_highlight(true)
	else:
		if is_adjacent(selected_pos, pos):
			var p1 = selected_pos
			var p2 = pos
			gem_views[selected_pos.y][selected_pos.x].set_highlight(false)
			selected_pos = null
			await try_swap(p1, p2)
		else:
			gem_views[selected_pos.y][selected_pos.x].set_highlight(false)
			selected_pos = pos
			gem_views[pos.y][pos.x].set_highlight(true)

func is_adjacent(p1: Vector2i, p2: Vector2i) -> bool:
	return abs(p1.x - p2.x) + abs(p1.y - p2.y) == 1

func try_swap(p1: Vector2i, p2: Vector2i) -> void:
	is_animating = true
	await animate_swap(p1, p2)
	
	board_state.swap_gems(p1.x, p1.y, p2.x, p2.y)
	var include_boxes = run_state.relic_ids.has("relic_box_match")
	var matches = MatchResolver_.find_matches(board_state, include_boxes)
	if matches.size() > 0:
		stage_state.moves_remaining -= 1
		update_hud()
		await resolve_board()
	else:
		board_state.swap_gems(p1.x, p1.y, p2.x, p2.y)
		await animate_swap(p1, p2)
		update_all_views()
	
	is_animating = false

func animate_swap(p1: Vector2i, p2: Vector2i) -> void:
	var v1 = gem_views[p1.y][p1.x]
	var v2 = gem_views[p2.y][p2.x]
	var pos1 = v1.position
	var pos2 = v2.position
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(v1, "position", pos2, SWAP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(v2, "position", pos1, SWAP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	
	gem_views[p1.y][p1.x] = v2
	gem_views[p2.y][p2.x] = v1
	v1.board_pos = p2
	v2.board_pos = p1

func _spawn_score_popups(positions: Array, value_per_gem: int) -> void:
	if value_per_gem <= 0: return
	
	for pos in positions:
		var label = Label.new()
		label.text = str(value_per_gem)
		label.add_theme_font_size_override("font_size", 32)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 6)
		
		board_view.add_child(label)
		label.position = Vector2(pos.x * TILE_SIZE_ESTIMATE + 20, pos.y * TILE_SIZE_ESTIMATE)
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(label, "position:y", label.position.y - 60, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.2)
		tween.finished.connect(func(): label.queue_free())

func resolve_board() -> void:
	stage_state.chain_index = 0
	var resolution_steps = 0

	if tutorial_label.visible:
		tutorial_label.visible = false

	while true:
		if stage_state.chain_index >= MAX_CHAIN_STEPS or resolution_steps >= MAX_RESOLUTION_STEPS:
			print("[StagePlayScreen] Chain Overload triggered!")
			break

		var include_boxes = run_state.relic_ids.has("relic_box_match")
		var match_results = MatchResolver_.find_matches(board_state, include_boxes)
		if match_results.size() == 0:
			break

		var matched_positions = []
		for res in match_results:
			matched_positions.append_array(res.positions)
			if res.shape != MatchResolver_.MatchShape.LINE_3:
				_trigger_special_action_for_shape(res)

		var effect_positions = MatchResolver_.find_effect_positions(board_state, matched_positions)
		
		var all_cleared_positions = matched_positions.duplicate()
		for pos in effect_positions:
			if not pos in all_cleared_positions:
				all_cleared_positions.append(pos)
				
		var stone_breaks = MatchResolver_.find_stone_breaks(board_state, all_cleared_positions)
		
		var combined_clears = []
		for res in match_results:
			combined_clears.append(res.positions)
		if effect_positions.size() > 0:
			combined_clears.append(effect_positions)
		if stone_breaks.size() > 0:
			combined_clears.append(stone_breaks)
			
		await animate_clear(combined_clears)
		
		var cleared_gems = []
		for pos in all_cleared_positions:
			var gem = board_state.get_gem(pos.x, pos.y)
			if gem:
				cleared_gems.append(gem)
				if gem.coat_ids.has("coin"):
					stage_state.gold_earned += 1
				
				if not gem.is_stone():
					deck_state.discard(gem)
				board_state.set_gem(pos.x, pos.y, null)
		
		for pos in stone_breaks:
			board_state.set_gem(pos.x, pos.y, null)
		
		var score_result = ScoreCalculator_.calculate_score(cleared_gems, stage_state.chain_index, run_state.relic_ids)
		stage_state.score += score_result.delta
		
		run_state.total_score += score_result.delta
		run_state.total_gems_cleared += cleared_gems.size()
		run_state.max_chain = max(run_state.max_chain, stage_state.chain_index + 1)
		run_state.largest_clear = max(run_state.largest_clear, cleared_gems.size())
		
		if all_cleared_positions.size() > 0:
			_spawn_score_popups(all_cleared_positions, score_result.delta / all_cleared_positions.size())
		
		if stage_state.chain_index > 0:
			show_announcement(combo_label, "%d COMBO!" % (stage_state.chain_index + 1), "+%d" % score_result.delta)
			
		stage_state.chain_index += 1
		resolution_steps += 1
		
		update_hud()
		update_deck_ui()
		
		var movements = CascadeResolver_.apply_gravity(board_state)
		await animate_movements(movements)
		
		var spawns = CascadeResolver_.refill_from_deck(board_state, deck_state, stage_state.obstacle_rate)
		await animate_spawns(spawns)
		
		update_all_views()
	
	check_game_end()

func _trigger_special_action_for_shape(match_res: Dictionary) -> void:
	var shape = match_res.shape
	var positions = match_res.positions
	var center = positions[0]

	print("[StagePlayScreen] Special Action for Shape: %s" % shape)

	var effect = ""
	match shape:
		MatchResolver_.MatchShape.LINE_4, MatchResolver_.MatchShape.L_SHAPE:
			effect = "rocket_v" if randf() > 0.5 else "rocket_h"
		MatchResolver_.MatchShape.T_SHAPE, MatchResolver_.MatchShape.CROSS, MatchResolver_.MatchShape.LINE_5:
			effect = "bomb"
		MatchResolver_.MatchShape.BOX_4:
			effect = "coin"

	if effect != "":
		var gem = board_state.get_gem(center.x, center.y)
		if gem:
			gem.add_coat(effect)
			print("[StagePlayScreen] Applied %s to gem at %s" % [effect, center])

func animate_clear(matches: Array[Array]) -> void:
	var tween = create_tween().set_parallel(true)
	var processed_cells = []
	for m in matches:
		for pos in m:
			if pos in processed_cells: continue
			processed_cells.append(pos)
			var view = gem_views[pos.y][pos.x]
			if view:
				tween.tween_property(view, "modulate:a", 0.0, CLEAR_DURATION)
				tween.tween_property(view, "scale", Vector2.ZERO, CLEAR_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	
	for pos in processed_cells:
		var view = gem_views[pos.y][pos.x]
		if view:
			view.queue_free()
			gem_views[pos.y][pos.x] = null

func animate_movements(movements: Array) -> void:
	if movements.is_empty(): return
	
	var tween = create_tween().set_parallel(true)
	var sorted_moves = movements.duplicate()
	sorted_moves.sort_custom(func(a, b): return a.to.y > b.to.y)
	
	for move in sorted_moves:
		var from = move.from
		var to = move.to
		var view = gem_views[from.y][from.x]
		if view:
			gem_views[to.y][to.x] = view
			gem_views[from.y][from.x] = null
			view.board_pos = to
			
			var dist = abs(to.y - from.y)
			var duration = FALL_DURATION + (dist * 0.05)
			var target_pos = Vector2(to.x * TILE_SIZE_ESTIMATE, to.y * TILE_SIZE_ESTIMATE)
			tween.tween_property(view, "position", target_pos, duration).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	await tween.finished

func animate_spawns(spawns: Array) -> void:
	if spawns.is_empty(): return
	
	var tween = create_tween().set_parallel(true)
	for spawn in spawns:
		var from = spawn.from
		var to = spawn.to
		var gem_view = GEM_VIEW_SCENE.instantiate()
		board_view.add_child(gem_view)
		gem_view.board_pos = to
		gem_view.gem_clicked.connect(_on_gem_clicked)
		gem_view.setup_gem(spawn.gem)
		gem_views[to.y][to.x] = gem_view
		
		gem_view.position = Vector2(from.x * TILE_SIZE_ESTIMATE, from.y * TILE_SIZE_ESTIMATE)
		
		var dist = abs(to.y - from.y)
		var duration = FALL_DURATION + (dist * 0.05)
		var target_pos = Vector2(to.x * TILE_SIZE_ESTIMATE, to.y * TILE_SIZE_ESTIMATE)
		tween.tween_property(gem_view, "position", target_pos, duration).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	await tween.finished

func check_game_end() -> void:
	if stage_state.is_cleared():
		stage_finished.emit(true)
	elif stage_state.is_game_over():
		stage_finished.emit(false)

func _on_view_deck_pressed() -> void:
	view_deck_requested.emit()
