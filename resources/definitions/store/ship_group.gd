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
		self.category = dict.category if dict.category is KalaxiaShipModel else ASSETS.ship_models[dict.category]


func _get_dict_property_list():
	return ["quantity", "system", "id", "fleet"]


func set_category(p_category : ShipModel) -> void:
	if category != p_category:
		category = p_category
		emit_signal("changed")


func set_quantity(new_quantity):
	if new_quantity < 0 or new_quantity == quantity:
		return
	quantity = new_quantity
	emit_signal("changed")
