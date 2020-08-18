extends Resource
class_name DictResource

func load_dict(dict) -> void:
	for key in self._get_dict_property_list():
		print("LOADED")
		self.set_indexed(key, dict[key])

func _get_dict_property_list() -> Array:
	return []
