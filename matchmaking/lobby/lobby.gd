extends Control

var player_info_scene = load("res://matchmaking/player/player_info.tscn")

signal scene_requested(scene)

func _ready():
	get_node("GUI/Body/Header/Name").set_text("Votre Partie")
	get_node("GUI/Body/Footer/LeaveButton").connect("pressed", self, "leave_lobby")
	Network.connect("PlayerJoined", self, "_on_player_joined")
	Network.connect("PlayerUpdate", self, "_on_player_update")
	Network.connect("PlayerLeft", self, "_on_player_disconnected")
	Network.connect("LobbyLaunched", self, "_on_lobby_launched")
	Network.connect("LobbyOwnerUpdated", self, "_on_lobby_owner_update")
	Network.req(self, "load_lobby"
		, "/api/lobbies/" + Store._state.lobby.id
	)

func load_lobby(err, response_code, headers, body):
	print("LOADING LOBBY")
	if err:
		ErrorHandler.network_response_error(err)
		return
	var lobby = JSON.parse(body.get_string_from_utf8()).result
	Store._state.lobby = lobby
	update_lobby_name()
	add_players_info(lobby.players)
	if lobby.owner.id == Store._state.player.id:
		var launch_button = get_node("GUI/Body/Footer/LaunchButton")
		launch_button.visible = true
		launch_button.connect("pressed", self, "launch_game")
	
func add_players_info(players):
	var list = get_node("GUI/Body/Section/PlayersContainer/Players")
	for player in players:
		add_player_info(list, player)

func add_player_info(list, player):
	var player_info = player_info_scene.instance()
	player_info.set_name(player.id)
	player_info.player = player
	
	if player.id == Store._state.player.id:
		player_info.connect("player_updated", self, "_on_player_update")
	list.add_child(player_info)

func leave_lobby():
	Network.req(self, "_on_lobby_left"
		, "/api/lobbies/" + Store._state.lobby.id + "/players/"
		, HTTPClient.METHOD_DELETE
	)
	
func launch_game():
	Network.req(self, "_on_launch_response"
		, "/api/lobbies" + Store._state.lobby.id + "/launch/"
		, HTTPClient.METHOD_POST
	)

func check_ready_state():
	get_node("GUI/Body/Footer/LaunchButton").disabled = ! is_ready_state()

func is_ready_state():
	if Store._state.lobby.owner.id != Store._state.player.id || Store._state.lobby.players.size() < 2:
		return false
	var lobby_factions = []
	for player in Store._state.lobby.players:
		if player.ready == false:
			return false
		if player.faction != null && ! lobby_factions.has(int(player.faction)): # it has to be cast as an int to work
			lobby_factions.push_back(int(player.faction))
	return lobby_factions.size() >= 2

func update_lobby_name():
	get_node("GUI/Body/Header/Name").set_text(Store.get_lobby_name(Store._state.lobby))

func _on_player_joined(player):
	Store._state.lobby.players.push_back(player)
	add_player_info(get_node("GUI/Body/Section/PlayersContainer/Players"), player)
	check_ready_state()

func _on_player_update(player):
	for i in range(Store._state.lobby.players.size()):
		if Store._state.lobby.players[i].id == player.id:
			Store._state.lobby.players[i] = player
	get_node("GUI/Body/Section/PlayersContainer/Players/" + player.id).update_data(player)
	if player.id == Store._state.lobby.owner.id:
		Store._state.lobby.owner = player
		update_lobby_name()
	check_ready_state()

func _on_player_disconnected(player):
	get_node("GUI/Body/Section/PlayersContainer/Players/" + player.id).queue_free()
	Store.remove_player_lobby(player)
	check_ready_state()

func _on_lobby_launched(game):
	Store.reset_player_lobby_data()
	Store._state.game = game
	emit_signal("scene_requested", "game_loading")
	
func _on_lobby_owner_update(pid):
	Store._state.lobby.owner = Store.get_lobby_player(pid)
	update_lobby_name()
	if pid == Store._state.player.id:
		var launch_button = get_node("GUI/Body/Footer/LaunchButton")
		launch_button.visible = true
		launch_button.connect("pressed", self, "launch_game")
		check_ready_state()
	
func _on_launch_response(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)

func _on_lobby_left(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
		return
	Store.reset_player_lobby_data()
	emit_signal("scene_requested", "menu")
	
