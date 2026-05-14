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
@onready var board_stack: Control = $MarginContainer/VBox/MainLayout/BoardArea/BoardStack
@onready var board_view: Control = $MarginContainer/VBox/MainLayout/BoardArea/BoardStack/BoardView
@onready var draw_label: Label = $MarginContainer/VBox/MainLayout/RightPanel/DeckInfo/DrawPileLabel
@onready var discard_label: Label = $MarginContainer/VBox/MainLayout/RightPanel/DeckInfo/DiscardPileLabel
@onready var drop_button: Button = $MarginContainer/VBox/MainLayout/RightPanel/DropButton
@onready var relics_container: GridContainer = $MarginContainer/VBox/MainLayout/RightPanel/RelicsContainer

# Use load() instead of preload() for domain scripts to break potential cyclic dependencies
var RunState_ = load("res://scripts/domain/run_state.gd")
var GemInstance_ = load("res://scripts/domain/gem_instance.gd")
var DeckState_ = load("res://scripts/domain/deck_state.gd")
var StageMaster_ = load("res://scripts/domain/stage_master.gd")
var BoardState_ = load("res://scripts/domain/board_state.gd")
var StageState_ = load("res://scripts/domain/stage_state.gd")
var MatchResolver_ = load("res://scripts/domain/match_resolver.gd")
var CascadeResolver_ = load("res://scripts/domain/cascade_resolver.gd")
var ScoreCalculator_ = load("res://scripts/domain/score_calculator.gd")
const GemTextureManager_ = preload("res://scripts/ui/gem_texture_manager.gd")
const GEM_VIEW_SCENE = preload("res://scenes/components/gem_view.tscn")

var run_state
var board_state
var deck_state
var stage_state
var gem_views = [] # 2D array [y][x]
var selected_pos = null
var is_animating = false
var run_finished: bool = false

const SWAP_DURATION = 0.15
const CLEAR_DURATION = 0.2
const FALL_DURATION = 0.2
const MAX_CHAIN_STEPS = 50
const MAX_RESOLUTION_STEPS = 100
const MIN_TILE_SIZE = 12.0
const BOARD_PADDING = 12.0

var gem_definitions: Array[String] = ["red", "blue", "green", "yellow", "purple"]
var tile_size: float = 64.0
var board_origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	set_process_input(true)
	_setup_pause_overlay()
	
	# Fix button connection path
	var view_deck_btn = $MarginContainer/VBox/MainLayout/RightPanel/ViewDeckButton
	if view_deck_btn:
		view_deck_btn.pressed.connect(_on_view_deck_pressed)
	if drop_button:
		drop_button.pressed.connect(_on_drop_pressed)
	board_view.resized.connect(_on_board_view_resized)
	
	# Standalone test
	if get_tree().current_scene == self:
		var mock_run = RunState_.new()
		var initial_gems: Array = []
		var defs = ["red", "blue", "green", "yellow", "purple"]
		for i in range(100):
			var g = GemInstance_.new(defs[i % defs.size()])
			initial_gems.append(g)
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
		var overlay = get_node_or_null("PauseOverlay")
		if overlay:
			overlay.visible = !overlay.visible
			get_tree().paused = overlay.visible
		return

	if is_animating or selected_pos == null or get_tree().paused or stage_state == null or stage_state.moves_remaining <= 0:
		return
	
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		var mouse_pos = board_view.get_local_mouse_position()
		var relative_pos = mouse_pos - board_origin
		var grid_pos = Vector2i(
			int(floor(relative_pos.x / tile_size)),
			int(floor(relative_pos.y / tile_size))
		)
		
		if grid_pos != selected_pos and is_within_bounds(grid_pos.x, grid_pos.y):
			if is_adjacent(selected_pos, grid_pos):
				var p1 = selected_pos
				var p2 = grid_pos
				gem_views[selected_pos.y][selected_pos.x].set_highlight(false)
				selected_pos = null
				await try_swap(p1, p2)

func is_within_bounds(x: int, y: int) -> bool:
	return board_state != null and board_state.is_within_bounds(x, y)

