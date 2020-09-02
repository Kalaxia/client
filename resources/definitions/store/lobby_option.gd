extends DictResource
class_name LobbyOption

const SIZE = ["very_small", "small", "medium", "large", "very_large"]
const SPEED = ["slow", "medium", "fast"]

export(String, "slow", "medium", "fast") var speed = "medium"
export(String, "very_small", "small", "medium", "large", "very_large") var size = "medium"


func _init(dict = null).(dict):
	pass


func _get_dict_property_list():
	return ["speed", "size"]
