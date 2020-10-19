class_name FleetSquadron
extends ShipGroup

export(String) var fleet = null
export(String, "center", "left", "right", "rear") var formation = ""


func _init(dict = null).(dict):
	pass


func _get_dict_property_list():
	return ._get_dict_property_list() + ["fleet", "formation"]
