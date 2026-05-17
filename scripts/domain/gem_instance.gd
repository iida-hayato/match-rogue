extends RefCounted

var instance_id: String
var definition_id: String
var coat_ids: Array[String] = []
var value_bonus: int = 0

func _init(def_id: String) -> void:
	instance_id = str(randi()) # Simple ID for now
	definition_id = def_id

func add_coat(coat_id: String) -> void:
	if not coat_ids.has(coat_id):
		coat_ids.append(coat_id)

func duplicate() -> Object:
	var copy = get_script().new(definition_id)
	copy.coat_ids = coat_ids.duplicate()
	copy.value_bonus = value_bonus
	return copy

func is_stone() -> bool:
	return definition_id == "stone"
