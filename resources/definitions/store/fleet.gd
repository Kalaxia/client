extends DictResource
class_name Fleet

export var ship_groups : Dictionary
export var model : Resource


func _init(dict = null).(dict):
	pass


func _get_dict_property_list():
	return ["ship_groups"]
