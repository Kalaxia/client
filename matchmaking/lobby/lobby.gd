extends Control

var player_info_scene = preload("res://matchmaking/player/player_info.tscn")

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
	print(JSON.print(Store._state.player))
	var node = player_info_scene.instance()
	node.player = Store._state.player
	$GUI/Body/Section/Players.add_child(node)
	node.connect("player_updated", self, "_on_player_update")
	update_lobby_name()
	add_players_info(lobby.players)
	if lobby.owner.id == Store._state.player.id:
		var launch_button = get_node("GUI/Body/Footer/LaunchButton")
		launch_button.visible = true
		launch_button.connect("pressed", self, "launch_game")

func add_players_info(players):
	for player in players:
		add_player_info(player)

func add_player_info(player):
	$GUI/Body/SectionColumn.add_player(player)

func leave_lobby():
	Network.req(self, "_on_lobby_left"
		, "/api/lobbies/" + Store._state.lobby.id + "/players/"
		, HTTPClient.METHOD_DELETE
	)
	
func launch_game():
	Network.req(self, "_on_launch_response"
		, "/api/lobbies/" + Store._state.lobby.id + "/launch/"
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
	add_player_info(player)
	check_ready_state()

func _on_player_id_update(player_id):
	var player = Store.get_lobby_player(player_id)
	_on_player_update(player)

func _on_player_update(player):
	for i in range(Store._state.lobby.players.size()):
		if Store._state.lobby.players[i].id == player.id:
			Store._state.lobby.players[i] = player
	$GUI/Body/SectionColumn.update_player(player)
	if player.id == Store._state.player.id:
		$GUI/Body/Section/Players/PlayerInfo.update_data(player)
	if player.id == Store._state.lobby.owner.id:
		Store._state.lobby.owner = player
		update_lobby_name()
	check_ready_state()

func _on_player_disconnected(player_id):
	$GUI/Body/SectionColumn.remove_player(Store.get_lobby_player(player_id))
	Store.remove_player_lobby(player_id)
	check_ready_state()

func _on_lobby_launched(game_id):
	Store.reset_player_lobby_data()
	Store._state.game = { "id": game_id }
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
	pass

func _on_lobby_left(err, response_code, headers, body):
	Store.reset_player_lobby_data()
	emit_signal("scene_requested", "menu")
