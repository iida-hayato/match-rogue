extends RefCounted

static func generate_shop_inventory(_stage_index: int, owned_relics: Array[String] = []) -> Array[Dictionary]:
	var inventory: Array[Dictionary] = []
	
	# 特殊Gem x2
	inventory.append(generate_special_gem())
	inventory.append(generate_special_gem())
	
	# レリック x1 (取得済みは除外)
	var relic = generate_relic(owned_relics)
	if relic:
		inventory.append(relic)
	else:
		# 全レリック所持時は代わりに消費アイテム
		inventory.append(generate_consumable())
	
	# コート付きGem or 消費アイテム x1
	if randf() < 0.5:
		inventory.append(generate_coated_gem())
	else:
		inventory.append(generate_consumable())
		
	return inventory

static func generate_special_gem() -> Dictionary:
	var items = [
		{"id": "rocket_v", "name": "V-Rocket (Red)", "type": "special_gem", "color": "red", "effect": "rocket_v", "price": 10},
		{"id": "rocket_h", "name": "H-Rocket (Blue)", "type": "special_gem", "color": "blue", "effect": "rocket_h", "price": 10},
		{"id": "bomb", "name": "Bomb (Yellow)", "type": "special_gem", "color": "yellow", "effect": "bomb", "price": 12},
		{"id": "beam", "name": "Beam (Purple)", "type": "special_gem", "color": "purple", "effect": "beam", "price": 12},
		{"id": "coin_gem", "name": "Coin Gem (Green)", "type": "special_gem", "color": "green", "effect": "coin", "price": 8}
	]
	return items[randi() % items.size()]

static func generate_relic(owned_relics: Array[String] = []) -> Dictionary:
	var pool = [
		{"id": "relic_mining", "name": "Mining Emblem", "type": "relic", "price": 22},
		{"id": "relic_chain", "name": "Chain Gear", "type": "relic", "price": 20},
		{"id": "relic_shop", "name": "Member Card", "type": "relic", "price": 18},
		{"id": "relic_box_match", "name": "Magic Box", "type": "relic", "price": 25}
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
