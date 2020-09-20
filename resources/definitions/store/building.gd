class_name Building
extends DictResource

const ASSETS = preload("res://resources/assets.tres")

export(Resource) var kind = null
export(int) var built_at
export(int) var created_at
export(String) var id
export(String) var status
export(String) var system


func _init(dict = null).(dict):
	pass


func load_dict(dict):
	if dict == null:
		return
	.load_dict(dict)
	kind = dict.kind if dict.kind is KalaxiaBuilding else ASSETS.buildings[dict.kind]


func _get_dict_property_list():
	return ["built_at", "created_at", "id", "status", "system"]
