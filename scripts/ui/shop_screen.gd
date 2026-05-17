extends Control

signal shop_finished()
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
@onready var items_container: GridContainer = $MarginContainer/VBox/ItemsContainer

@onready var detail_overlay: ColorRect = $ItemDetailOverlay
@onready var detail_name: Label = $ItemDetailOverlay/Panel/VBox/NameLabel
@onready var detail_icon: TextureRect = $ItemDetailOverlay/Panel/VBox/IconRect
@onready var detail_desc: Label = $ItemDetailOverlay/Panel/VBox/DescLabel
@onready var detail_price: Label = $ItemDetailOverlay/Panel/VBox/PriceLabel
@onready var detail_buy_btn: Button = $ItemDetailOverlay/Panel/VBox/Buttons/DetailBuyButton
@onready var detail_close_btn: Button = $ItemDetailOverlay/Panel/VBox/Buttons/CloseButton

# New service buttons
var reroll_button: Button
var view_deck_button: Button
var shop_relics_container: GridContainer

var run_state
var next_stage_plan
var current_inventory: Array[Dictionary] = []
var reroll_cost: int = 3

func _ready() -> void:
	next_button.pressed.connect(_on_next_button_pressed)
	detail_close_btn.pressed.connect(func(): detail_overlay.visible = false)

	_build_shop_layout()
	_build_service_ui()

	if get_tree().current_scene == self:
		var mock_run = RunState_.new()
		var mock_plan = StageMaster_.create_plan(1)
		var mock_inv = ShopGenerator_.generate_shop_inventory(mock_run)
		initialize_shop(mock_run, mock_plan, mock_inv)

func _build_shop_layout() -> void:
	var main_vbox = $MarginContainer/VBox
	var main_layout = HBoxContainer.new()
	main_layout.name = "MainLayout"
	main_layout.size_flags_horizontal = SIZE_EXPAND_FILL
	main_layout.size_flags_vertical = SIZE_EXPAND_FILL
	main_layout.add_theme_constant_override("separation", 24)
	main_vbox.add_child(main_layout)
	main_vbox.move_child(main_layout, 2)

	var items_column = VBoxContainer.new()
	items_column.size_flags_horizontal = SIZE_EXPAND_FILL
	items_column.size_flags_vertical = SIZE_EXPAND_FILL
	main_layout.add_child(items_column)

	var sidebar = VBoxContainer.new()
	sidebar.name = "Sidebar"
	sidebar.custom_minimum_size = Vector2(260, 0)
	sidebar.add_theme_constant_override("separation", 14)
	main_layout.add_child(sidebar)

	main_vbox.remove_child(items_container)
	items_column.add_child(items_container)
	items_container.size_flags_horizontal = SIZE_EXPAND_FILL

	main_vbox.remove_child(next_stage_info)
	sidebar.add_child(next_stage_info)
	next_stage_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	var relics_label = Label.new()
	relics_label.text = "Relics"
	relics_label.add_theme_font_size_override("font_size", 22)
	sidebar.add_child(relics_label)

	shop_relics_container = GridContainer.new()
	shop_relics_container.columns = 3
	shop_relics_container.add_theme_constant_override("h_separation", 10)
	shop_relics_container.add_theme_constant_override("v_separation", 10)
	sidebar.add_child(shop_relics_container)

	var spacer = Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	sidebar.add_child(spacer)

	main_vbox.remove_child(next_button)
	sidebar.add_child(next_button)
	next_button.size_flags_horizontal = SIZE_EXPAND_FILL
	next_button.custom_minimum_size = Vector2(0, 54)

func _build_service_ui() -> void:
	var sidebar = $MarginContainer/VBox/MainLayout/Sidebar

	reroll_button = Button.new()
	reroll_button.text = "Reroll: %dG" % reroll_cost
	reroll_button.custom_minimum_size = Vector2(170, 48)
	reroll_button.add_theme_font_size_override("font_size", 20)
	reroll_button.pressed.connect(_on_reroll_pressed)
	sidebar.add_child(reroll_button)
	sidebar.move_child(reroll_button, 1)
	
	view_deck_button = Button.new()
	view_deck_button.text = "View Deck"
	view_deck_button.custom_minimum_size = Vector2(170, 48)
	view_deck_button.add_theme_font_size_override("font_size", 20)
	view_deck_button.pressed.connect(_on_view_deck_pressed)
	sidebar.add_child(view_deck_button)
	sidebar.move_child(view_deck_button, 2)

