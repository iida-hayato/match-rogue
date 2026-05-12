extends RefCounted

var instance_id: String
var definition_id: String
var coat_ids: Array[String] = []

func _init(def_id: String) -> void:
	instance_id = str(randi()) # Simple ID for now
	definition_id = def_id

func add_coat(coat_id: String) -> void:
	if not coat_ids.has(coat_id):
		coat_ids.append(coat_id)

func duplicate() -> GemInstance:
	var copy = GemInstance.new(definition_id)
	copy.coat_ids = coat_ids.duplicate()
	return copy

func is_stone() -> bool:
	return definition_id == "stone"
