extends RefCounted

const GemInstance_ = preload("res://scripts/domain/gem_instance.gd")

var draw_pile: Array = [] # Array[GemInstance_]
var discard_pile: Array = [] # Array[GemInstance_]

func _init(initial_gems: Array = []) -> void:
	draw_pile = initial_gems
	draw_pile.shuffle()

func draw_one() -> Object: # GemInstance_
	if draw_pile.size() == 0:
		if discard_pile.size() == 0:
			# Fallback if somehow both are empty
			return null
		reshuffle()
	
	return draw_pile.pop_back()

func discard(gem: Object) -> void:
	if gem:
		discard_pile.append(gem)

func reshuffle() -> void:
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	draw_pile.shuffle()
	# Restore coats, etc. will happen here in the future
