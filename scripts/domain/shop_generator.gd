extends RefCounted

static func generate_shop_inventory(run_state: Object) -> Array[Dictionary]:
	var inventory := get_persistent_shop_items(run_state)
	
	# Special Gem x3
	for _i in range(3):
		inventory.append(generate_special_gem())
	
	# レリック x2 (取得済みは除外)
	var owned_relics = run_state.relic_ids.duplicate()
	for _i in range(2):
		var relic = generate_relic(owned_relics)
		if relic:
			inventory.append(relic)
			owned_relics.append(relic.id)
		
	return inventory

static func get_persistent_shop_items(run_state: Object) -> Array[Dictionary]:
	return [
		_create_board_upgrade_item(
			"expand_height",
			"Add Row",
			"height",
			"yellow",
			"add_row",
			run_state.board_height,
			run_state.get_base_board_height(),
			run_state.get_max_board_height()
		),
		_create_board_upgrade_item(
			"expand_width",
			"Add Column",
			"width",
			"green",
			"add_column",
			run_state.board_width,
			run_state.get_base_board_width(),
			run_state.get_max_board_width()
		)
	]

static func _create_board_upgrade_item(
	id: String,
	name: String,
	axis: String,
	color: String,
	effect: String,
	current_size: int,
	base_size: int,
	max_size: int
) -> Dictionary:
	var purchased_count = current_size - base_size
	return {
		"id": id,
		"name": "%s (%d/%d)" % [name, current_size, max_size],
		"type": "board_upgrade",
		"axis": axis,
		"color": color,
		"effect": effect,
		"price": 6 + (purchased_count * 3),
		"current_size": current_size,
		"max_size": max_size,
		"maxed": current_size >= max_size
	}

static func generate_special_gem() -> Dictionary:
	var colors = ["red", "blue", "green", "yellow", "purple"]
	var bundle_color = colors[randi() % colors.size()]
	var items = [
		{"id": "rocket_v", "name": "V-Rocket (Red)", "type": "special_gem", "color": "red", "effect": "rocket_v", "price": 10},
		{"id": "rocket_h", "name": "H-Rocket (Blue)", "type": "special_gem", "color": "blue", "effect": "rocket_h", "price": 10},
		{"id": "bomb", "name": "Bomb (Yellow)", "type": "special_gem", "color": "yellow", "effect": "bomb", "price": 12},
		{"id": "beam", "name": "Beam (Purple)", "type": "special_gem", "color": "purple", "effect": "beam", "price": 12},
		{"id": "coin_gem", "name": "Coin Gem (Green)", "type": "special_gem", "color": "green", "effect": "coin", "price": 8},
		_create_value_gem_bundle_item(bundle_color)
	]
	return items[randi() % items.size()]

static func generate_value_gem_bundle() -> Dictionary:
	var colors = ["red", "blue", "green", "yellow", "purple"]
	var color = colors[randi() % colors.size()]
	return _create_value_gem_bundle_item(color)

static func _create_value_gem_bundle_item(color: String) -> Dictionary:
	return {
		"id": "value_gem_bundle",
		"name": "Value Gem Bundle",
		"type": "value_gem_bundle",
		"color": color,
		"value_bonus": 5,
		"bundle_count": 10,
		"price": 34
	}

static func generate_relic(owned_relics: Array[String] = []) -> Dictionary:
	var pool = [
		{"id": "relic_mining", "name": "Mining Emblem", "type": "relic", "price": 22},
		{"id": "relic_chain", "name": "Chain Gear", "type": "relic", "price": 20},
		{"id": "relic_shop", "name": "Member Card", "type": "relic", "price": 18},
		{"id": "relic_box_match", "name": "Magic Box", "type": "relic", "price": 25},
		{"id": "relic_rocket_workshop", "name": "Rocket Workshop", "type": "relic", "price": 24},
		{"id": "relic_bomb_workshop", "name": "Bomb Workshop", "type": "relic", "price": 28},
		{"id": "relic_prism_secret", "name": "Prism Secret", "type": "relic", "price": 30},
		{"id": "relic_beam_range", "name": "Precision Lens", "type": "relic", "price": 20},
		{"id": "relic_rocket_range", "name": "Barrel Extender", "type": "relic", "price": 20},
		{"id": "relic_bomb_diagonal", "name": "Shrapnel Ring", "type": "relic", "price": 24},
		{"id": "relic_auto_drop_seal", "name": "Auto Drop Seal", "type": "relic", "price": 42}
	]
	
	# フィルター
	var available = []
	for item in pool:
		if not owned_relics.has(item.id):
			available.append(item)
	
	if available.is_empty():
		return {} # null dictionary indicates no relic available
		
	return available[randi() % available.size()]

static func generate_coated_gem() -> Dictionary:
	var items = [
		{"id": "coated_gold", "name": "Gold Coated Red", "type": "coated_gem", "color": "red", "coat": "gold", "price": 14},
		{"id": "coated_score", "name": "Shiny Coated Blue", "type": "coated_gem", "color": "blue", "coat": "score", "price": 12}
	]
	return items[randi() % items.size()]

static func generate_consumable() -> Dictionary:
	var items = [
		{"id": "item_hammer", "name": "Hammer", "type": "consumable", "price": 6},
		{"id": "item_shuffle", "name": "Shuffle", "type": "consumable", "price": 5}
	]
	return items[randi() % items.size()]
