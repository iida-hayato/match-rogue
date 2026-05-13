extends Control

signal restart_requested()
signal endless_requested()

const RunState_ = preload("res://scripts/domain/run_state.gd")
const GemInstance_ = preload("res://scripts/domain/gem_instance.gd")

@onready var title_label: Label = $MarginContainer/VBox/Title
@onready var reched_label: Label = $MarginContainer/VBox/ReachedLabel
@onready var stats_grid: GridContainer = $MarginContainer/VBox/StatsGrid
@onready var deck_summary: Label = $MarginContainer/VBox/DeckSummary
@onready var relic_summary: Label = $MarginContainer/VBox/RelicSummary
@onready var restart_button: Button = $MarginContainer/VBox/Buttons/RestartButton
@onready var endless_button: Button = $MarginContainer/VBox/Buttons/EndlessButton

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	endless_button.pressed.connect(_on_endless_pressed)
	if get_tree().current_scene == self:
		var mock_run = RunState_.new()
		mock_run.stage_index = 14
		mock_run.total_score = 250000
		mock_run.total_gems_cleared = 1200
		mock_run.total_gold_earned = 300
		mock_run.max_chain = 15
		mock_run.largest_clear = 24
		var mock_relics: Array[String] = ["relic_mining", "relic_chain"]
		mock_run.relic_ids = mock_relics
		for i in range(60): mock_run.master_deck.append(GemInstance_.new("red"))
		initialize_result(mock_run)


func initialize_result(run: Object) -> void:
	if run.stage_index >= run.max_stages:
		title_label.text = "RUN CLEAR!"
		title_label.add_theme_color_override("font_color", Color.GOLD)
		reched_label.text = "Congratulations! You conquered the mines."
		endless_button.visible = !run.is_endless
	else:
		title_label.text = "RUN FINISHED"
		reched_label.text = "Reached Stage %s" % run.format_stage_progress(run.stage_index)
		endless_button.visible = false
	
	_set_stat("Total Score", str(run.total_score))
	_set_stat("Gems Cleared", str(run.total_gems_cleared))
	_set_stat("Gold Earned", str(run.total_gold_earned))
	_set_stat("Max Combo", str(run.max_chain))
	_set_stat("Largest Match", str(run.largest_clear))
	
	# Deck Summary
	var deck_counts = {}
	for gem in run.master_deck:
		deck_counts[gem.definition_id] = deck_counts.get(gem.definition_id, 0) + 1
	
	var deck_text = "Final Deck: "
	var parts = []
	for color in deck_counts:
		parts.append("%s x%d" % [color.capitalize(), deck_counts[color]])
	deck_summary.text = deck_text + ", ".join(parts)
	
	# Relics
	if run.relic_ids.size() > 0:
		relic_summary.text = "Relics: " + ", ".join(run.relic_ids)
	else:
		relic_summary.text = "Relics: None"

func _set_stat(label_text: String, value_text: String) -> void:
	var label = Label.new()
	label.text = label_text + ":"
	label.add_theme_font_size_override("font_size", 24)
	
	var val = Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", 28)
	val.add_theme_color_override("font_color", Color.YELLOW)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	stats_grid.add_child(label)
	stats_grid.add_child(val)

func _on_restart_pressed() -> void:
	restart_requested.emit()

func _on_endless_pressed() -> void:
	endless_requested.emit()
