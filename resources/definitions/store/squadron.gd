class_name Squadron
extends ShipGroup

export(String) var system = null


func _init(dict = null).(dict):
	pass


func _get_dict_property_list():
	return ._get_dict_property_list() + ["system"]
