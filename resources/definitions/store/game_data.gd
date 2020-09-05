class_name GameData
extends Resource

signal fleet_sailed(fleet, arrival_time)

const PATH_NAME = "game_data"
const ASSETS = preload("res://resources/assets.tres")

export(String) var id
export(Dictionary) var systems = {}
export(Dictionary) var players = {}
export(Resource) var player = null # CurentPlayer
export(Resource) var selected_state = SelectedState.new()
export(Resource) var scores = Scores.new()
export(Dictionary) var sailing_fleets = {}


func _init(p_id : String, player_p : Player = null, lobby : Lobby = null) -> void:
	resource_path = PATH_NAME
	self.id = p_id
	self.player = player_p
	if lobby != null:
		load_player_lobby(lobby)


func insert_system(p_system : Dictionary) -> void:
	var new_system = System.new(p_system)
	self.systems[p_system.id] = new_system
	emit_signal("changed")


func insert_player(p_player : Dictionary) -> void:
	self.players[p_player] = Player.new(p_player)
	emit_signal("changed")


func get_system(system_id : String):
	return systems[system_id] if players.has(system_id) else null


func get_player(payer_id : String):
	return players[payer_id] if players.has(payer_id) else null


func load_player_lobby(lobby : Lobby):
	for player_l in lobby.players.values():
		players[player.id] = player_l
	emit_signal("changed")


func unload_data():
	# is this needed ?
	systems.clear()
	players.clear()
	sailing_fleets.clear()
	selected_state.unselect_fleet()
	selected_state.unselect_system()
	# scores ?
	player.game = null
	player.lobby = null
	emit_signal("changed")


func is_in_range(fleet, system):
	# review
	if fleet == null or system == null:
		return false
	var coord_system_fleet = get_system(fleet.system).coordinates
	var vector_diff = Vector2(coord_system_fleet.x, coord_system_fleet.y) - Vector2(system.coordinates.x, system.coordinates.y)
	return vector_diff.length() < ASSETS.constants.fleet_range and vector_diff != Vector2.ZERO


func get_player_color(player_p : Player, is_victory_system = false) -> Color:
	# todo review
	if player_p == null :
		return Color(194.0 / 255.0, 254.0 / 255.0 , 255.0 / 255.0) if is_victory_system else Color(1.0, 1.0, 1.0)
	return player_p.faction.get_color(is_victory_system, player_p.id == player.id)


func fleet_sail(fleet, arrival_time):
	# todo determine where to move ( fleet ? )
	sailing_fleets[fleet.id] = fleet
	systems[fleet.system].fleets.erase(fleet.id)
	# todo signal
	emit_signal("fleet_sailed", fleet, arrival_time)

func request_hangar_and_building(system : System):
	# move to system
	request_hangar(system)
	request_buildings(system)


func request_hangar(system : System):
	# move to system
	Network.req(self, "_on_ship_group_received",
		"/api/games/" +
			id + "/systems/" +
			system.id + "/ship-groups/",
		HTTPClient.METHOD_GET,
		[],
		"",
		[system]
	)


func _on_ship_group_received(err, response_code, _headers, body, system : System):
	# move to system
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_OK :
		var result = JSON.parse(body.get_string_from_utf8()).result
		var hangar = []
		for i in result:
			hangar.push_back(ShipGroup.new(i))
		# test if ti works
		system.hangar = hangar


func request_buildings(system : System):
	# move to system
	Network.req(self, "_on_receive_building",
		"/api/games/" +
			id + "/systems/" +
			system.id + "/buildings/",
		HTTPClient.METHOD_GET,
		[],
		"",
		[system]
	)


func _on_receive_building(err, response_code, _headers, body, system : System):
	# move to system
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_OK :
		var result = JSON.parse(body.get_string_from_utf8()).result
		var buildings = []
		for i in result:
			buildings.push_back(Building.new(i))
		system.buildings = buildings


func update_player_me():
	# toto move player ?
	Network.req(self, "_on_me_loaded", "/api/players/me/")


func _on_me_loaded(err, response_code, _headers, body):
	# move to player ?
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_OK :
		var result = JSON.parse(body.get_string_from_utf8()).result
		player = Player.new(result) if player == null else player.load_dict(result)


func request_leave_game():
	Network.req(self, "_on_player_left_game", "/api/games/" + id + "/players/", HTTPClient.METHOD_DELETE)


func _on_player_left_game(err, _response_code, _headers, _body):
	if err:
		ErrorHandler.network_response_error(err)


static func get_game_data():
	return load(PATH_NAME)
