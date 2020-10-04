extends Resource
class_name DictResource


func _init(dictionary = null):
	if dictionary != null:
		load_dict(dictionary)


func load_dict(dict) -> void:
	if dict == null:
		return
	if not dict is Dictionary and not dict is Object:
		push_error("Cannot load form this data type")
		print_stack()
		return
	for key in self._get_dict_property_list():
		if dict is Dictionary and dict.has(key):
			self.set_indexed(key, dict[key])
		elif dict is Object:
			self.set_indexed(key, dict.get_indexed(key))


func _get_dict_property_list() -> Array:
	return []
