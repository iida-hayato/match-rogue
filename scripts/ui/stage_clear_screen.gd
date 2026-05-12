extends Control

signal continue_requested()

const StageState = preload("res://scripts/domain/stage_state.gd")

@onready var title_label: Label = $MarginContainer/VBox/Title
@onready var score_label: Label = $MarginContainer/VBox/Stats/ScoreLabel
@onready var moves_label: Label = $MarginContainer/VBox/Stats/MovesLabel
@onready var gold_total_label: Label = $MarginContainer/VBox/GoldInfo/TotalLabel
@onready var breakdown_container: VBoxContainer = $MarginContainer/VBox/GoldInfo/Breakdown

func _ready() -> void:
	if get_tree().current_scene == self:
		var mock_state = StageState.new()
		mock_state.score = 1200
		mock_state.moves_remaining = 5
		initialize("1-1", mock_state, 1000, {
			"total": 15,
			"clear_bonus": 8,
			"moves_bonus": 5,
			"over_score_bonus": 2,
			"coin_gem_bonus": 0
		})

func initialize(stage_name: String, stage_state: Object, target_score: int, gold_breakdown: Dictionary) -> void:
	title_label.text = "Stage %s Clear" % stage_name
	score_label.text = "Score: %d / %d" % [stage_state.score, target_score]
	moves_label.text = "Moves Left: %d" % stage_state.moves_remaining
	
	gold_total_label.text = "Gold Earned: %d" % gold_breakdown.total
	
	for child in breakdown_container.get_children():
		child.queue_free()
	
	_add_breakdown_item("Clear Bonus", gold_breakdown.clear_bonus)
	_add_breakdown_item("Moves Bonus", gold_breakdown.moves_bonus)
	_add_breakdown_item("Over Score Bonus", gold_breakdown.over_score_bonus)
	
	if gold_breakdown.get("coin_gem_bonus", 0) > 0:
		_add_breakdown_item("Coin Gem Bonus", gold_breakdown.coin_gem_bonus)

func _add_breakdown_item(label_text: String, value: int) -> void:
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = "- %s: " % label_text
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var val_label = Label.new()
	val_label.text = str(value)
	
	hbox.add_child(label)
	hbox.add_child(val_label)
	breakdown_container.add_child(hbox)

func _on_continue_pressed() -> void:
	continue_requested.emit()
