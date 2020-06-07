extends Control

signal scene_requested(scene)

func _ready():
	Network.connect_to_host()
	Network.connect("authenticated", self, "_on_authentication")
	Network.req(self, "_on_factions_loaded", "/api/factions/")

func _on_factions_loaded(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	var factions = JSON.parse(body.get_string_from_utf8()).result
	if factions != null:
		Store.set_factions(factions)
	if Network.token != null:
		emit_signal("scene_requested", "menu")

func _on_authentication():
	if Store._state.factions.size() > 0:
		emit_signal("scene_requested", "menu")
