extends Resource
class_name DictResource

func _init(dictionary = null):
	if dictionary != null:
		load_dict(dictionary)


func load_dict(dict) -> void:
	if dict == null:
		return
	for key in self._get_dict_property_list():
		if not dict is Dictionary or dict.has(key):
			self.set_indexed(key, dict[key])


func _get_dict_property_list() -> Array:
	return []
