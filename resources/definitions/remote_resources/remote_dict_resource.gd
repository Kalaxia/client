extends DictResource
class_name RemoteDictResource

signal loaded()
signal error_loading(err, response_code, body)

var _lock_load_resource = Utils.Lock.new() setget private_set, private_get

export(String) var url # url of the resource.


func _init(url_p = "", dict = null).(dict):
	url = url_p


func load_remote(target_object = null, method_to_trigger = "", arguments = []):
	if not _lock_load_resource.try_lock():
		return false
	Network.req(self, "_on_loaded", url, HTTPClient.METHOD_GET, [], "", [target_object, method_to_trigger, arguments])
	return true


func has_all_data() -> bool:
	for i in _get_prop_list_expected():
		if get_indexed(i) == null:
			return false
	return true


func is_loading():
	return _lock_load_resource.get_is_locked()


func _on_loaded(err, response_code, _headers, body, target_object, method_to_trigger, arguments):
	if err:
		ErrorHandler.network_response_error(err)
		emit_signal("error_loading", err, response_code, body)
	if response_code == HTTPClient.RESPONSE_OK:
		var result = JSON.parse(body.get_string_from_utf8()).result 
		load_dict(result)
		if target_object != null and is_instance_valid(target_object):
			var f = funcref(target_object, method_to_trigger)
			if f.is_valid():
				var arg_array = arguments if arguments is Array else [arguments]
				f.call_funcv( [self] + arg_array)
		emit_signal("loaded")
	elif not err:
		emit_signal("error_loading", err, response_code, body)
	_lock_load_resource.unlock()


func _get_prop_list_expected() -> Array:
	return _get_dict_property_list()


func private_set(_variant):
	pass


func private_get():
	return null
