extends Control

@onready var board_view: GridContainer = $VBox/MainLayout/BoardArea/BoardView
const GEM_VIEW_SCENE = preload("res://scenes/components/gem_view.tscn")

const BoardState = preload("res://scripts/domain/board_state.gd")
const MatchResolver = preload("res://scripts/domain/match_resolver.gd")
const CascadeResolver = preload("res://scripts/domain/cascade_resolver.gd")
const GemInstance = preload("res://scripts/domain/gem_instance.gd")

var board_state
var gem_views = [] # 2D array [y][x]
var selected_pos = null

var gem_definitions: Array[String] = ["red", "blue", "green", "yellow", "purple"]
var color_map = {
	"red": Color.RED,
	"blue": Color.BLUE,
	"green": Color.GREEN,
	"yellow": Color.YELLOW,
	"purple": Color.PURPLE
}

func _ready() -> void:
	board_state = BoardState.new(8, 8)
	setup_board_views()
	initial_refill()

func setup_board_views() -> void:
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
	print("Starting initial refill...")
	# Refill until no matches
	while true:
		CascadeResolver.refill_random(board_state, gem_definitions)
		var matches = MatchResolver.find_matches(board_state)
		if matches.size() == 0:
			break
		# Clear matches and repeat (simple initial setup)
		for m in matches:
			for pos in m:
				board_state.set_gem(pos.x, pos.y, null)
	update_all_views()
	print("Initial refill complete.")

func update_all_views() -> void:
	for y in range(8):
		for x in range(8):
			update_gem_view(x, y)

func update_gem_view(x: int, y: int) -> void:
	var gem = board_state.get_gem(x, y)
	var view = gem_views[y][x]
	if gem:
		view.set_gem_color(color_map[gem.definition_id])
		view.visible = true
	else:
		view.visible = false

func _on_gem_clicked(pos: Vector2i) -> void:
	if selected_pos == null:
		selected_pos = pos
		gem_views[pos.y][pos.x].set_highlight(true)
	else:
		if is_adjacent(selected_pos, pos):
			try_swap(selected_pos, pos)
			gem_views[selected_pos.y][selected_pos.x].set_highlight(false)
			selected_pos = null
		else:
			gem_views[selected_pos.y][selected_pos.x].set_highlight(false)
			selected_pos = pos
			gem_views[pos.y][pos.x].set_highlight(true)

func is_adjacent(p1: Vector2i, p2: Vector2i) -> bool:
	return (abs(p1.x - p2.x) == 1 and p1.y == p2.y) or (abs(p1.y - p2.y) == 1 and p1.x == p2.x)

func try_swap(p1: Vector2i, p2: Vector2i) -> void:
	board_state.swap_gems(p1.x, p1.y, p2.x, p2.y)
	var matches = MatchResolver.find_matches(board_state)
	if matches.size() > 0:
		# Valid swap
		resolve_board()
	else:
		# Invalid swap, revert
		board_state.swap_gems(p1.x, p1.y, p2.x, p2.y)
		update_gem_view(p1.x, p1.y)
		update_gem_view(p2.x, p2.y)

func resolve_board() -> void:
	while true:
		var matches = MatchResolver.find_matches(board_state)
		if matches.size() == 0:
			break
		
		# Clear gems
		for m in matches:
			for pos in m:
				board_state.set_gem(pos.x, pos.y, null)
		
		update_all_views()
		# await get_tree().create_timer(0.2).timeout # For animation later
		
		CascadeResolver.apply_gravity(board_state)
		update_all_views()
		# await get_tree().create_timer(0.2).timeout
		
		CascadeResolver.refill_random(board_state, gem_definitions)
		update_all_views()
		# await get_tree().create_timer(0.2).timeout
