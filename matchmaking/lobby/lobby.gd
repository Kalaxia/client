extends Control

var menu_scene = load("res://menu/menu_screen.tscn")
var player_info_scene = load("res://matchmaking/lobby/player_info.tscn")

func _ready():
	get_node("Body/Header/Name").set_text(Store._state.lobby.id)
	get_node("Body/Footer/LeaveButton").connect("pressed", self, "leave_lobby")
	$HTTPRequest.connect("request_completed", self, "load_lobby")
	$HTTPRequest.request(Network.api_url + "/api/lobbies/" + Store._state.lobby.id, [
		"Authorization: Bearer " + Network.token
	], false, HTTPClient.METHOD_GET)

func load_lobby(result, response_code, headers, body):
	var lobby = JSON.parse(body.get_string_from_utf8()).result
	print(lobby)
	Store._state.lobby = lobby
	add_players_info(lobby.players)

func add_players_info(players):
	var list = get_node("Body/Section/PlayersContainer/Players")
	for player in players:
		var player_info = player_info_scene.instance()
		player_info.set_name(player.id)
		player_info.player = player
		list.add_child(player_info)

func leave_lobby():
	$HTTPRequest.connect("request_completed", self, "_on_lobby_left")
	$HTTPRequest.request(Network.api_url + "/api/lobbies/" + Store._state.lobby.id + "/players/", [
		"Authorization: Bearer " + Network.token
	], false, HTTPClient.METHOD_DELETE)

func _on_lobby_left(result, response_code, headers, body):
	
	get_tree().change_scene_to(menu_scene)
	
