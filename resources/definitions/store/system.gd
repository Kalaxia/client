extends DictResource
class_name System

export(String) var player # ressource ?
export(String) var kind
export(Vector2) var coords
export(bool) var unreachable
export(Dictionary) var fleets


func _init(dict = null).(dict):
	pass


func load_dict(dict):
	if dict == null:
		return
	.load_dict(dict)
	if not dict is Dictionary or dict.has("fleet"):
		for fleet in dict.fleets:
			fleets[fleet.id] = Fleet.new(fleets)

func _get_dict_property_list() -> Array:
	return ["player", "kind", "coords", "unreachable"]
