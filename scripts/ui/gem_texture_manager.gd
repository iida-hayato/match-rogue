class_name GemTextureManager
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
}

static func get_gem_texture(id: String) -> Texture2D:
	return textures.get(id)

static func get_effect_texture(id: String) -> Texture2D:
	return effects.get(id)