func initialize_shop(run: Object, next_plan: Object, inventory: Array[Dictionary]) -> void:
	run_state = run
	next_stage_plan = next_plan
	current_inventory = inventory
	update_ui(next_plan)

func update_ui(next_plan: Object) -> void:
	gold_label.text = "Gold: %d" % run_state.gold
	
	var obstacle_text = ""
	if next_plan.obstacle_rate > 0:
		obstacle_text = " (Obstacle: Stone Gem %d%%)" % int(next_plan.obstacle_rate * 100)
	
	next_stage_info.text = "Next Stage: %s (Target: %d)%s" % [
		run_state.format_stage_progress(next_plan.stage_index),
		next_plan.target_score,
		obstacle_text
	]
	
	var reroll_price = _get_reroll_price()
	reroll_button.text = "Reroll: %dG" % reroll_price
	reroll_button.disabled = run_state.gold < reroll_price
	
	# Clear and rebuild inventory
	for child in items_container.get_children():
		child.queue_free()
	
	for item in current_inventory:
		var price = _get_item_price(item)
		
		var panel = PanelContainer.new()
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.gui_input.connect(_on_item_panel_input.bind(item, price))
		panel.custom_minimum_size = Vector2(176, 188)
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 4)
		panel.add_child(vbox)
		
		# Item Texture
		var icon_container = CenterContainer.new()
		icon_container.custom_minimum_size = Vector2(64, 64)
		vbox.add_child(icon_container)

		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(64, 64)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_container.add_child(tex_rect)
	
		# Set texture
		if item.type == "board_upgrade":
			# For board upgrades, the new icons already represent the board/squares,
			# so we don't need the base gem texture behind them.
			var effect_id = item.get("effect", "")
			if effect_id != "":
				tex_rect.texture = GemTextureManager_.get_effect_texture(effect_id)
		elif item.type == "special_gem" or item.type == "coated_gem" or item.type == "normal_gem" or item.type == "value_gem_bundle":
			_render_gem_item(tex_rect, item)
		elif item.type == "relic":
			tex_rect.texture = GemTextureManager_.get_relic_texture(item.id)
		
		var name_label = Label.new()
		name_label.text = item.name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(name_label)
		
		var price_label = Label.new()
		price_label.text = "MAX" if item.get("maxed", false) else "%dG" % price
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_label.add_theme_font_size_override("font_size", 22)
		price_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8) if item.get("maxed", false) else Color.YELLOW)
		vbox.add_child(price_label)
		
		var buy_btn = Button.new()
		buy_btn.text = "BUY"
		buy_btn.custom_minimum_size = Vector2(0, 40)
		buy_btn.add_theme_font_size_override("font_size", 17)
		buy_btn.disabled = item.get("maxed", false) or run_state.gold < price
		buy_btn.pressed.connect(_on_buy_pressed.bind(item, price))
		vbox.add_child(buy_btn)
		
		panel.tooltip_text = DescriptionService_.get_item_description(item)
		items_container.add_child(panel)
	
	update_relics()

func update_relics() -> void:
	for child in shop_relics_container.get_children():
		child.queue_free()
		
	for relic_id in run_state.relic_ids:
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(48, 48)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture = GemTextureManager_.get_relic_texture(relic_id)
		tex_rect.tooltip_text = DescriptionService_.get_relic_description(relic_id)
		shop_relics_container.add_child(tex_rect)

func _has_shop_discount() -> bool:
	return run_state != null and run_state.relic_ids.has("relic_shop")

func _get_discounted_price(base_price: int) -> int:
	if _has_shop_discount():
		return max(1, int(floor(base_price * 0.85)))
	return base_price

func _get_item_price(item: Dictionary) -> int:
	return _get_discounted_price(int(item.get("price", 0)))