func initialize_stage(run: Object, deck: Object, plan: Object) -> void:
	print("[StagePlayScreen] Initializing Stage: %d (Target Score: %d)" % [plan.stage_index, plan.target_score])
	run_state = run
	deck_state = deck
	board_state = BoardState_.new(run.board_width, run.board_height)
	stage_state = StageState_.new()
	stage_state.target_score = plan.target_score
	stage_state.moves_remaining = plan.move_limit
	stage_state.obstacle_rate = plan.obstacle_rate
	
	selected_pos = null
	is_animating = false
	run_finished = false
	
	setup_board_views()
	_refresh_board_layout()
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
	stage_label.text = "Stage: %s%s" % [run_state.get_stage_progress_text(), obstacle_info]
	score_label.text = "Score: %d / %d" % [stage_state.score, stage_state.target_score]
	moves_label.text = "Moves: %d" % stage_state.moves_remaining
	gold_label.text = "Gold: %d" % run_state.gold
	drop_button.text = "Drop: %d" % stage_state.drop_charges_remaining
	# Drop is allowed even when moves are exhausted, as long as empty cells remain.
	# The game-over check handles the case where both moves and drops are unavailable.
	drop_button.disabled = is_animating or stage_state.drop_charges_remaining <= 0 or not board_state.has_empty_cells()
	
	score_gauge.max_value = stage_state.target_score
	score_gauge.value = min(stage_state.score, stage_state.target_score)
	_maybe_finish_run()

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
		"relic_rocket_workshop": return "Rocket Workshop: 4 in a row creates a rocket gem."
		"relic_bomb_workshop": return "Bomb Workshop: T and cross matches create a bomb gem."
		"relic_prism_secret": return "Prism Secret: 5 in a row creates a diagonal beam gem."
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
	gem_views.resize(board_state.height)
	for y in range(board_state.height):
		gem_views[y] = []
		gem_views[y].resize(board_state.width)
		for x in range(board_state.width):
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
		
		# For initial refill, we must also null out gem_views to keep them in sync
		for m in matches:
			for pos in m.positions:
				var gem = board_state.get_gem(pos.x, pos.y)
				if gem:
					if not gem.is_stone():
						deck_state.discard(gem)
					board_state.set_gem(pos.x, pos.y, null)
				
				# Also visually "clear" (hidden) for initial setup
				if gem_views[pos.y][pos.x]:
					gem_views[pos.y][pos.x].visible = false
	
	update_all_views()
	update_deck_ui()

func update_all_views() -> void:
	_refresh_board_layout()
	for y in range(board_state.height):
		for x in range(board_state.width):
			update_gem_view(x, y)

func update_gem_view(x: int, y: int) -> void:
	var gem = board_state.get_gem(x, y)
	var view = gem_views[y][x]
	if gem and view:
		view.setup_gem(gem)
		view.visible = true
		view.size = Vector2(tile_size, tile_size)
		view.position = _board_position_for_cell(Vector2i(x, y))
		view.board_pos = Vector2i(x, y)
	elif view:
		view.visible = false
		view.size = Vector2(tile_size, tile_size)

func _on_gem_clicked(pos: Vector2i) -> void:
	if is_animating or get_tree().paused or stage_state == null or stage_state.moves_remaining <= 0: return
	
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
	var gem1 = board_state.get_gem(p1.x, p1.y)
	var gem2 = board_state.get_gem(p2.x, p2.y)

	if gem1 == null and gem2 == null:
		is_animating = false
		update_hud()
		return

	if gem1 == null or gem2 == null:
		await animate_move_to_empty(p1, p2)
		board_state.swap_gems(p1.x, p1.y, p2.x, p2.y)
		stage_state.moves_remaining = max(0, stage_state.moves_remaining - 1)
		update_all_views()
		is_animating = false
		update_hud()
		check_game_end()
		return

	await animate_swap(p1, p2)
	board_state.swap_gems(p1.x, p1.y, p2.x, p2.y)
	var include_boxes = run_state.relic_ids.has("relic_box_match")
	var matches = MatchResolver_.find_matches(board_state, include_boxes)
	stage_state.moves_remaining = max(0, stage_state.moves_remaining - 1)
	update_hud()
	if matches.size() > 0:
		await resolve_board(false)
	
	is_animating = false
	update_hud()

