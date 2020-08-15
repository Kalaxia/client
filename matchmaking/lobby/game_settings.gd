extends VBoxContainer

const SIZE = ["very_small", "small", "medium", "large", "very_large"]
const SPEED = ["slow", "medium", "fast"]

export(bool) var enabled = false setget set_enabled

onready var option_size = $PanelContainer/MarginContainer/GameSetings/Size/OptionButton
onready var option_speed = $PanelContainer/MarginContainer/GameSetings/Speed/OptionButton


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
	_pacth_game_seting("game_speed", SPEED[id])


func _on_size_selected(id):
	_pacth_game_seting("map_size", SIZE[id])


func _pacth_game_seting(field, value):
	Network.req(self, "_on_data_patched",
		"/api/lobbies/" + Store._state.lobby.id + "/",
		HTTPClient.METHOD_PATCH,
		[ "Content-Type: application/json" ],
		JSON.print({field : value})
	)


func _on_data_patched(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)


func _on_game_config_changed(lobby_option):
	update_game_settings_button(lobby_option)


func update_game_settings_button(lobby_option):
	if option_size != null and lobby_option.has("map_size"):
		option_size.disconnect("item_selected", self, "_on_size_selected")
		option_size.selected = SIZE.find(lobby_option.map_size)
		option_size.connect("item_selected", self, "_on_size_selected")
	if option_speed != null and lobby_option.has("game_speed"):
		option_speed.disconnect("item_selected", self, "_on_speed_selected")
		option_speed.selected = SPEED.find(lobby_option.game_speed)
		option_speed.connect("item_selected", self, "_on_speed_selected")
