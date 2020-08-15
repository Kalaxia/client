extends Control

signal scene_requested(scene)

const PLAYER_INFO_SCENE = preload("res://matchmaking/player/player_info.tscn")

onready var leave_button = $GUI/Body/BodyFaction/Footer/LeaveButton
onready var player_info = $GUI/Body/BodyFaction/Section/Players
onready var launch_button = $GUI/Body/BodyFaction/Footer/LaunchButton
onready var section_col = $GUI/Body/BodyFaction/SectionColumn
onready var header_name = $GUI/Body/BodyFaction/Header/Name
onready var game_settings_container = $GUI/Body/GameSettings


func _ready():
	leave_button.connect("pressed", self, "leave_lobby")
	Network.connect("PlayerJoined", self, "_on_player_joined")
	Network.connect("PlayerUpdate", self, "_on_player_update")
	Network.connect("PlayerLeft", self, "_on_player_disconnected")
	Network.connect("LobbyLaunched", self, "_on_lobby_launched")
	Network.connect("LobbyOwnerUpdated", self, "_on_lobby_owner_update")
	Network.req(self, "load_lobby"
		, "/api/lobbies/" + Store._state.lobby.id
	)
	update_lobby_name()


func load_lobby(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
		return
	var lobby = JSON.parse(body.get_string_from_utf8()).result
	Store._state.lobby = lobby
	print(JSON.print(Store._state.player))
	var node = PLAYER_INFO_SCENE.instance()
	node.player = Store._state.player
	player_info.add_child(node)
	node.connect("player_updated", self, "_on_player_update")
	update_lobby_name()
	add_players_info(lobby.players)
	if lobby.owner.id == Store._state.player.id:
		launch_button.visible = true
		launch_button.connect("pressed", self, "launch_game")
	game_settings_container.enabled = lobby.owner.id == Store._state.player.id
	game_settings_container.update_game_settings_button(lobby)


func add_players_info(players):
	for player in players:
		add_player_info(player)


func add_player_info(player):
	section_col.add_player(player)


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
	launch_button.disabled = ! is_ready_state()


func is_ready_state():
	if Store._state.lobby.owner.id != Store._state.player.id or Store._state.lobby.players.size() < 2:
		return false
	var lobby_factions = []
	for player in Store._state.lobby.players:
		if player.ready == false:
			return false
		if player.faction != null and not lobby_factions.has(int(player.faction)): # it has to be cast as an int to work
			lobby_factions.push_back(int(player.faction))
	return lobby_factions.size() >= 2


func update_lobby_name():
	header_name.set_text(Store.get_lobby_name(Store._state.lobby))


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
	section_col.update_player(player)
	if player.id == Store._state.player.id:
		player_info.get_node("PlayerInfo").update_data(player)
	if player.id == Store._state.lobby.owner.id:
		Store._state.lobby.owner = player
		update_lobby_name()
	check_ready_state()


func _on_player_disconnected(player_id):
	section_col.remove_player(Store.get_lobby_player(player_id))
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
		launch_button.visible = true
		launch_button.connect("pressed", self, "launch_game")
		check_ready_state()
	game_setings_container.enabled = (pid == Store._state.player.id)


func _on_launch_response(err, response_code, headers, body):
	pass


func _on_lobby_left(err, response_code, headers, body):
	Store.reset_player_lobby_data()
	emit_signal("scene_requested", "menu")
