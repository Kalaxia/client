extends Control

var menu_scene = load("res://menu/menu_screen.tscn")
var player_info_scene = load("res://matchmaking/lobby/player_info.tscn")

func _ready():
	get_node("Body/Header/Name").set_text("Votre Partie")
	get_node("Body/Footer/LeaveButton").connect("pressed", self, "leave_lobby")
	$HTTPRequest.connect("request_completed", self, "load_lobby")
	Network.connect("PlayerJoined", self, "_on_player_joined")
	Network.connect("PlayerUpdate", self, "_on_player_update")
	Network.connect("PlayerDisconnected", self, "_on_player_disconnected")
	$HTTPRequest.request(Network.api_url + "/api/lobbies/" + Store._state.lobby.id, [
		"Authorization: Bearer " + Network.token
	], false, HTTPClient.METHOD_GET)

func load_lobby(result, response_code, headers, body):
	var lobby = JSON.parse(body.get_string_from_utf8()).result
	Store._state.lobby = lobby
	get_node("Body/Header/Name").set_text(Store.get_lobby_name(lobby))
	add_players_info(lobby.players)
	
func add_players_info(players):
	var list = get_node("Body/Section/PlayersContainer/Players")
	for player in players:
		add_player_info(list, player)

func add_player_info(list, player):
	var player_info = player_info_scene.instance()
	player_info.set_name(player.id)
	player_info.player = player
	list.add_child(player_info)

func leave_lobby():
	$HTTPRequest.connect("request_completed", self, "_on_lobby_left")
	$HTTPRequest.request(Network.api_url + "/api/lobbies/" + Store._state.lobby.id + "/players/", [
		"Authorization: Bearer " + Network.token
	], false, HTTPClient.METHOD_DELETE)

func _on_player_joined(player):
	add_player_info(get_node("Body/Section/PlayersContainer/Players"), player)

func _on_player_update(player):
	get_node("Body/Section/PlayersContainer/Players/" + player.id).update_data(player)

func _on_player_disconnected(player):
	get_node("Body/Section/PlayersContainer/Players/" + player.id).queue_free()

func _on_lobby_left(result, response_code, headers, body):
	Store.reset_player_lobby_data()
	get_tree().change_scene_to(menu_scene)
	
