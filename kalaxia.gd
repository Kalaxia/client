extends Node

var lobby_card_scene = preload("res://lobbycard.tscn")
var lobbies = [];

func _ready():
	$Button.connect("button_down", self, "create_lobby")
	$HTTPRequest.connect("request_completed", self, "_on_request_completed")
	get_lobbies()
	
func get_lobbies():
	$HTTPRequest.request("http://127.0.0.1:8080/lobbies/")
	
func create_lobby():
	$HTTPRequest.request("http://127.0.0.1:8080/lobbies/", [], false, HTTPClient.METHOD_POST)
	
func display_lobbies(l):
	lobbies = l
	for lobby in lobbies:
		add_lobby_card(lobby)

func display_lobby(l):
	lobbies.push_back(l)
	add_lobby_card(l)
	
func add_lobby_card(lobby):
	var lobby_card = lobby_card_scene.instance()
	lobby_card.lobby = lobby
	$Lobbies.add_child(lobby_card)
	
func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	if response_code == 200:
		display_lobbies(json.result)
	elif response_code == 201:
		display_lobby(json.result)