func _get_reroll_price() -> int:
	return _get_discounted_price(reroll_cost)

func _on_item_panel_input(event: InputEvent, item: Dictionary, price: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_item_detail(item, price)

func _show_item_detail(item: Dictionary, price: int) -> void:
	detail_name.text = item.name
	detail_desc.text = DescriptionService_.get_item_description(item)
	detail_price.text = "MAX" if item.get("maxed", false) else "Cost: %dG" % price
	
	# Icon Setup
	detail_icon.custom_minimum_size = Vector2(64, 64)
	detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	for child in detail_icon.get_children(): child.queue_free()
	
	if item.type == "board_upgrade":
		var effect_id = item.get("effect", "")
		if effect_id != "":
			detail_icon.texture = GemTextureManager_.get_effect_texture(effect_id)
		else:
			detail_icon.texture = null
	elif item.type == "special_gem" or item.type == "coated_gem" or item.type == "normal_gem" or item.type == "value_gem_bundle":
		_render_gem_item(detail_icon, item)
	elif item.type == "relic":
		detail_icon.texture = GemTextureManager_.get_relic_texture(item.id)
	else:
		detail_icon.texture = null
		
	detail_buy_btn.disabled = item.get("maxed", false) or run_state.gold < price
	for connection in detail_buy_btn.pressed.get_connections():
		detail_buy_btn.pressed.disconnect(connection.callable)
		
	detail_buy_btn.pressed.connect(func():
		_on_buy_pressed(item, price)
		detail_overlay.visible = false
	)
	
	detail_overlay.visible = true

func _on_buy_pressed(item: Dictionary, price: int) -> void:
	if item.get("maxed", false):
		return
	if run_state.gold >= price:
		run_state.gold -= price
		apply_purchase(item)
		if item.type == "board_upgrade":
			_refresh_persistent_inventory()
		else:
			current_inventory.erase(item)
		update_ui(next_stage_plan)

func apply_purchase(item: Dictionary) -> void:
	match item.type:
		"special_gem":
			var gem = GemInstance_.new(item.color)
			gem.add_coat(item.effect)
			run_state.master_deck.append(gem)
		"normal_gem":
			var normal_gem = GemInstance_.new(item.color)
			normal_gem.value_bonus = int(item.get("value_bonus", 0))
			run_state.master_deck.append(normal_gem)
		"value_gem_bundle":
			for _i in range(int(item.get("bundle_count", 5))):
				var value_gem = GemInstance_.new(item.color)
				value_gem.value_bonus = int(item.get("value_bonus", 5))
				run_state.master_deck.append(value_gem)
		"relic":
			run_state.add_relic(item.id)
		"coated_gem":
			var gem = GemInstance_.new(item.color)
			gem.add_coat(item.coat)
			run_state.master_deck.append(gem)
		"board_upgrade":
			if item.axis == "height":
				run_state.expand_height()
			else:
				run_state.expand_width()
		"consumable":
			print("Purchased item: %s" % item.id)

func _on_reroll_pressed() -> void:
	var reroll_price = _get_reroll_price()
	if run_state.gold >= reroll_price:
		run_state.gold -= reroll_price
		current_inventory = ShopGenerator_.generate_shop_inventory(run_state)
		reroll_cost += 1
		update_ui(next_stage_plan)

func _on_view_deck_pressed() -> void:
	view_deck_requested.emit()

func _on_next_button_pressed() -> void:
	shop_finished.emit()

func _refresh_persistent_inventory() -> void:
	var updated_inventory := ShopGenerator_.get_persistent_shop_items(run_state)
	for item in current_inventory:
		if item.type != "board_upgrade":
			updated_inventory.append(item)
	current_inventory = updated_inventory

func _render_gem_item(tex_rect: TextureRect, item: Dictionary) -> void:
	var effect_id = item.get("effect", item.get("coat", ""))
	tex_rect.texture = GemTextureManager_.get_gem_texture(item.color)
	if item.type == "value_gem_bundle":
		effect_id = "score"
	if effect_id != "":
		var overlay = TextureRect.new()
		overlay.texture = GemTextureManager_.get_effect_texture(effect_id)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.add_child(overlay)
