class_name GemInstance
extends RefCounted

var instance_id: String
var definition_id: String
# In the future, this might hold coat states, etc.

func _init(def_id: String) -> void:
	instance_id = str(ResourceUID.create_id()) if ClassDB.class_exists("ResourceUID") else str(randi())
	definition_id = def_id
