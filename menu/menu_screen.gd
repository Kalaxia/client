extends Control

var lobby_card_scene = preload("res://matchmaking/lobby/lobby_card.tscn")

signal scene_requested(scene)

func _ready():
	$HTTPRequest.connect("request_completed", self, "_on_request_completed")
	Network.connect("LobbyCreated", self, "_on_lobby_created")
	Network.connect("LobbyNameUpdated", self, "_on_lobby_name_updated")
	Network.connect("LobbyRemoved", self, "_on_lobby_removed")
	Network.connect("PlayerDisconnected", self, "_on_player_disconnected")
	Network.connect("PlayerJoined", self, "_on_player_joined")
	if Network.token == null:
		Network.connect("authenticated", self, "init")
	else:
		init()
	get_node("GUI/Body/Footer/LobbyCreationButton").connect("button_down", self, "create_lobby")
	
func init():
	get_lobbies()
	
func get_lobbies():
	$HTTPRequest.request(Network.api_url + "/api/lobbies/", [
		"Authorization: Bearer " + Network.token
	])
	
func create_lobby():
	var err = $HTTPRequest.request(Network.api_url + "/api/lobbies/", [
		"Authorization: Bearer " + Network.token
	], false, HTTPClient.METHOD_POST)
	if err:
		ErrorHandler.network_error(err)
	
func add_lobby_cards(lobbies):
	for lobby in lobbies:
		add_lobby_card(lobby)
	
func add_lobby_card(lobby):
	lobby.players = []
	var lobby_card = lobby_card_scene.instance()
	lobby_card.lobby = lobby
	lobby_card.set_name(lobby.id)
	lobby_card.connect("join", self, "join_lobby")
	get_node("GUI/Body/Section/Lobbies").add_child(lobby_card)
	
func join_lobby(lobby, must_update = false):
	Store._state.lobby = lobby
	var err = $HTTPRequest.request(Network.api_url + "/api/lobbies/" + lobby.id + "/players/", [
		"Authorization: Bearer " + Network.token
	], false, HTTPClient.METHOD_POST)
	if err:
		ErrorHandler.network_error(err)
	
func _on_lobby_created(lobby):
	add_lobby_card(lobby)
	
func _on_lobby_name_updated(data):
	get_node("GUI/Body/Section/Lobbies/" + data.id).update_name(data.name)
	
func _on_lobby_removed(lobby):
	get_node("GUI/Body/Section/Lobbies/" + lobby.id).queue_free()
	
func _on_player_joined(player):
	get_node("GUI/Body/Section/Lobbies/" + player.lobby).increment_nb_players()
	
func _on_player_disconnected(player):
	if player.lobby != null:
		get_node("GUI/Body/Section/Lobbies/" + player.lobby).decrement_nb_players()
	
func _on_request_completed(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
		return
		
	if response_code == 200:
		add_lobby_cards(JSON.parse(body.get_string_from_utf8()).result)
	elif response_code == 201:
		Store._state.lobby = JSON.parse(body.get_string_from_utf8()).result
		emit_signal("scene_requested", "lobby")
	elif response_code == 204:
		Store._state.lobby.players.push_back(Store._state.player.id)
		emit_signal("scene_requested", "lobby")
	
