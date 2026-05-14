extends RefCounted

static func get_relic_description(id: String) -> String:
	match id:
		"relic_mining": return "Mining Emblem: Clear 6+ gems at once to get huge bonus multipliers."
		"relic_chain": return "Chain Gear: Increases chain multiplier bonus per step."
		"relic_shop": return "Member Card: 15% discount on all shop items."
		"relic_box_match": return "Magic Box: Allows matching 2x2 squares of the same color. Box matches grant +1 Gold."
		"relic_rocket_workshop": return "Rocket Workshop: 4 in a row creates a rocket gem."
		"relic_bomb_workshop": return "Bomb Workshop: T and cross matches create a bomb gem."
		"relic_prism_secret": return "Prism Secret: 5 in a row creates a diagonal beam gem."
		"relic_beam_range": return "Lens Scope: Diagonal beams reach 1 tile farther."
		"relic_rocket_range": return "Nozzle Extender: Rockets reach 1 tile farther."
		"relic_bomb_diagonal": return "Shrapnel Core: Bombs also hit diagonals."
	return "No description available."

static func get_gem_description(gem: Object) -> String:
	# Expects GemInstance-like object with definition_id and coat_ids
	var desc = "Color: %s" % gem.definition_id.capitalize()
	if gem.has_method("is_stone") and gem.is_stone():
		return "Stone Gem: Does not match. Breaks when nearby gems are cleared."
	
	for coat in gem.coat_ids:
		desc += "\nEffect: " + get_coat_description(coat)
	return desc

static func get_coat_description(id: String) -> String:
	match id:
		"rocket_v": return "Vertical Rocket (Clears up to 3 tiles vertically)"
		"rocket_h": return "Horizontal Rocket (Clears up to 3 tiles horizontally)"
		"bomb": return "Bomb (Clears 3x3 area)"
		"beam": return "Diagonal Beam (Clears diagonals up to 3 tiles)"
		"coin": return "Gold Coin (+1 Gold)"
		"gold": return "Gold Coin (+1 Gold)"
		"score": return "Shiny Polish (Huge score bonus)"
	return id.capitalize()

static func get_item_description(item: Dictionary) -> String:
	if item.type == "relic":
		return get_relic_description(item.id)
	if item.type == "board_upgrade":
		var axis_label = "rows" if item.axis == "height" else "columns"
		var max_state = " Maxed out." if item.get("maxed", false) else ""
		return "Permanently add 1 %s to the board. Current: %d / %d.%s" % [
			axis_label,
			item.get("current_size", 0),
			item.get("max_size", 0),
			max_state
		]
	
	var effect_id = item.get("effect", item.get("coat", ""))
	if effect_id != "":
		return get_coat_description(effect_id)
		
	match item.id:
		"item_hammer": return "Hammer: Click a gem to clear it immediately."
		"item_shuffle": return "Shuffle: Reshuffles the board state."
		
	return "No description available."
