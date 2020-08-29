extends DictResource
class_name PlayerData

export var nickname : String
export var faction : Resource
export var wallet : int


func load_dict(dict : Dictionary) -> void:
	.load_dict(dict)
	
	var assets = load("res://resources/assets.tres")
	self.faction = assets.factions[dict.faction]
	self.wallet = 0


func _get_dict_property_list() -> Array:
	return ["nickname"]
