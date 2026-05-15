extends Node

# Explicitly preloading textures ensures they are included in the export 
# and available immediately on all platforms including Web.

static var textures = {
	"red": preload("res://assets/textures/gems/red.svg"),
	"blue": preload("res://assets/textures/gems/blue.svg"),
	"green": preload("res://assets/textures/gems/green.svg"),
	"yellow": preload("res://assets/textures/gems/yellow.svg"),
	"purple": preload("res://assets/textures/gems/purple.svg"),
	"stone": preload("res://assets/textures/gems/stone.svg"),
}

static var effects = {
	"rocket_v": preload("res://assets/textures/gems/effect_rocket_v.svg"),
	"rocket_h": preload("res://assets/textures/gems/effect_rocket_h.svg"),
	"bomb": preload("res://assets/textures/gems/effect_bomb.svg"),
	"beam": preload("res://assets/textures/gems/effect_beam.svg"),
	"coin": preload("res://assets/textures/gems/effect_coin.svg"),
	"add_row": preload("res://assets/textures/gems/effect_add_row.svg"),
	"add_column": preload("res://assets/textures/gems/effect_add_column.svg"),
}

static var relics = {
	"relic_mining": preload("res://assets/textures/relics/relic_mining.svg"),
	"relic_chain": preload("res://assets/textures/relics/relic_chain.svg"),
	"relic_shop": preload("res://assets/textures/relics/relic_shop.svg"),
	"relic_box_match": preload("res://assets/textures/relics/relic_box_match.svg"),
	"relic_rocket_workshop": preload("res://assets/textures/relics/relic_rocket_workshop.svg"),
	"relic_bomb_workshop": preload("res://assets/textures/relics/relic_bomb_workshop.svg"),
	"relic_prism_secret": preload("res://assets/textures/relics/relic_prism_secret.svg"),
	"relic_beam_range": preload("res://assets/textures/relics/relic_beam_range.svg"),
	"relic_rocket_range": preload("res://assets/textures/relics/relic_rocket_range.svg"),
	"relic_bomb_diagonal": preload("res://assets/textures/relics/relic_bomb_diagonal.svg"),
	"relic_auto_drop_seal": preload("res://assets/textures/relics/relic_shop.svg"),
}

static func get_gem_texture(id: String) -> Texture2D:
	return textures.get(id)

static func get_effect_texture(id: String) -> Texture2D:
	return effects.get(id)

static func get_relic_texture(id: String) -> Texture2D:
	return relics.get(id)
