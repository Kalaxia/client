extends Control

var lobby_card_scene = preload("res://matchmaking/lobby/lobby_card.tscn")
var lobby_scene = preload("res://matchmaking/lobby/lobby.tscn")
var player_info_scene = preload("res://matchmaking/lobby/player_info.tscn")

func _ready():
	$HTTPRequest.connect("request_completed", self, "_on_request_completed")
	Network.connect("LobbyCreated", self, "_on_lobby_created")
	Network.connect("LobbyNameUpdated", self, "_on_lobby_name_updated")
	Network.connect("LobbyRemoved", self, "_on_lobby_removed")
	if Network.token == null:
		Network.connect("authenticated", self, "get_lobbies")
	else:
		get_lobbies()
	get_node("Body/Footer/LobbyCreationButton").connect("button_down", self, "create_lobby")
	
func get_lobbies():
	$HTTPRequest.request(Network.api_url + "/api/lobbies/", [
		"Authorization: Bearer " + Network.token
	])
	
func create_lobby():
	$HTTPRequest.request(Network.api_url + "/api/lobbies/", [
		"Authorization: Bearer " + Network.token
	], false, HTTPClient.METHOD_POST)
	
func add_lobby_cards(lobbies):
	for lobby in lobbies:
		add_lobby_card(lobby)
	
func add_lobby_card(lobby):
	lobby.players = []
	var lobby_card = lobby_card_scene.instance()
	lobby_card.lobby = lobby
	lobby_card.set_name(lobby.id)
	lobby_card.connect("join", self, "join_lobby")
	get_node("Body/Section/Lobbies").add_child(lobby_card)
	
func join_lobby(lobby, must_update = false):
	Store._state.lobby = lobby
	$HTTPRequest.request(Network.api_url + "/api/lobbies/" + lobby.id + "/players/", [
		"Authorization: Bearer " + Network.token
	], false, HTTPClient.METHOD_POST)
	
func _on_lobby_created(lobby):
	print(lobby)
	add_lobby_card(lobby)
	
func _on_lobby_name_updated(data):
	get_node("Body/Section/Lobbies/" + data.id).update_name(data.name)
	
func _on_lobby_removed(lobby):
	get_node("Body/Section/Lobbies/" + lobby.id).queue_free()
	
func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		add_lobby_cards(JSON.parse(body.get_string_from_utf8()).result)
	elif response_code == 201:
		Store._state.lobby = JSON.parse(body.get_string_from_utf8()).result
		get_tree().change_scene_to(lobby_scene)
	elif response_code == 204:
		Store._state.lobby.players.push_back(Store._state.player.id)
		get_tree().change_scene_to(lobby_scene)
	
