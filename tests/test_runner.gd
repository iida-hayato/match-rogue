extends SceneTree

const BoardState_ = preload("res://scripts/domain/board_state.gd")
const DeckState_ = preload("res://scripts/domain/deck_state.gd")
const GemInstance_ = preload("res://scripts/domain/gem_instance.gd")
const MatchResolver_ = preload("res://scripts/domain/match_resolver.gd")
const ShopGenerator_ = preload("res://scripts/domain/shop_generator.gd")
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
	await _test_line5_relic_priority_beats_line4_when_both_present()
	await _test_l_shape_triggers_bomb_relic()
	await _test_shop_generates_two_relics()
	await _test_beam_range_relic_extends_diagonal_clear()
	await _test_rocket_range_relic_extends_line_clear()
	await _test_bomb_diagonal_relic_adds_corner_cells()
	await _test_no_reshuffle_relic_blocks_discard_return()
	await _test_auto_drop_relic_does_not_auto_refill_without_relic()
	await _test_auto_drop_relic_refills_without_consuming_charge()
	await _test_auto_drop_relic_waits_for_draw_pile_then_ends()
	await _test_auto_drop_relic_ends_when_board_is_full_and_moves_zero()
	await _test_end_run_waits_during_resolution()
	await _test_gem_visual_size_shrinks_on_large_board()
	await _test_debug_helpers_can_force_relic_and_single_color()
	await _test_debug_enable_auto_drop_seal_helper()
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

func _test_line5_relic_priority_beats_line4_when_both_present() -> void:
	var screen = await _create_stage_screen()
	screen.run_state.add_relic("relic_rocket_workshop")
	screen.run_state.add_relic("relic_prism_secret")
	_clear_board(screen)
	var positions = [Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7), Vector2i(5, 7)]
	for pos in positions:
		screen.board_state.set_gem(pos.x, pos.y, GemInstance_.new("purple"))
	screen.update_all_views()

	await screen.resolve_board(false)

	var beam_count = 0
	var rocket_count = 0
	for x in range(screen.board_state.width):
		for y in range(screen.board_state.height):
			var gem = screen.board_state.get_gem(x, y)
			if gem != null and gem.coat_ids.size() > 0:
				if gem.coat_ids.has("beam"):
					beam_count += 1
				if gem.coat_ids.has("rocket_v") or gem.coat_ids.has("rocket_h"):
					rocket_count += 1
	_assert_eq(beam_count, 1, "5-clear should prefer Prism Secret over Rocket Workshop")
	_assert_eq(rocket_count, 0, "5-clear should not create a rocket when Prism Secret is present")
	screen.free()
	await process_frame

func _test_l_shape_triggers_bomb_relic() -> void:
	var screen = await _create_stage_screen()
	screen.run_state.add_relic("relic_bomb_workshop")
	_clear_board(screen)
	var positions = [Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 1), Vector2i(3, 1)]
	for pos in positions:
		screen.board_state.set_gem(pos.x, pos.y, GemInstance_.new("yellow"))
	screen.update_all_views()

	await screen.resolve_board(false)

	var bomb_count = 0
	for x in range(screen.board_state.width):
		for y in range(screen.board_state.height):
			var gem = screen.board_state.get_gem(x, y)
			if gem != null and gem.coat_ids.has("bomb"):
				bomb_count += 1
	_assert_eq(bomb_count, 1, "L-shape should trigger Bomb Workshop like T-shape")
	screen.free()
	await process_frame

func _test_shop_generates_two_relics() -> void:
	var run_state = RunState_.new()
	run_state.add_relic("relic_mining")
	var inventory = ShopGenerator_.generate_shop_inventory(run_state)
	var relic_ids: Array[String] = []
	for item in inventory:
		if item.type == "relic":
			relic_ids.append(item.id)
	_assert_eq(relic_ids.size(), 2, "shop should generate two relics")
	_assert_true(not relic_ids.has("relic_mining"), "owned relics should be excluded from shop relic pool")
	_assert_true(relic_ids[0] != relic_ids[1], "shop relics should not duplicate in the same inventory")

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

func _test_no_reshuffle_relic_blocks_discard_return() -> void:
	var deck = DeckState_.new([])
	var discarded = GemInstance_.new("blue")
	deck.discard(discarded)
	var first_draw = deck.draw_one(false)
	_assert_true(first_draw == null, "draw_one should return null when reshuffle is disabled and draw pile is empty")
	_assert_eq(deck.discard_pile.size(), 1, "discard should remain untouched when reshuffle is disabled")

func _test_auto_drop_relic_does_not_auto_refill_without_relic() -> void:
	var screen = await _create_stage_screen()
	_clear_board(screen)
	screen.board_state.set_gem(0, 7, GemInstance_.new("red"))
	screen.board_state.set_gem(1, 7, GemInstance_.new("red"))
	screen.board_state.set_gem(2, 7, GemInstance_.new("red"))
	screen.deck_state = DeckState_.new([GemInstance_.new("blue")])
	screen.update_all_views()

	await screen.resolve_board(false)

	_assert_true(screen.run_state.relic_ids.is_empty(), "test setup should not add relics")
	_assert_true(screen.board_state.has_empty_cells(), "without the relic, board should stay partially empty after resolution")
	_assert_eq(screen.deck_state.draw_pile.size(), 1, "without the relic, draw pile should not be consumed by auto drop")
	screen.free()
	await process_frame

