extends DictResource
class_name ShipQueue


export(int) var quantity = 0 setget set_quantity
export(Resource) var model


func _init(dict = null).(dict):
	pass


func load_dict(dict) -> void:
	if dict == null:
		return
	.load_dict(dict)


func _get_dict_property_list():
	return []


func set_quantity(new_quantity):
	if new_quantity < 0:
		return
	quantity = new_quantity
