extends DictResource
class_name Player

const ASSETS = preload("res://resources/assets.tres")

export var username : String
export var faction : Resource
export var wallet : int


func _init(dict = null).(dict):
	pass


func load_dict(dict : Dictionary) -> void:
	if dict == null:
		return
	.load_dict(dict)
	if not dict is Dictionary or dict.has("faction"):
		self.faction = ASSETS.factions[dict.faction]
	if not dict is Dictionary or dict.has("wallet"):
		wallet = dict.wallet
	else:
		self.wallet = 0


func _get_dict_property_list() -> Array:
	return ["username"]
