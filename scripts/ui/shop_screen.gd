extends Control

signal shop_finished()
signal remove_gem_requested()
signal view_deck_requested()

const RunState_ = preload("res://scripts/domain/run_state.gd")
const GemInstance_ = preload("res://scripts/domain/gem_instance.gd")
const StageMaster_ = preload("res://scripts/domain/stage_master.gd")
const GemTextureManager_ = preload("res://scripts/ui/gem_texture_manager.gd")
const ShopGenerator_ = preload("res://scripts/domain/shop_generator.gd")
const DescriptionService_ = preload("res://scripts/domain/description_service.gd")

@onready var gold_label: Label = $MarginContainer/VBox/GoldLabel
@onready var next_stage_info: Label = $MarginContainer/VBox/NextStageInfo
@onready var next_button: Button = $MarginContainer/VBox/NextButton
@onready var items_container: HBoxContainer = $MarginContainer/VBox/ItemsContainer

@onready var detail_overlay: ColorRect = $ItemDetailOverlay
@onready var detail_name: Label = $ItemDetailOverlay/Panel/VBox/NameLabel
@onready var detail_icon: TextureRect = $ItemDetailOverlay/Panel/VBox/IconRect
@onready var detail_desc: Label = $ItemDetailOverlay/Panel/VBox/DescLabel
@onready var detail_price: Label = $ItemDetailOverlay/Panel/VBox/PriceLabel
@onready var detail_buy_btn: Button = $ItemDetailOverlay/Panel/VBox/Buttons/DetailBuyButton
@onready var detail_close_btn: Button = $ItemDetailOverlay/Panel/VBox/Buttons/CloseButton

# New service buttons
var reroll_button: Button
var remove_gem_button: Button
var view_deck_button: Button

var run_state
var current_inventory: Array[Dictionary] = []
var reroll_cost: int = 3
var remove_gem_cost: int = 8

func _ready() -> void:
	next_button.pressed.connect(_on_next_button_pressed)
	detail_close_btn.pressed.connect(func(): detail_overlay.visible = false)
	
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
	
	view_deck_button = Button.new()
	view_deck_button.text = "View Deck"
	view_deck_button.custom_minimum_size = Vector2(200, 60)
	view_deck_button.add_theme_font_size_override("font_size", 24)
	view_deck_button.pressed.connect(_on_view_deck_pressed)
	service_hbox.add_child(view_deck_button)
	
	remove_gem_button = Button.new()
	remove_gem_button.text = "Remove Gem: %dG" % remove_gem_cost
	remove_gem_button.custom_minimum_size = Vector2(250, 60)
	remove_gem_button.add_theme_font_size_override("font_size", 24)
	remove_gem_button.pressed.connect(_on_remove_gem_pressed)
	service_hbox.add_child(remove_gem_button)

	if get_tree().current_scene == self:
		var mock_run = RunState_.new()
		var mock_plan = StageMaster_.create_plan(1)
		var mock_inv = ShopGenerator_.generate_shop_inventory(1, mock_run.relic_ids)
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
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.gui_input.connect(_on_item_panel_input.bind(item, price))
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
		
		# Set texture
		if item.type == "special_gem" or item.type == "coated_gem":
			var effect_id = item.get("effect", item.get("coat", ""))
			tex_rect.texture = GemTextureManager_.get_gem_texture(item.color)
			if effect_id != "":
				var overlay = TextureRect.new()
				overlay.texture = GemTextureManager_.get_effect_texture(effect_id)
				overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_rect.add_child(overlay)
		elif item.type == "relic":
			tex_rect.texture = GemTextureManager_.get_relic_texture(item.id)
		
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
		
		panel.tooltip_text = DescriptionService_.get_item_description(item)
		items_container.add_child(panel)
	
	update_relics()

func update_relics() -> void:
	var main_vbox = $MarginContainer/VBox
	var relics_container = main_vbox.get_node_or_null("RelicsContainer")
	if not relics_container:
		relics_container = HBoxContainer.new()
		relics_container.name = "RelicsContainer"
		relics_container.alignment = BoxContainer.ALIGNMENT_CENTER
		relics_container.add_theme_constant_override("separation", 15)
		main_vbox.add_child(relics_container)
		main_vbox.move_child(relics_container, 3) # After gold label
	
	for child in relics_container.get_children():
		child.queue_free()
		
	for relic_id in run_state.relic_ids:
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(48, 48)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture = GemTextureManager_.get_relic_texture(relic_id)
		tex_rect.tooltip_text = DescriptionService_.get_relic_description(relic_id)
		relics_container.add_child(tex_rect)

func _on_item_panel_input(event: InputEvent, item: Dictionary, price: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_item_detail(item, price)

func _show_item_detail(item: Dictionary, price: int) -> void:
	detail_name.text = item.name
	detail_desc.text = DescriptionService_.get_item_description(item)
	detail_price.text = "Cost: %dG" % price
	
	# Icon Setup
	for child in detail_icon.get_children(): child.queue_free()
	if item.type == "special_gem" or item.type == "coated_gem":
		var effect_id = item.get("effect", item.get("coat", ""))
		detail_icon.texture = GemTextureManager_.get_gem_texture(item.color)
		if effect_id != "":
			var overlay = TextureRect.new()
			overlay.texture = GemTextureManager_.get_effect_texture(effect_id)
			overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			detail_icon.add_child(overlay)
	elif item.type == "relic":
		detail_icon.texture = GemTextureManager_.get_relic_texture(item.id)
	else:
		detail_icon.texture = null
		
	detail_buy_btn.disabled = run_state.gold < price
	for connection in detail_buy_btn.pressed.get_connections():
		detail_buy_btn.pressed.disconnect(connection.callable)
		
	detail_buy_btn.pressed.connect(func():
		_on_buy_pressed(item, price)
		detail_overlay.visible = false
	)
	
	detail_overlay.visible = true

func _on_buy_pressed(item: Dictionary, price: int) -> void:
	if run_state.gold >= price:
		run_state.gold -= price
		apply_purchase(item)
		current_inventory.erase(item)
		update_ui(StageMaster_.create_plan(run_state.stage_index))

func apply_purchase(item: Dictionary) -> void:
	match item.type:
		"special_gem":
			var gem = GemInstance_.new(item.color)
			gem.add_coat(item.effect)
			run_state.master_deck.append(gem)
		"relic":
			run_state.add_relic(item.id)
		"coated_gem":
			var gem = GemInstance_.new(item.color)
			gem.add_coat(item.coat)
			run_state.master_deck.append(gem)
		"consumable":
			print("Purchased item: %s" % item.id)

func _on_reroll_pressed() -> void:
	if run_state.gold >= reroll_cost:
		run_state.gold -= reroll_cost
		current_inventory = ShopGenerator_.generate_shop_inventory(run_state.stage_index, run_state.relic_ids)
		reroll_cost += 1
		update_ui(StageMaster_.create_plan(run_state.stage_index))

func _on_remove_gem_pressed() -> void:
	if run_state.gold >= remove_gem_cost:
		remove_gem_requested.emit()
		run_state.gold -= remove_gem_cost
		remove_gem_cost += 2

func _on_view_deck_pressed() -> void:
	view_deck_requested.emit()

func _on_next_button_pressed() -> void:
	shop_finished.emit()
