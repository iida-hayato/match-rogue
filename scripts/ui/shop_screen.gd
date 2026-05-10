extends Control

signal shop_finished()
signal remove_gem_requested()

@onready var gold_label: Label = $MarginContainer/VBox/GoldLabel
@onready var next_stage_info: Label = $MarginContainer/VBox/NextStageInfo
@onready var next_button: Button = $MarginContainer/VBox/NextButton
@onready var items_container: HBoxContainer = $MarginContainer/VBox/ItemsContainer

# New service buttons
var reroll_button: Button
var remove_gem_button: Button

var run_state
var current_inventory: Array[Dictionary] = []
var reroll_cost: int = 3
var remove_gem_cost: int = 8

func _ready() -> void:
	next_button.pressed.connect(_on_next_button_pressed)
	
	# Create service UI
	var main_vbox = $MarginContainer/VBox
	var service_hbox = HBoxContainer.new()
	service_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	service_hbox.add_theme_constant_override("separation", 40)
	main_vbox.add_child(service_hbox)
	main_vbox.move_child(service_hbox, 4) # Insert before next stage info
	
	reroll_button = Button.new()
	reroll_button.text = "Reroll: %dG" % reroll_cost
	reroll_button.custom_minimum_size = Vector2(200, 60)
	reroll_button.add_theme_font_size_override("font_size", 24)
	reroll_button.pressed.connect(_on_reroll_pressed)
	service_hbox.add_child(reroll_button)
	
	remove_gem_button = Button.new()
	remove_gem_button.text = "Remove Gem: %dG" % remove_gem_cost
	remove_gem_button.custom_minimum_size = Vector2(250, 60)
	remove_gem_button.add_theme_font_size_override("font_size", 24)
	remove_gem_button.pressed.connect(_on_remove_gem_pressed)
	service_hbox.add_child(remove_gem_button)

	if get_tree().current_scene == self:
		var mock_run = RunState.new()
		var mock_plan = StageMaster.create_plan(1)
		var mock_inv = ShopGenerator.generate_shop_inventory(1)
		initialize_shop(mock_run, mock_plan, mock_inv)

func initialize_shop(run: Object, next_plan: Object, inventory: Array[Dictionary]) -> void:
	run_state = run
	current_inventory = inventory
	update_ui(next_plan)

func update_ui(next_plan: Object) -> void:
	gold_label.text = "Gold: %d" % run_state.gold
	
	var obstacle_text = ""
	if next_plan.obstacle_rate > 0:
		obstacle_text = " (Obstacle: Stone Gem %d%%)" % int(next_plan.obstacle_rate * 100)
	
	next_stage_info.text = "Next Stage: %s (Target: %d)%s" % [
		run_state.get_current_stage_name(),
		next_plan.target_score,
		obstacle_text
	]
	
	reroll_button.text = "Reroll: %dG" % reroll_cost
	reroll_button.disabled = run_state.gold < reroll_cost
	
	remove_gem_button.text = "Remove Gem: %dG" % remove_gem_cost
	remove_gem_button.disabled = run_state.gold < remove_gem_cost or run_state.master_deck.size() <= 0
	
	# Clear and rebuild inventory
	for child in items_container.get_children():
		child.queue_free()
	
	for item in current_inventory:
		var price = item.price
		if run_state.relic_ids.has("relic_shop"):
			price = int(price * 0.85) # 15% discount
		
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(200, 260)
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 5)
		panel.add_child(vbox)
		
		# Item Texture
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(60, 60)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.add_child(tex_rect)
		
		# Set texture based on item type
		if item.type == "special_gem" or item.type == "coated_gem":
			var effect_id = item.get("effect", item.get("coat", ""))
			tex_rect.texture = GemTextureManager.get_gem_texture(item.color)
			
			if effect_id != "":
				var overlay = TextureRect.new()
				overlay.texture = GemTextureManager.get_effect_texture(effect_id)
				overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_rect.add_child(overlay)
		elif item.type == "relic":
			tex_rect.texture = GemTextureManager.get_relic_texture(item.id)
		elif item.type == "consumable":
			# Placeholder color/rect for consumables if no SVG yet
			tex_rect.self_modulate = Color.WHITE
		
		var name_label = Label.new()
		name_label.text = item.name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(name_label)
		
		var price_label = Label.new()
		price_label.text = "%dG" % price
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_label.add_theme_font_size_override("font_size", 28)
		price_label.add_theme_color_override("font_color", Color.YELLOW)
		vbox.add_child(price_label)
		
		var buy_btn = Button.new()
		buy_btn.text = "BUY"
		buy_btn.custom_minimum_size = Vector2(0, 50)
		buy_btn.add_theme_font_size_override("font_size", 20)
		buy_btn.disabled = run_state.gold < price
		buy_btn.pressed.connect(_on_buy_pressed.bind(item, price))
		vbox.add_child(buy_btn)
		
		panel.tooltip_text = _get_item_description(item)
		items_container.add_child(panel)

func _get_item_description(item: Dictionary) -> String:
	match item.get("effect", item.get("coat", item.id)):
		"rocket_v": return "Clears vertical column when matched."
		"rocket_h": return "Clears horizontal row when matched."
		"bomb": return "Clears surrounding 3x3 area when matched."
		"beam": return "Clears diagonal X-shape when matched."
		"coin": return "Earn +1 Gold when matched."
		"gold": return "Earn +1 Gold when matched."
		"score": return "Grants significant score bonus."
		"relic_mining": return "Mining Emblem: Clear 6+ gems to get huge bonus multipliers."
		"relic_chain": return "Chain Gear: Increases chain multiplier bonus per step."
		"relic_shop": return "Member Card: 15% discount on all shop items."
		"item_hammer": return "Hammer: Click a gem to clear it immediately."
		"item_shuffle": return "Shuffle: Reshuffles the board state."
	return "No description available."

func _on_buy_pressed(item: Dictionary, price: int) -> void:
	if run_state.gold >= price:
		run_state.gold -= price
		apply_purchase(item)
		current_inventory.erase(item)
		update_ui(StageMaster.create_plan(run_state.stage_index))

func apply_purchase(item: Dictionary) -> void:
	match item.type:
		"special_gem":
			var gem = GemInstance.new(item.color)
			gem.add_coat(item.effect)
			run_state.master_deck.append(gem)
		"relic":
			run_state.add_relic(item.id)
		"coated_gem":
			var gem = GemInstance.new(item.color)
			gem.add_coat(item.coat)
			run_state.master_deck.append(gem)
		"consumable":
			print("Purchased item: %s" % item.id)

func _on_reroll_pressed() -> void:
	if run_state.gold >= reroll_cost:
		run_state.gold -= reroll_cost
		current_inventory = ShopGenerator.generate_shop_inventory(run_state.stage_index)
		reroll_cost += 1
		update_ui(StageMaster.create_plan(run_state.stage_index))

func _on_remove_gem_pressed() -> void:
	if run_state.gold >= remove_gem_cost:
		remove_gem_requested.emit()
		run_state.gold -= remove_gem_cost
		remove_gem_cost += 2

func _on_next_button_pressed() -> void:
	shop_finished.emit()
