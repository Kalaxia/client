extends Control

var lobby_card_scene = preload("res://lobby_card.tscn")
var token = ""

func _ready():
	get_node("Body/Footer/LobbyCreationButton").connect("button_down", self, "create_lobby")
	$HTTPRequest.connect("request_completed", self, "_on_request_completed")
	auth()
	
func auth():
	$HTTPRequest.request("http://127.0.0.1:8080/login", [], false, HTTPClient.METHOD_POST)
	
func get_lobbies():
	$HTTPRequest.request("http://127.0.0.1:8080/api/lobbies/", [
		"Authorization: Bearer " + token
	])
	
func create_lobby():
	$HTTPRequest.request("http://127.0.0.1:8080/api/lobbies/", [
		"Authorization: Bearer " + token
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
		if json.result.has('token'):
			token = json.result.token
			get_lobbies()
		else:
			add_lobby_cards(json.result)
	elif response_code == 201:
		add_lobby_card(json.result)
