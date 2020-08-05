extends DictResource
class_name ShipModel

export var category : String
export var contruction_type : int
export var cost : int
export var damage : int
export var hit_points : int
export var precision : int

# we can even add some infos about graphical representation or "gun sound" why not
# export var texture : Texture

func _get_dict_property_list() -> Array:
	return [
		"category",
		"construction_type",
		"cost",
		"damage",
		"hit_points",
		"precision"
	]
