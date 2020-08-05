extends DictResource
class_name SystemData

export var player : String
export var kind : String
export var coords : Vector2
export var unreachable : bool
export var fleets : Dictionary

func _get_dict_property_list() -> Array:
	return ["player", "kind", "coords", "unreachable"]
