extends DictResource
class_name ShipGroup

const ASSETS = preload("res://resources/assets.tres")

export(int) var quantity setget set_quantity
export(Resource) var model setget set_model


func _init(dict = null).(dict):
	pass


func load_dict(dict : Dictionary) -> void:
	if dict == null:
		return
	.load_dict(dict)
	if not dict is Dictionary or dict.has("model"):
		self.model = ASSETS.ship[dict.model]


func _get_dict_property_list():
	return ["quantity"]


func set_model(p_model : ShipModel) -> void:
	model = p_model


func set_quantity(new_quantity):
	if new_quantity < 0:
		return
	quantity = new_quantity
