class_name ShipGroup
extends DictResource

const ASSETS = preload("res://resources/assets.tres")

export(int) var quantity setget set_quantity
export(Resource) var category setget set_category
export(String) var system = null
export(String) var id = null
export(String) var fleet = null


func _init(dict = null).(dict):
	pass


func load_dict(dict : Dictionary) -> void:
	if dict == null:
		return
	.load_dict(dict)
	if not dict is Dictionary or dict.has("category"):
		self.category = ASSETS.ship[dict.category]


func _get_dict_property_list():
	return ["quantity", "system", "id", "fleet"]


func set_category(p_category : ShipModel) -> void:
	category = p_category


func set_quantity(new_quantity):
	if new_quantity < 0:
		return
	quantity = new_quantity
