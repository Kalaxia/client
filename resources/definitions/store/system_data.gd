extends DictResource
class_name SystemData

export var player : String
export var kind : String
export var coords : Vector2
export var unreachable : bool
export var fleets : Dictionary

func _get_dict_property_list() -> Array:
	return ["player", "kind", "coords", "unreachable"]
"res://resources/fleet_data.gd","res://resources/game_data.gd","res://resources/player_data.gd","res://resources/ship_group.gd","res://resources/ship_model.gd","res://resources/system_data.gd"
