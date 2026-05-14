extends SceneTree

const BoardState_ = preload("res://scripts/domain/board_state.gd")
const DeckState_ = preload("res://scripts/domain/deck_state.gd")
const GemInstance_ = preload("res://scripts/domain/gem_instance.gd")
const MatchResolver_ = preload("res://scripts/domain/match_resolver.gd")
const RunState_ = preload("res://scripts/domain/run_state.gd")
const StageMaster_ = preload("res://scripts/domain/stage_master.gd")

var failures: Array[String] = []
var assertions := 0

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	Engine.time_scale = 100.0
	await _test_match_shape_classification()
	await _test_no_special_spawn_without_relic()
	await _test_special_gem_persists_after_creation()
	await _test_special_gem_triggers_on_next_chain()
	await _test_beam_spawn_requires_prism_secret()
	await _test_beam_range_relic_extends_diagonal_clear()
	await _test_rocket_range_relic_extends_line_clear()
	await _test_bomb_diagonal_relic_adds_corner_cells()
	await _test_move_into_empty_is_blocked()
	Engine.time_scale = 1.0
	await _cleanup()

	if failures.is_empty():
		print("TEST PASS: %d assertions" % assertions)
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	print("TEST FAIL: %d failures / %d assertions" % [failures.size(), assertions])
	quit(1)

func _test_match_shape_classification() -> void:
	var cases = [
		{
			"name": "line4",
			"positions": [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2)],
			"shape": MatchResolver_.MatchShape.LINE_4,
			"include_boxes": false
		},
		{
			"name": "line5",
			"positions": [Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3)],
			"shape": MatchResolver_.MatchShape.LINE_5,
			"include_boxes": false
		},
		{
			"name": "l_shape",
			"positions": [Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 1), Vector2i(3, 1)],
			"shape": MatchResolver_.MatchShape.L_SHAPE,
			"include_boxes": false
		},
		{
			"name": "t_shape",
			"positions": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(2, 2), Vector2i(2, 3)],
			"shape": MatchResolver_.MatchShape.T_SHAPE,
			"include_boxes": false
		},
		{
			"name": "cross",
			"positions": [Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3), Vector2i(1, 2), Vector2i(3, 2)],
			"shape": MatchResolver_.MatchShape.CROSS,
			"include_boxes": false,
			"expect_direct": true
		},
		{
			"name": "box4",
			"positions": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2)],
			"shape": MatchResolver_.MatchShape.BOX_4,
			"include_boxes": true
		}
	]

	for test_case in cases:
		var board = BoardState_.new(6, 6)
		var typed_positions: Array[Vector2i] = []
		for pos in test_case.positions:
			board.set_gem(pos.x, pos.y, GemInstance_.new("red"))
			typed_positions.append(pos)

		var actual_shape = MatchResolver_.analyze_shape(board, typed_positions) if test_case.get("expect_direct", false) else MatchResolver_.find_matches(board, test_case.include_boxes)[0].shape
		_assert_eq(actual_shape, test_case.shape, "shape classification: %s" % test_case.name)

func _test_special_gem_persists_after_creation() -> void:
	var screen = await _create_stage_screen()
	screen.run_state.add_relic("relic_rocket_workshop")
	_clear_board(screen)
	var positions = [Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7), Vector2i(5, 7)]
	for pos in positions:
		screen.board_state.set_gem(pos.x, pos.y, GemInstance_.new("red"))
	screen.update_all_views()

	await screen.resolve_board(false)

	var coated_count = 0
	for x in range(screen.board_state.width):
		for y in range(screen.board_state.height):
			var gem = screen.board_state.get_gem(x, y)
			if gem != null and gem.coat_ids.size() > 0:
				coated_count += 1
				_assert_true(gem.coat_ids.has("rocket_v") or gem.coat_ids.has("rocket_h"), "4-clear should create a rocket gem")
	_assert_eq(coated_count, 1, "generated special gem should remain on board after its creation step")
	screen.free()
	await process_frame

func _test_no_special_spawn_without_relic() -> void:
	var screen = await _create_stage_screen()
	_clear_board(screen)
	var positions = [Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7), Vector2i(5, 7)]
	for pos in positions:
		screen.board_state.set_gem(pos.x, pos.y, GemInstance_.new("red"))
	screen.update_all_views()

	await screen.resolve_board(false)

	var coated_count = 0
	for x in range(screen.board_state.width):
		for y in range(screen.board_state.height):
			var gem = screen.board_state.get_gem(x, y)
			if gem != null and gem.coat_ids.size() > 0:
				coated_count += 1
	_assert_eq(coated_count, 0, "4-clear should not create a special gem without the matching relic")
	screen.free()
	await process_frame

func _test_special_gem_triggers_on_next_chain() -> void:
	var board = BoardState_.new(7, 7)
	var bomb_gem = GemInstance_.new("red")
	bomb_gem.add_coat("bomb")
	board.set_gem(3, 3, bomb_gem)

	var effect_positions = MatchResolver_.find_effect_positions(board, [Vector2i(3, 3)])
	var expected_clears = [Vector2i(3, 3), Vector2i(2, 3), Vector2i(4, 3), Vector2i(3, 2), Vector2i(3, 4)]
	for pos in expected_clears:
		_assert_true(pos in effect_positions, "bomb gem should include cross cell %s" % str(pos))
	var diagonal_survivors = [Vector2i(2, 2), Vector2i(4, 2), Vector2i(2, 4), Vector2i(4, 4)]
	for pos in diagonal_survivors:
		_assert_true(not (pos in effect_positions), "bomb gem should not include diagonal cell %s" % str(pos))

