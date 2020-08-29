extends DictResource
class_name FactionRemote

export(Array, int) var display_color
export(String) var name
export(float) var id


func _init(dict = null).(dict):
	pass


func load_dict(dict):
	.load_dict(dict)
	display_color = Color8(dict.color[0], dict.color[1], dict.color[2], dict.color[3])


func _get_dict_property_list() -> Array:
	return ["name", "id"]
