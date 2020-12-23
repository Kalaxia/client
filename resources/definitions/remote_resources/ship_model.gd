extends DictResource
class_name ShipModel

export(String) var category
export(int) var construction_time
export(int) var cost
export(int) var damage
export(int) var hit_points
export(int) var precision

# we can even add some infos about graphical representation or "gun sound" why not
# export var texture : Texture


func _init(dict = null).(dict):
	pass


func _get_dict_property_list() -> Array:
	return [
		"category",
		"construction_time",
		"cost",
		"damage",
		"hit_points",
		"precision"
	]


func max_ship_build(price):
	return floor(price as float / cost as float) as int
