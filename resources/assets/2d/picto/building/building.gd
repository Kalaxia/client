tool
extends DictResource
class_name KalaxiaBuilding

export(String) var kind
export(float) var contruction_time
export(float) var cost
export(Texture) var texture


func _init(dict = null).(dict):
	pass


func load_dict(dict):
	.load_dict(dict)
	texture = load("res://resources/assets/2d/picto/building/" + (kind if kind != "" else "area") + ".svg")


func _get_dict_property_list():
	return ["kind", "contruction_time", "cost"]
