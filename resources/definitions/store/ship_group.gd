extends DictResource
class_name ShipGroup

export var quantity : int
export var model : Resource setget set_model


func load_dict(dict : Dictionary) -> void:
	self.quantity = dict.quantity
	self.model = load("res://resources/assets.tres").ship[dict.model]


func set_model(p_model : ShipModel) -> void:
	model = p_model