func animate_move_to_empty(p1: Vector2i, p2: Vector2i) -> void:
	var source = p1
	var target = p2
	if gem_views[source.y][source.x] == null:
		source = p2
		target = p1

	var moving_view = gem_views[source.y][source.x]
	if moving_view == null or gem_views[target.y][target.x] != null:
		return

	var tween = create_tween()
	tween.tween_property(moving_view, "position", _board_position_for_cell(target), SWAP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	gem_views[target.y][target.x] = moving_view
	gem_views[source.y][source.x] = null
	moving_view.board_pos = target

func animate_swap(p1: Vector2i, p2: Vector2i) -> void:
	var v1 = gem_views[p1.y][p1.x]
	var v2 = gem_views[p2.y][p2.x]
	if not v1 or not v2: return
	
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
		label.add_theme_font_size_override("font_size", int(clamp(tile_size * 0.65, 18.0, 32.0)))
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", int(clamp(tile_size * 0.12, 3.0, 6.0)))
		
		board_view.add_child(label)
		label.position = _board_position_for_cell(pos) + Vector2(tile_size * 0.3, 0)
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(label, "position:y", label.position.y - max(28.0, tile_size), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.2)
		tween.finished.connect(func(): label.queue_free())

func _create_special_spawn_for_shape(match_res: Dictionary) -> Dictionary:
	var shape = match_res.shape
	var positions = match_res.positions
	var center = _get_special_spawn_position(positions, shape)

	var effect = _get_special_effect_for_shape(shape)

	if effect != "":
		var gem = board_state.get_gem(center.x, center.y)
		if gem:
			var spawned_gem = gem.duplicate()
			spawned_gem.add_coat(effect)
			print("[StagePlayScreen] Queued %s spawn at %s" % [effect, center])
			return {"position": center, "gem": spawned_gem}
	return {}

func _get_special_effect_for_shape(shape: int) -> String:
	match shape:
		MatchResolver_.MatchShape.LINE_4:
			if run_state.relic_ids.has("relic_rocket_workshop"):
				return "rocket_v" if randf() > 0.5 else "rocket_h"
		MatchResolver_.MatchShape.T_SHAPE, MatchResolver_.MatchShape.CROSS:
			if run_state.relic_ids.has("relic_bomb_workshop"):
				return "bomb"
		MatchResolver_.MatchShape.LINE_5:
			if run_state.relic_ids.has("relic_prism_secret"):
				return "beam"
		MatchResolver_.MatchShape.BOX_4:
			return "coin"
	return ""

func animate_clear(matches: Array) -> void:
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
	# Important: process from bottom up to avoid overwriting views we still need
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
			var target_pos = _board_position_for_cell(to)
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
		gem_view.size = Vector2(tile_size, tile_size)
		gem_views[to.y][to.x] = gem_view
		
		gem_view.position = _board_position_for_spawn(from)
		
		var dist = abs(to.y - from.y)
		var duration = FALL_DURATION + (dist * 0.05)
		var target_pos = _board_position_for_cell(to)
		tween.tween_property(gem_view, "position", target_pos, duration).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	await tween.finished

func resolve_board(allow_refill: bool) -> void:
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
		var special_spawns: Array[Dictionary] = []
		var reserved_spawn_positions: Dictionary = {}
		for res in match_results:
			if res.shape != MatchResolver_.MatchShape.LINE_3:
				var spawn = _create_special_spawn_for_shape(res)
				if not spawn.is_empty() and not reserved_spawn_positions.has(spawn.position):
					reserved_spawn_positions[spawn.position] = true
					special_spawns.append(spawn)
			for pos in res.positions:
				matched_positions.append(pos)

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
		var total_logical_clears = all_cleared_positions.duplicate()
		for pos in stone_breaks:
			if not pos in total_logical_clears:
				total_logical_clears.append(pos)
				
		for pos in total_logical_clears:
			var gem = board_state.get_gem(pos.x, pos.y)
			if gem:
				if not gem.is_stone():
					cleared_gems.append(gem)
					if gem.coat_ids.has("coin"):
						stage_state.gold_earned += 1
					deck_state.discard(gem)
				board_state.set_gem(pos.x, pos.y, null)

		for spawn in special_spawns:
			var spawn_pos: Vector2i = spawn.position
			var spawn_gem = spawn.gem
			if board_state.get_gem(spawn_pos.x, spawn_pos.y) == null:
				board_state.set_gem(spawn_pos.x, spawn_pos.y, spawn_gem)
				_create_gem_view_at_position(spawn_pos, spawn_gem)
		
		var score_result = ScoreCalculator_.calculate_score(cleared_gems, stage_state.chain_index, run_state.relic_ids)
		stage_state.score += score_result.delta
		
		run_state.total_score += score_result.delta
		run_state.total_gems_cleared += cleared_gems.size()
		run_state.max_chain = max(run_state.max_chain, stage_state.chain_index + 1)
		run_state.largest_clear = max(run_state.largest_clear, cleared_gems.size())
		
		if cleared_gems.size() > 0:
			_spawn_score_popups(all_cleared_positions, score_result.delta / max(1, all_cleared_positions.size()))
		
		if stage_state.chain_index > 0:
			show_announcement(combo_label, "%d COMBO!" % (stage_state.chain_index + 1), "+%d" % score_result.delta)
			
		stage_state.chain_index += 1
		resolution_steps += 1
		
		update_hud()
		update_deck_ui()
		
		var movements = CascadeResolver_.apply_gravity(board_state)
		await animate_movements(movements)
		update_all_views()
		
		if allow_refill:
			var spawns = CascadeResolver_.refill_from_deck(board_state, deck_state, stage_state.obstacle_rate)
			await animate_spawns(spawns)
			
			update_all_views()

	check_game_end()

func check_game_end() -> void:
	if run_finished:
		return
	if stage_state.is_cleared():
		run_finished = true
		stage_finished.emit(true)
	elif _should_end_run():
		run_finished = true
		stage_finished.emit(false)

func _should_end_run() -> bool:
	if stage_state == null:
		return false
	if stage_state.moves_remaining > 0:
		return false
	if stage_state.score >= stage_state.target_score:
		return false
	if stage_state.drop_charges_remaining <= 0:
		return true
	return not board_state.has_empty_cells()

func _maybe_finish_run() -> void:
	if run_finished or stage_state == null:
		return
	if stage_state.is_cleared() or _should_end_run():
		check_game_end()

func _on_view_deck_pressed() -> void:
	view_deck_requested.emit()

func _on_drop_pressed() -> void:
	if is_animating or get_tree().paused or stage_state == null or stage_state.drop_charges_remaining <= 0:
		return
	if not board_state.has_empty_cells():
		return

	if selected_pos != null and gem_views[selected_pos.y][selected_pos.x]:
		gem_views[selected_pos.y][selected_pos.x].set_highlight(false)
	selected_pos = null
	is_animating = true
	stage_state.drop_charges_remaining -= 1
	update_hud()

	var spawns = CascadeResolver_.refill_from_deck(board_state, deck_state, stage_state.obstacle_rate)
	await animate_spawns(spawns)

	update_all_views()
	await resolve_board(false)

	is_animating = false
	update_hud()

func _refresh_board_layout() -> void:
	if board_state == null:
		return

	var padding = Vector2(BOARD_PADDING, BOARD_PADDING)
	var available_size = board_view.size - (padding * 2.0)
	if available_size.x <= 0.0 or available_size.y <= 0.0:
		available_size = board_stack.custom_minimum_size - (padding * 2.0)

	tile_size = floor(min(
		available_size.x / max(1, board_state.width),
		available_size.y / max(1, board_state.height)
	))
	tile_size = max(MIN_TILE_SIZE, tile_size)

	var board_pixel_size = Vector2(board_state.width * tile_size, board_state.height * tile_size)
	var centered_offset = (available_size - board_pixel_size) * 0.5
	board_origin = padding + Vector2(floor(centered_offset.x), floor(centered_offset.y))

func _board_position_for_cell(cell: Vector2i) -> Vector2:
	return board_origin + Vector2(cell.x * tile_size, cell.y * tile_size)

func _board_position_for_spawn(spawn_cell: Vector2i) -> Vector2:
	return board_origin + Vector2(spawn_cell.x * tile_size, spawn_cell.y * tile_size)

func _on_board_view_resized() -> void:
	if board_state != null:
		update_all_views()

func _get_special_spawn_position(positions: Array[Vector2i], shape: int) -> Vector2i:
	if positions.is_empty():
		return Vector2i.ZERO

	var x_counts := {}
	var y_counts := {}
	for pos in positions:
		x_counts[pos.x] = int(x_counts.get(pos.x, 0)) + 1
		y_counts[pos.y] = int(y_counts.get(pos.y, 0)) + 1

	match shape:
		MatchResolver_.MatchShape.LINE_4, MatchResolver_.MatchShape.LINE_5:
			var sorted_positions = positions.duplicate()
			if y_counts.size() == 1:
				sorted_positions.sort_custom(func(a: Vector2i, b: Vector2i): return a.x < b.x)
			else:
				sorted_positions.sort_custom(func(a: Vector2i, b: Vector2i): return a.y < b.y)
			return sorted_positions[int(floor((sorted_positions.size() - 1) / 2.0))]
		MatchResolver_.MatchShape.L_SHAPE, MatchResolver_.MatchShape.T_SHAPE, MatchResolver_.MatchShape.CROSS:
			var best_pos = positions[0]
			var best_score = -1
			for pos in positions:
				var score = int(x_counts.get(pos.x, 0)) + int(y_counts.get(pos.y, 0))
				if score > best_score:
					best_score = score
					best_pos = pos
			return best_pos
		_:
			return positions[0]

func _create_gem_view_at_position(pos: Vector2i, gem: Object) -> void:
	if gem_views[pos.y][pos.x] != null:
		gem_views[pos.y][pos.x].queue_free()

	var gem_view = GEM_VIEW_SCENE.instantiate()
	board_view.add_child(gem_view)
	gem_view.board_pos = pos
	gem_view.gem_clicked.connect(_on_gem_clicked)
	gem_view.setup_gem(gem)
	gem_view.size = Vector2(tile_size, tile_size)
	gem_view.position = _board_position_for_cell(pos)
	gem_views[pos.y][pos.x] = gem_view
