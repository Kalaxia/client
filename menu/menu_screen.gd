extends Control

signal scene_requested(scene)

var lobby_card_scene = preload("res://matchmaking/lobby/lobby_card.tscn")

onready var lobbies_container = $GUI/Body/MainSection/Section/Lobbies

func _ready():
	Network.connect("LobbyCreated", self, "_on_lobby_created")
	Network.connect("LobbyNameUpdated", self, "_on_lobby_name_updated")
	Network.connect("LobbyRemoved", self, "_on_lobby_removed")
	Network.connect("LobbyLaunched",self,"_on_lobby_launched")
	Network.connect("PlayerDisconnected", self, "_on_player_disconnected")
	Network.connect("PlayerJoined", self, "_on_player_joined")
	if Network.token == null:
		Network.connect("authenticated", self, "init")
	else:
		init()
	$GUI/Body/MainSection/Menu/LobbyCreationButton.connect("button_down", self, "create_lobby")
	$GUI/Body/MainSection/Menu/OptionButton.connect("button_down", self, "_on_menu_option_pressed")
	$GUI/Body/MainSection/Menu/CreditsButton.connect("button_down", self, "_on_menu_credits_pressed")
	$GUI/Body/MainSection/Menu/Quit.connect("pressed", self, "_quit_game")


func init():
	get_lobbies()


func _quit_game():
	get_tree().quit()


func _queue_free_lobby(lobby : Dictionary):
	lobbies_container.get_node(lobby.id).queue_free()


func get_lobbies():
	Network.req(self, "_handle_get_lobbies", "/api/lobbies/")


func create_lobby():
	Network.req(self, "_handle_create_lobby", "/api/lobbies/", HTTPClient.METHOD_POST)


func add_lobby_cards(lobbies):
	for lobby in lobbies:
		add_lobby_card(lobby)


func add_lobby_card(lobby_dict : Dictionary):
	var lobby = Lobby.new(lobby_dict)
	var lobby_card = lobby_card_scene.instance()
	lobby_card.lobby = lobby
	lobby_card.set_name(lobby.id)
	lobby_card.connect("join", self, "join_lobby")
	lobbies_container.add_child(lobby_card)


func join_lobby(lobby : Lobby):
	Store.lobby = lobby
	Network.req(self, "_handle_join_lobby", "/api/lobbies/" + lobby.id + "/players/", HTTPClient.METHOD_POST)


func _on_lobby_created(lobby : Dictionary):
	add_lobby_card(lobby)


func _on_lobby_name_updated(data : Dictionary):
	lobbies_container.get_node(data.id).update_name(data.name)


func _on_lobby_removed(lobby : Dictionary):
	_queue_free_lobby(lobby)


func _on_lobby_launched(lobby : Dictionary):
	_queue_free_lobby(lobby)


func _on_player_joined(player : Dictionary):
	lobbies_container.get_node(player.lobby).add_player(Player.new(player))


func _on_player_disconnected(player : Dictionary):
	if player.lobby != null:
		lobbies_container.get_node(player.lobby).remove_player(player.id)


func _handle_get_lobbies(err, response_code, _headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_OK:
		add_lobby_cards(JSON.parse(body.get_string_from_utf8()).result)


func _handle_create_lobby(err, response_code, _headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_CREATED:
		Store.lobby = Lobby.new(JSON.parse(body.get_string_from_utf8()).result)
		emit_signal("scene_requested", "lobby")
	# todo handel error


func _handle_join_lobby(err, response_code, _headers, _body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_NO_CONTENT:
		Store.lobby.players[Store.player.id] = Store.player
		emit_signal("scene_requested", "lobby")
	# todo handel error


func _on_menu_option_pressed():
	emit_signal("scene_requested", "option_menu")


func _on_menu_credits_pressed():
	emit_signal("scene_requested", "credits_menu")
