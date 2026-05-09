extends Control

signal restart_requested()

@onready var title_label: Label = $MarginContainer/VBox/Title
@onready var reched_label: Label = $MarginContainer/VBox/ReachedLabel
@onready var stats_grid: GridContainer = $MarginContainer/VBox/StatsGrid
@onready var deck_summary: Label = $MarginContainer/VBox/DeckSummary
@onready var relic_summary: Label = $MarginContainer/VBox/RelicSummary
@onready var restart_button: Button = $MarginContainer/VBox/RestartButton

func _ready() -> void:
	if get_tree().current_scene == self:
		var mock_run = RunState.new()
		mock_run.stage_index = 5
		mock_run.total_score = 125000
		mock_run.total_gems_cleared = 850
		mock_run.total_gold_earned = 150
		mock_run.max_chain = 12
		mock_run.largest_clear = 18
		var mock_relics: Array[String] = ["relic_mining", "relic_chain"]
		mock_run.relic_ids = mock_relics
		for i in range(20): mock_run.master_deck.append(GemInstance.new("red"))
		initialize_result(mock_run)

func initialize_result(run: Object) -> void:
	if run.stage_index >= run.max_stages:
		title_label.text = "RUN CLEAR!"
		title_label.add_theme_color_override("font_color", Color.GOLD)
		reched_label.text = "Congratulations! You conquered the mines."
	else:
		title_label.text = "RUN FINISHED"
		reched_label.text = "Reached Stage %s" % run.get_current_stage_name()
	
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