func _test_auto_drop_relic_refills_without_consuming_charge() -> void:
	var screen = await _create_stage_screen()
	screen.run_state.add_relic("relic_auto_drop_seal")
	_clear_board(screen)
	screen.deck_state = DeckState_.new([GemInstance_.new("red")])
	screen.stage_state.drop_charges_remaining = 1
	screen.update_hud()

	await screen.resolve_board(false)

	var found_gem := false
	for x in range(screen.board_state.width):
		for y in range(screen.board_state.height):
			if screen.board_state.get_gem(x, y) != null:
				found_gem = true
				break
		if found_gem:
			break
	_assert_true(found_gem, "auto drop should refill at least one empty cell")
	_assert_eq(screen.stage_state.drop_charges_remaining, 1, "auto drop should not consume drop charges")
	screen.free()
	await process_frame

func _test_auto_drop_relic_waits_for_draw_pile_then_ends() -> void:
	var screen = await _create_stage_screen()
	screen.run_state.add_relic("relic_auto_drop_seal")
	screen.stage_state.moves_remaining = 0
	screen.stage_state.drop_charges_remaining = 0
	_clear_board(screen)
	screen.board_state.set_gem(0, 7, GemInstance_.new("red"))
	screen.board_state.set_gem(1, 7, GemInstance_.new("red"))
	screen.board_state.set_gem(2, 7, GemInstance_.new("red"))
	screen.deck_state = DeckState_.new([GemInstance_.new("blue")])
	screen.update_hud()

	_assert_true(not screen._should_end_run(), "auto drop relic should wait while draw pile still has gems")

	screen.deck_state.draw_pile.clear()
	screen.update_hud()
	_assert_true(screen._should_end_run(), "auto drop relic should end once draw pile is empty and moves are exhausted")
	screen.free()
	await process_frame

func _test_auto_drop_relic_ends_when_board_is_full_and_moves_zero() -> void:
	var screen = await _create_stage_screen()
	screen.run_state.add_relic("relic_auto_drop_seal")
	screen.stage_state.moves_remaining = 0
	screen.stage_state.drop_charges_remaining = 0
	screen.deck_state = DeckState_.new([GemInstance_.new("blue")])
	for y in range(screen.board_state.height):
		for x in range(screen.board_state.width):
			screen.board_state.set_gem(x, y, GemInstance_.new("red"))
	screen.update_hud()

	_assert_true(screen._should_end_run(), "auto drop relic should not keep the run alive when the board is already full")
	screen.free()
	await process_frame

func _test_end_run_waits_during_resolution() -> void:
	var screen = await _create_stage_screen()
	screen.stage_state.moves_remaining = 0
	screen.stage_state.drop_charges_remaining = 0
	screen.stage_state.score = 0
	screen.stage_state.target_score = 999

	screen.resolution_in_progress = true
	_assert_true(not screen._should_end_run(), "game over should wait while resolution is in progress")
	screen.resolution_in_progress = false
	_assert_true(screen._should_end_run(), "game over should trigger after resolution ends")
	screen.free()
	await process_frame

func _test_gem_visual_size_shrinks_on_large_board() -> void:
	var screen = await _create_stage_screen()
	screen.run_state.board_width = 12
	screen.run_state.board_height = 12
	screen.board_state = BoardState_.new(12, 12)
	screen.setup_board_views()
	screen.update_all_views()

	var gem = GemInstance_.new("red")
	screen.board_state.set_gem(0, 0, gem)
	screen.update_all_views()

	var view = screen.gem_views[0][0]
	_assert_true(view != null, "large board should still create gem views")
	_assert_true(view.size.x < screen.tile_size, "gem visuals should be smaller than the tile on large boards")
	screen.free()
	await process_frame

func _test_debug_helpers_can_force_relic_and_single_color() -> void:
	var screen = await _create_stage_screen()
	screen.debug_add_relic("relic_auto_drop_seal")
	_assert_true(screen.run_state.relic_ids.has("relic_auto_drop_seal"), "debug relic helper should add relics")

	screen.board_state.set_gem(0, 0, GemInstance_.new("blue"))
	screen.board_state.set_gem(1, 0, GemInstance_.new("green"))
	screen.deck_state = DeckState_.new([GemInstance_.new("purple"), GemInstance_.new("yellow")])
	screen.debug_set_all_gems_to_color("red")

	_assert_eq(screen.board_state.get_gem(0, 0).definition_id, "red", "debug single-color helper should recolor board gems")
	_assert_eq(screen.board_state.get_gem(1, 0).definition_id, "red", "debug single-color helper should recolor all board gems")
	_assert_eq(screen.deck_state.draw_pile[0].definition_id, "red", "debug single-color helper should recolor draw pile gems")
	_assert_eq(screen.deck_state.draw_pile[1].definition_id, "red", "debug single-color helper should recolor draw pile gems")
	screen.free()
	await process_frame

func _test_debug_enable_auto_drop_seal_helper() -> void:
	var screen = await _create_stage_screen()
	screen.debug_enable_auto_drop_seal()
	_assert_true(screen.run_state.relic_ids.has("relic_auto_drop_seal"), "debug auto drop helper should enable the relic")
	_assert_true(screen.drop_button.disabled, "debug auto drop helper should immediately update the HUD state")
	screen.free()
	await process_frame

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