func _test_beam_spawn_requires_prism_secret() -> void:
	var screen = await _create_stage_screen()
	screen.run_state.add_relic("relic_prism_secret")
	_clear_board(screen)
	var positions = [Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7), Vector2i(5, 7)]
	for pos in positions:
		screen.board_state.set_gem(pos.x, pos.y, GemInstance_.new("purple"))
	screen.update_all_views()

	await screen.resolve_board(false)

	var beam_count = 0
	for x in range(screen.board_state.width):
		for y in range(screen.board_state.height):
			var gem = screen.board_state.get_gem(x, y)
			if gem != null and gem.coat_ids.has("beam"):
				beam_count += 1
	_assert_eq(beam_count, 1, "5-clear should create a beam gem only with Prism Secret")
	screen.free()
	await process_frame

func _test_beam_range_relic_extends_diagonal_clear() -> void:
	var board = BoardState_.new(7, 7)
	var beam_gem = GemInstance_.new("purple")
	beam_gem.add_coat("beam")
	board.set_gem(3, 3, beam_gem)

	var base_effects = MatchResolver_.find_effect_positions(board, [Vector2i(3, 3)])
	var relic_effects = MatchResolver_.find_effect_positions(board, [Vector2i(3, 3)], ["relic_beam_range"])

	_assert_true(Vector2i(1, 1) in base_effects, "base beam should reach 2 tiles diagonally")
	_assert_true(not (Vector2i(0, 0) in base_effects), "base beam should stop before 3 tiles diagonally")
	_assert_true(Vector2i(0, 0) in relic_effects, "beam range relic should extend diagonal clear by 1")

func _test_rocket_range_relic_extends_line_clear() -> void:
	var board = BoardState_.new(9, 9)
	var rocket_gem = GemInstance_.new("red")
	rocket_gem.add_coat("rocket_v")
	board.set_gem(4, 4, rocket_gem)

	var base_effects = MatchResolver_.find_effect_positions(board, [Vector2i(4, 4)])
	var relic_effects = MatchResolver_.find_effect_positions(board, [Vector2i(4, 4)], ["relic_rocket_range"])

	_assert_true(Vector2i(4, 1) in base_effects, "base rocket should reach 3 tiles vertically")
	_assert_true(not (Vector2i(4, 0) in base_effects), "base rocket should stop before 4 tiles vertically")
	_assert_true(Vector2i(4, 0) in relic_effects, "rocket range relic should extend vertical clear by 1")

func _test_bomb_diagonal_relic_adds_corner_cells() -> void:
	var board = BoardState_.new(5, 5)
	var bomb_gem = GemInstance_.new("yellow")
	bomb_gem.add_coat("bomb")
	board.set_gem(2, 2, bomb_gem)

	var base_effects = MatchResolver_.find_effect_positions(board, [Vector2i(2, 2)])
	var relic_effects = MatchResolver_.find_effect_positions(board, [Vector2i(2, 2)], ["relic_bomb_diagonal"])

	_assert_true(not (Vector2i(1, 1) in base_effects), "base bomb should not hit diagonals")
	_assert_true(Vector2i(1, 1) in relic_effects, "bomb diagonal relic should include diagonal cells")
	_assert_true(Vector2i(3, 3) in relic_effects, "bomb diagonal relic should include the opposite diagonal")

func _test_move_into_empty_is_blocked() -> void:
	var screen = await _create_stage_screen()
	_clear_board(screen)

	screen.board_state.set_gem(1, 4, GemInstance_.new("red"))
	screen.board_state.set_gem(2, 4, GemInstance_.new("red"))
	screen.board_state.set_gem(4, 4, GemInstance_.new("red"))
	screen.update_all_views()

	await screen.try_swap(Vector2i(4, 4), Vector2i(3, 4))

	_assert_true(screen.board_state.get_gem(3, 4) == null, "moving into an empty cell should be blocked")
	_assert_true(screen.board_state.get_gem(4, 4) != null, "source gem should remain in place")
	_assert_true(screen.board_state.get_gem(1, 4) != null, "blocked move should not clear existing gems")
	_assert_true(screen.board_state.get_gem(2, 4) != null, "blocked move should not create a match")
	screen.free()
	await process_frame

func _cleanup() -> void:
	for child in root.get_children():
		child.free()
	await process_frame

func _create_stage_screen() -> Variant:
	var scene = load("res://scenes/screens/stage_play_screen.tscn")
	var screen = scene.instantiate()
	root.add_child(screen)
	await process_frame

	var run_state = RunState_.new()
	run_state.board_width = 8
	run_state.board_height = 8
	var deck_state = DeckState_.new([])
	var stage_plan = StageMaster_.create_plan(0)
	screen.initialize_stage(run_state, deck_state, stage_plan)
	await process_frame
	return screen

func _clear_board(screen) -> void:
	for y in range(screen.board_state.height):
		for x in range(screen.board_state.width):
			screen.board_state.set_gem(x, y, null)
	screen.setup_board_views()
	screen.update_all_views()

func _assert_eq(actual, expected, label: String) -> void:
	assertions += 1
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [label, str(expected), str(actual)])

func _assert_true(value: bool, label: String) -> void:
	assertions += 1
	if not value:
		failures.append("%s | expected true" % label)
