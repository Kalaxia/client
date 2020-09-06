extends VBoxContainer

export(bool) var enabled = false setget set_enabled

onready var option_size = $PanelContainer/MarginContainer/GameSettings/Size/OptionButton
onready var option_speed = $PanelContainer/MarginContainer/GameSettings/Speed/OptionButton


func _ready():
	Network.connect("LobbyOptionsUpdated", self, "_on_game_config_changed")
	option_size.connect("item_selected", self, "_on_size_selected")
	option_speed.connect("item_selected", self, "_on_speed_selected")
	_update_enable_state()


func set_enabled(new_state):
	enabled = new_state
	_update_enable_state()


func _update_enable_state():
	option_size.disabled = not enabled
	option_speed.disabled = not enabled


func _on_speed_selected(id):
	Store.lobby.option.game_speed = LobbyOption.SPEED[id]
	_pacth_game_seting("game_speed", LobbyOption.SPEED[id])


func _on_size_selected(id):
	Store.lobby.option.map_size = LobbyOption.SIZE[id]
	_pacth_game_seting("map_size", LobbyOption.SIZE[id])


func _pacth_game_seting(field, value):
	Network.req(self, "_on_data_patched",
		"/api/lobbies/" + Store.lobby.id + "/",
		HTTPClient.METHOD_PATCH,
		[ "Content-Type: application/json" ],
		JSON.print({field : value})
	)


func _on_data_patched(err, _response_code, _headers, _body):
	if err:
		ErrorHandler.network_response_error(err)


func _on_game_config_changed(lobby_option):
	Store.lobby.option.load_dict(lobby_option)
	update_game_settings_button(Store.lobby)


func update_game_settings_button(lobby_option):
	if option_size != null:
		option_size.disconnect("item_selected", self, "_on_size_selected")
		option_size.selected = LobbyOption.SIZE.find(lobby_option.option.map_size)
		option_size.connect("item_selected", self, "_on_size_selected")
	if option_speed != null:
		option_speed.disconnect("item_selected", self, "_on_speed_selected")
		option_speed.selected = LobbyOption.SPEED.find(lobby_option.option.game_speed)
		option_speed.connect("item_selected", self, "_on_speed_selected")
