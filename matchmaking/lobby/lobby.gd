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
		, "/api/lobbies/" + Store.lobby.id
	)
	update_lobby_name()


func load_lobby(err, response_code, _headers, body):
	# todo mange error
	if err:
		ErrorHandler.network_response_error(err)
		return
	var result = JSON.parse(body.get_string_from_utf8()).result
	Store.lobby.update(result, Store.player)
	var lobby = Store.lobby
	var node = PLAYER_INFO_SCENE.instance()
	node.player = Store.player
	player_info.add_child(node)
	node.connect("player_updated", self, "_update_player")
	update_lobby_name()
	add_players_info(lobby.players)
	if lobby.owner.id == Store.player.id:
		launch_button.visible = true
		launch_button.connect("pressed", self, "launch_game")
	game_settings_container.enabled = lobby.owner.id == Store.player.id
	game_settings_container.update_game_settings_button(lobby)
	if Config.config_environement.debug_activated:
		Debug.on_lobby_ready(self)


func add_players_info(players):
	for player in players.values():
		add_player_info(player)


func add_player_info(player : Player):
	section_col.add_player(player)


func leave_lobby():
	Network.req(self, "_on_lobby_left"
		, "/api/lobbies/" + Store.lobby.id + "/players/"
		, HTTPClient.METHOD_DELETE
	)


func launch_game():
	Network.req(self, "_on_launch_response"
		, "/api/lobbies/" + Store.lobby.id + "/launch/"
		, HTTPClient.METHOD_POST
	)


func check_ready_state():
	launch_button.disabled = ! is_ready_state()


func is_ready_state():
	if Store.lobby.owner.id != Store.player.id or Store.lobby.players.size() < 2:
		return false
	var lobby_factions = []
	for player in Store.lobby.players.values():
		if player.ready == false:
			return false
		if player.faction != null and not lobby_factions.has(player.faction.id):
			lobby_factions.push_back(player.faction.id)
	return lobby_factions.size() >= 2


func update_lobby_name():
	header_name.text = Store.lobby.get_name()


func _on_player_joined(player_dict : Dictionary):
	var player = Player.new(player_dict)
	Store.lobby.players[player.id] = player
	add_player_info(player)
	check_ready_state()


func _on_player_update(player_dict : Dictionary):
	var player = Store.lobby.players[player_dict.id]
	player.update(player_dict)
	_update_player(player)


func _update_player(player: Player):
	section_col.update_player(player)
	if player.id == Store.player.id:
		player_info.get_node("PlayerInfo").update_data(player)
	if player.id == Store.lobby.owner.id:
		#Store.lobby.owner.update(player_dict)
		# normally the owner is the same ref as inside the lobby
		update_lobby_name()
	check_ready_state()


func _on_player_disconnected(player_id : String):
	section_col.remove_player(Store.lobby.get_player(player_id))
	Store.lobby.remove_player_lobby(player_id)
	check_ready_state()


func _on_lobby_launched(game_id):
	Store.player.ready = false
	Store.game_data = GameData.new(game_id, Store.player, Store.lobby)
	emit_signal("scene_requested", "game_loading")


func _on_lobby_owner_update(pid : String):
	Store.lobby.owner = Store.lobby.get_player(pid)
	update_lobby_name()
	if pid == Store.player.id:
		launch_button.visible = true
		launch_button.connect("pressed", self, "launch_game")
		check_ready_state()
	game_settings_container.enabled = (pid == Store.player.id)


func _on_launch_response(err, _response_code, _headers, _body):
	if err:
		ErrorHandler.network_response_error(err)


func _on_lobby_left(err, _response_code, _headers, _body):
	if err:
		ErrorHandler.network_response_error(err)
	Store.player.ready = false
	emit_signal("scene_requested", "menu")
