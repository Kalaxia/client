class_name LobbyOption
extends DictResource

const SIZE = ["mini", "very_small", "small", "medium", "large", "very_large"]
const SPEED = ["slow", "medium", "fast"]

export(String, "slow", "medium", "fast") var game_speed = "medium"
export(String, "mini", "very_small", "small", "medium", "large", "very_large") var map_size = "medium"


func _init(dict = null).(dict):
	pass


func _get_dict_property_list():
	return ["game_speed", "map_size"]
