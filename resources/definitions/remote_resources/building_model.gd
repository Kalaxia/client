extends DictResource
class_name BuildingModelRemote

export(String) var kind
export(float) var contruction_time
export(float) var cost


func _init(dict = null).(dict):
	pass


func _get_dict_property_list() -> Array:
	return ["kind", "contruction_time", "cost"]
