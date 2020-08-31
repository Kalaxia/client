extends VBoxContainer

var _game_data : GameData = Store.game_data
var list_player_option = []
var selected_player = null
var _lock_send_credits = Utils.Lock.new() setget private_set, private_get

onready var option_button = $HBoxContainer/OptionButton
onready var send_button = $HBoxContainer/Button
onready var spinbox = $HBoxContainer/SpinBox


func _ready():
	option_button.connect("item_selected", self, "_on_item_selected")
	send_button.connect("pressed", self, "_on_button_send_pressed")
	_lock_send_credits.connect("changed_state", self, "_on_lock_state_changed")
	spinbox.connect("value_changed", self, "_on_spinbox_value_changed")
	_game_data.player.connect("wallet_updated", self, "_on_wallet_updated")
	for player in _game_data.players.values():
		if player.faction.id == _game_data.player.faction.id and not _game_data.is_current_player(player):
			option_button.add_item(player.username)
			list_player_option.push_back(player.id)
	_verifiy_state_button_send()


func _on_item_selected(id):
	selected_player = list_player_option[id - 1]
	_verifiy_state_button_send()


func _on_spinbox_value_changed(_value):
	_verifiy_state_button_send()


func _on_lock_state_changed(_state):
	_verifiy_state_button_send()


func _verifiy_state_button_send():
	send_button.disabled = selected_player == null or spinbox.value > _game_data.player.wallet or _lock_send_credits.get_is_locked() 


func _on_button_send_pressed():
	if not _lock_send_credits.try_lock():
		return
	var credits_to_send = spinbox.value
	if credits_to_send > _game_data.player.wallet or selected_player == null or credits_to_send <= 0:
		_lock_send_credits.unlock()
		return
	Network.req(self, "_on_credits_send",
		"/api/games/" + _game_data.id + "/factions/" + _game_data.player.faction.id as String 
		+ "/players/" + selected_player + "/money/",
		HTTPClient.METHOD_PATCH,
		[ "Content-Type: application/json" ],
		JSON.print({"amount" : credits_to_send}), 
		[credits_to_send]
	)


func _on_credits_send(err, response_code, _headers, _body, amount):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_NO_CONTENT:
		_game_data.player.update_wallet( - amount)
	_lock_send_credits.unlock()


func _on_wallet_updated(amount):
	spinbox.max_value = amount


func private_set(_value):
	pass


func private_get():
	return null
