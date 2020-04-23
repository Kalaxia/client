extends Control

var lobby_card_scene = preload("res://lobby_card.tscn")

func _ready():
	$HTTPRequest.connect("request_completed", self, "_on_request_completed")
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
	var lobby_card = lobby_card_scene.instance()
	lobby_card.lobby = lobby
	get_node("Body/Section/Lobbies").add_child(lobby_card)
	
func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	if response_code == 200:
		add_lobby_cards(json.result)
	elif response_code == 201:
		add_lobby_card(json.result)
	
