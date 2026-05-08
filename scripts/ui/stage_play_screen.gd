extends Control

signal stage_finished(success: bool)

@onready var stage_label: Label = $VBox/HUD/StageLabel
@onready var score_label: Label = $VBox/HUD/ScoreLabel
@onready var moves_label: Label = $VBox/HUD/MovesLabel
@onready var gold_label: Label = $VBox/HUD/GoldLabel
@onready var board_view: Control = $VBox/MainLayout/BoardArea/BoardView
@onready var draw_label: Label = $VBox/MainLayout/RightPanel/DeckInfo/DrawPileLabel
@onready var discard_label: Label = $VBox/MainLayout/RightPanel/DeckInfo/DiscardPileLabel

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
const TILE_SIZE_ESTIMATE = 80.0

var gem_definitions: Array[String] = ["red", "blue", "green", "yellow", "purple"]
var color_map = {
	"red": Color.RED,
	"blue": Color.BLUE,
	"green": Color.GREEN,
	"yellow": Color.YELLOW,
	"purple": Color.PURPLE
}

func _ready() -> void:
	set_process_input(true)
	# Standalone test
	if get_tree().current_scene == self:
		var mock_run = RunState.new()
		var initial_gems: Array[GemInstance] = []
		for i in range(100):
			initial_gems.append(GemInstance.new("red"))
		mock_run.deck = DeckState.new(initial_gems)
		var mock_plan = StageMaster.create_plan(0)
		initialize_stage(mock_run, mock_plan)

func _input(event: InputEvent) -> void:
	if is_animating or selected_pos == null:
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

func initialize_stage(run: Object, plan: Object) -> void:
	print("[StagePlayScreen] Initializing Stage: %d (Target Score: %d)" % [plan.stage_index, plan.target_score])
	run_state = run
	deck_state = run.deck
	board_state = BoardState.new(8, 8)
	stage_state = StageState.new()
	stage_state.target_score = plan.target_score
	stage_state.moves_remaining = plan.move_limit
	
	selected_pos = null
	is_animating = false
	
	setup_board_views()
	initial_refill()
	update_hud()
	update_deck_ui()
	print("[StagePlayScreen] Initialization complete for stage %d." % plan.stage_index)

func update_deck_ui() -> void:
	draw_label.text = "Draw: %d" % deck_state.draw_pile.size()
	discard_label.text = "Discard: %d" % deck_state.discard_pile.size()

func update_hud() -> void:
	stage_label.text = "Stage: %s" % run_state.get_current_stage_name()
	score_label.text = "Score: %d / %d" % [stage_state.score, stage_state.target_score]
	moves_label.text = "Moves: %d" % stage_state.moves_remaining
	gold_label.text = "Gold: %d" % run_state.gold

func setup_board_views() -> void:
	print("[StagePlayScreen] Setting up board views. Current children: %d" % board_view.get_child_count())
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
	print("[StagePlayScreen] Board views setup complete.")

func initial_refill() -> void:
	print("[StagePlayScreen] Starting initial refill...")
	var max_iterations = 100
	var iterations = 0
	while iterations < max_iterations:
		iterations += 1
		CascadeResolver.refill_from_deck(board_state, deck_state)
		var matches = MatchResolver.find_matches(board_state)
		if matches.size() == 0:
			break
		
		print("[StagePlayScreen] Match found in initial refill (iteration %d), clearing..." % iterations)
		for m in matches:
			for pos in m:
				var gem = board_state.get_gem(pos.x, pos.y)
				if gem:
					deck_state.discard(gem)
					board_state.set_gem(pos.x, pos.y, null)
	
	update_all_views()
	update_deck_ui()
	print("[StagePlayScreen] Initial refill complete after %d iterations." % iterations)

func update_all_views() -> void:
	for y in range(8):
		for x in range(8):
			update_gem_view(x, y)

func update_gem_view(x: int, y: int) -> void:
	var gem = board_state.get_gem(x, y)
	var view = gem_views[y][x]
	if gem and view:
		view.set_gem_color(color_map[gem.definition_id])
		view.visible = true
		view.position = Vector2(x * TILE_SIZE_ESTIMATE, y * TILE_SIZE_ESTIMATE)
		view.board_pos = Vector2i(x, y)
	elif view:
		view.visible = false

func _on_gem_clicked(pos: Vector2i) -> void:
	if is_animating: return
	
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
	var matches = MatchResolver.find_matches(board_state)
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
	
	# Update references and board_pos
	gem_views[p1.y][p1.x] = v2
	gem_views[p2.y][p2.x] = v1
	v1.board_pos = p2
	v2.board_pos = p1

func resolve_board() -> void:
	stage_state.chain_index = 0
	while true:
		var matches = MatchResolver.find_matches(board_state)
		if matches.size() == 0:
			break
		
		await animate_clear(matches)
		
		var cleared_gems = []
		for m in matches:
			for pos in m:
				var gem = board_state.get_gem(pos.x, pos.y)
				if gem:
					cleared_gems.append(gem)
					deck_state.discard(gem)
					board_state.set_gem(pos.x, pos.y, null)
		
		var score_result = ScoreCalculator.calculate_score(cleared_gems, stage_state.chain_index)
		stage_state.score += score_result.delta
		stage_state.chain_index += 1
		
		update_hud()
		update_deck_ui()
		
		var movements = CascadeResolver.apply_gravity(board_state)
		await animate_movements(movements)
		
		var spawns = CascadeResolver.refill_from_deck(board_state, deck_state)
		await animate_spawns(spawns)
		
		update_all_views()
	
	check_game_end()

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
		gem_view.set_gem_color(color_map[spawn.gem.definition_id])
		gem_views[to.y][to.x] = gem_view
		
		gem_view.position = Vector2(from.x * TILE_SIZE_ESTIMATE, from.y * TILE_SIZE_ESTIMATE)
		
		var dist = abs(to.y - from.y)
		var duration = FALL_DURATION + (dist * 0.05)
		var target_pos = Vector2(to.x * TILE_SIZE_ESTIMATE, to.y * TILE_SIZE_ESTIMATE)
		tween.tween_property(gem_view, "position", target_pos, duration).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	await tween.finished

func check_game_end() -> void:
	if stage_state.is_cleared():
		return_board_to_deck()
		stage_finished.emit(true)
	elif stage_state.is_game_over():
		return_board_to_deck()
		stage_finished.emit(false)

func return_board_to_deck() -> void:
	print("[StagePlayScreen] Returning all gems on board to discard pile.")
	for y in range(8):
		for x in range(8):
			var gem = board_state.get_gem(x, y)
			if gem:
				deck_state.discard(gem)
				board_state.set_gem(x, y, null)
	update_deck_ui()
