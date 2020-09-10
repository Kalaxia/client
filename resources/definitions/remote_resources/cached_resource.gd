extends DictResource
class_name CachedResource

enum Resource_elements{
	BUILDING,
	SHIP_MODELS,
	FACTIONS,
	CONSTANTS,
}

signal error(ressource_name, err, response_code, body)
signal loaded(ressource_name)

const CACHED_DATA_PATH = "res://cache.tres"

export(Dictionary) var factions
export(Array, Resource) var ship_models
export(Array, Resource) var building_list
export(Resource) var constants
export(String) var version = null

var _lock_load_building = Utils.Lock.new() setget private_set, private_get
var _lock_ships = Utils.Lock.new() setget private_set, private_get
var _lock_faction = Utils.Lock.new() setget private_set, private_get
var dict_loaded = { # todo can cause bugs
	Resource_elements.BUILDING : true, 
	Resource_elements.SHIP_MODELS : true, 
	Resource_elements.FACTIONS : true,
	Resource_elements.CONSTANTS : true,
} setget private_set


func _init():
	constants = ConstanteRemoteResource.new()
	# todo dict_loaded reset ?


func refresh(version_p):
	if version != version_p or version == null:
		version = version_p
		_fetch_data_and_save()
		return true
	return false


func load_constant():
	constants = ConstanteRemoteResource.new()
	constants.load_remote()
	constants.connect("loaded", self, "_on_constants_loaded")
	constants.connect("error_loading", self, "_on_constants_error_loading")


func has_all_data():
	return constants.has_all_data() and has_ships_model() \
	and has_factions() and has_building()


func has_ships_model():
	return ship_models.size() > 0


func has_factions():
	return factions.size() > 0


func has_building():
	return building_list.size() > 0


func has_finished_loading():
	var has_finished_loading = true
	for key in dict_loaded.keys():
		has_finished_loading = has_finished_loading and dict_loaded[key]
	return has_finished_loading


func load_building():
	if not _lock_load_building.try_lock():
		return false
	Network.req(self, "_on_building_loaded", "/api/buildings/")
	return true


func _on_building_loaded(err, response_code, _header, body):
	if err:
		ErrorHandler.network_response_error(err)
		emit_signal("error", Resource_elements.BUILDING, err, response_code, body)
	if response_code == HTTPClient.RESPONSE_OK:
		var result = JSON.parse(body.get_string_from_utf8()).result 
		building_list = []
		for building in result:
			building_list.push_back(BuildingModelRemote.new(building))
		dict_loaded[Resource_elements.BUILDING] = true
		_verify_finished_loading()
		emit_signal("loaded", Resource_elements.BUILDING)
	elif not err:
		emit_signal("error_loading", Resource_elements.BUILDING , err, response_code, body)
	_lock_load_building.unlock()


func load_ship_models():
	if not _lock_ships.try_lock():
		return false
	Network.req(self, "_on_ship_models_loaded", "/api/ship-models/")
	return true


func _on_ship_models_loaded(err, response_code, _header, body):
	if err:
		ErrorHandler.network_response_error(err)
		emit_signal("error", Resource_elements.SHIP_MODELS, err, response_code, body)
	if response_code == HTTPClient.RESPONSE_OK:
		var result = JSON.parse(body.get_string_from_utf8()).result 
		ship_models = []
		for ship_model in result:
			ship_models.push_back(ShipModel.new(ship_model))
		dict_loaded[Resource_elements.SHIP_MODELS] = true
		_verify_finished_loading()
		emit_signal("loaded", Resource_elements.SHIP_MODELS)
	elif not err:
		emit_signal("error_loading", Resource_elements.SHIP_MODELS, err, response_code, body)
	_lock_ships.unlock()


func load_factions():
	if not _lock_faction.try_lock():
		return false
	Network.req(self, "_on_factions_loaded", "/api/factions/")
	return true


func _on_factions_loaded(err, response_code, _header, body):
	if err:
		ErrorHandler.network_response_error(err)
		emit_signal("error", Resource_elements.FACTIONS, err, response_code, body)
	if response_code == HTTPClient.RESPONSE_OK:
		var result = JSON.parse(body.get_string_from_utf8()).result
		factions = {}
		for faction in result:
			factions[faction.id] = (FactionRemote.new(faction))
		dict_loaded[Resource_elements.FACTIONS] = true
		_verify_finished_loading()
		emit_signal("loaded", Resource_elements.FACTIONS)
	elif not err:
		emit_signal("error_loading", Resource_elements.FACTIONS, err, response_code, body)
	_lock_faction.unlock()


func _on_constants_loaded():
	dict_loaded[Resource_elements.CONSTANTS] = true
	_verify_finished_loading()
	emit_signal("loaded", Resource_elements.CONSTANTS)
	_disconnect_constants_loading()


func _on_constants_error_loading(err, response_code, body):
	emit_signal("error", Resource_elements.CONSTANTS, err, response_code, body)
	_disconnect_constants_loading()


func _disconnect_constants_loading():
	constants.disconnect("loaded", self, "_on_constants_loaded")
	constants.disconnect("error_loading", self, "_on_constants_error_loading")


func _fetch_data_and_save():
	# todo version controle
	for key in dict_loaded.keys():
		dict_loaded[key] = false
	load_constant()
	load_building()
	load_factions()
	load_ship_models()


func _verify_finished_loading():
	if has_finished_loading():
		var err = ResourceSaver.save(CACHED_DATA_PATH, self, ResourceSaver.FLAG_CHANGE_PATH)
		if err != OK:
			printerr("Could not save cached data at path %s : %d" % [CACHED_DATA_PATH, err])


func private_set(_variant):
	pass


func private_get():
	return null
