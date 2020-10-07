class_name GameData
extends Resource

signal fleet_sailed(fleet) # todo move copy in system and fleet
signal score_updated()
signal fleet_arrived(fleet)

const ASSETS = preload("res://resources/assets.tres")

export(String) var id
export(Dictionary) var systems
export(Dictionary) var players
export(Resource) var player # CurentPlayer
export(Resource) var selected_state
export(Dictionary) var scores
export(Dictionary) var sailing_fleets


func _init(game_id : String, player_p : Player, lobby : Lobby = null) -> void:
	self.id = game_id
	player = player_p
	if lobby != null:
		load_player_lobby(lobby)
	selected_state = SelectedState.new()
	players[player_p.id] = player_p


func insert_system(p_system : Dictionary) -> void:
	var new_system = System.new(p_system)
	systems[p_system.id] = new_system
	if does_belong_to_current_player(new_system):
		request_hangar(new_system)
	if new_system.player != null and players[new_system.player].faction.id == player.faction.id:
		request_buildings(new_system)
	emit_signal("changed")


func set_players(player_array : Array):
	for p in player_array:
		if p.id != player.id:
			insert_player(p)
		else:
			players[player.id] = player
			player.update(p)
			# no need to inster it as it should already in players (see contructor)
	emit_signal("changed")


func insert_player(p_player : Dictionary) -> void:
	if players.has(p_player.id):
		players[p_player.id].update(p_player)
	else:
		players[p_player.id] = Player.new(p_player)


func get_system(system_id : String):
	return systems[system_id] if systems.has(system_id) else null


func get_player(payer_id : String):
	return players[payer_id] if players.has(payer_id) else null


func get_fleet(fleet : Dictionary):
	return sailing_fleets[fleet.id] \
			if sailing_fleets.has(fleet.id) \
			else get_system(fleet.system).get_fleet(fleet.id)


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
#	# scores ?
	player = null
	scores.clear()
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


func fleet_sail(fleet : Fleet):
	sailing_fleets[fleet.id] = fleet
	systems[fleet.system].fleets.erase(fleet.id)
	emit_signal("fleet_sailed", fleet)


func update_fleet_arrival(fleet_dict : Dictionary):
	var fleet : Fleet = get_fleet(fleet_dict)
	fleet.update_fleet(fleet_dict)
	if sailing_fleets.has(fleet.id):
		sailing_fleets.erase(fleet.id)
	get_system(fleet.system).fleet_arrive(fleet)
	emit_signal("fleet_arrived", fleet)


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
		if player == null:
			player = Player.new(result)
		else:
			player.update(result)


func request_leave_game():
	Network.req(self, "_on_player_left_game", "/api/games/" + id + "/players/", HTTPClient.METHOD_DELETE)


func _on_player_left_game(err, _response_code, _headers, _body):
	if err:
		ErrorHandler.network_response_error(err)


func is_current_player(player_p : Player):
	return player_p.id == player.id


func does_belong_to_current_player(resource):
	if resource == null:
		return false
	return resource.player == player.id


func update_scores(scores_new) -> void:
	scores.clear()
	if scores_new is Dictionary:
		for key in scores_new.keys():
			if scores.has(key as int):
				scores[key as int].load_dict(scores_new[key])
			else:
				scores[key as int] = ScoreFaction.new(scores_new[key])
	elif scores_new is Array:
		for score in scores_new:
			if scores.has(score.faction as int):
				scores[score.faction as int].load_dict(score)
			else:
				scores[score.faction] = ScoreFaction.new(score)
	else:
		printerr("update score with invalide data type")
	emit_signal("changed")
	emit_signal("score_updated")
