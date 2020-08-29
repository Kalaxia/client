extends Resource
class_name CachedResource

signal error(ressource_name, err, response_code, body)
signal loaded(ressource_name)

export(Array, Resource) var ship_models
export(Array, Resource) var building_list
export(Resource) var constants = ConstanteRemoteResource.new()
export(String) var version = null


func load_constant():
	constants = ConstanteRemoteResource.new().load_remote()
	constants.connect("loaded", self, "_on_constants_loaded")
	constants.connect("error_loading", self, "_on_constants_error_loading")


func _on_constants_loaded():
	emit_signal("loaded", "constants")
	_disconnect_constants_loading()


func _on_constants_error_loading(err, response_code, body):
	emit_signal("error", "constants", err, response_code, body)
	_disconnect_constants_loading()


func _disconnect_constants_loading():
	constants.disconnect("loaded", self, "_on_constants_loaded")
	constants.disconnect("error_loading", self, "_on_constants_error_loading")
