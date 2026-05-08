extends Control

@onready var board_view: GridContainer = $VBox/MainLayout/BoardArea/BoardView
const GEM_VIEW_SCENE = preload("res://scenes/components/gem_view.tscn")

func _ready() -> void:
	populate_placeholder_board()

func populate_placeholder_board() -> void:
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.PURPLE]
	for i in range(64):
		var gem = GEM_VIEW_SCENE.instantiate()
		board_view.add_child(gem)
		gem.set_gem_color(colors[i % colors.size()])
