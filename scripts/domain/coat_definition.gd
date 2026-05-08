class_name CoatDefinition
extends RefCounted

var id: String
var display_name: String
var effect_id: String

func _init(i: String, n: String, e: String) -> void:
	id = i
	display_name = n
	effect_id = e
