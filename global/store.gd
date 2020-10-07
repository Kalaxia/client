extends Node

signal notification_added(notification)
signal system_selected(system, old_system)
signal wallet_updated(amount)
signal fleet_created(fleet)
signal fleet_sailed(fleet, arrival_time )
signal fleet_selected(fleet)
signal fleet_update(fleet)
signal fleet_erased(fleet)
signal system_update(system)
signal fleet_update_nb_ships(fleet)
signal fleet_unselected()
signal hangar_updated(system, ship_groups)
signal building_updated(system)
signal fleet_owner_updated(fleet)

const _STATE_EMPTY = {
	#"factions": {},
	"game": {},
	"lobby": null,
	"player": null,
	"selected_system": null,
	"selected_fleet": null,
	"scores": {},
	"victorious_faction": null,
	#"ship_models" : [],
	#"building_list" : [],
}

var _state = _STATE_EMPTY.duplicate(true)
var assets : KalaxiaAssets = preload("res://resources/assets.tres") 

func _ready():
	pass


func update_assets(cached_data : CachedResource):
	assets.load_data_from_cached(cached_data)


static func get_lobby_name(lobby):
	return TranslationServer.translate('store.game_of %s') % lobby.owner.username \
			if typeof(lobby.owner) == TYPE_DICTIONARY and lobby.owner.username != '' \
			else TranslationServer.translate('store.new_game')


func get_lobby_player(pid):
	for p in _state.lobby.players:
		if p.id == pid:
			return p


func get_system(system_id):
	return _state.game.systems[system_id]


func update_fleet_owner(fleet, player_id):
	var updated_fleet = _state.game.systems[fleet.system].fleets[fleet.id]
	updated_fleet.player = player_id
	emit_signal("fleet_owner_updated", updated_fleet)


func reset_player_lobby_data():
	_state.player.ready = false


func notify(title, content):
	emit_signal("notification_added", {
		"title": title,
		"content": content
	})


func get_faction(id):
	#todo remove
	return assets.factions[id]


func set_game_players(players):
	_state.game.players = {}
	for player in players:
		_state.game.players[player.id] = player


func get_game_player(id):
	return _state.game.players[id]


func update_wallet(new_amount):
	_state.player.wallet += new_amount
	emit_signal("wallet_updated", _state.player.wallet)


func select_system(system):
	# _state.selected_system is the old system
	var old_system = _state.selected_system
	_state.selected_system = system
	emit_signal("system_selected", system, old_system)


func update_system(s):
	var system = _state.game.systems[s.id]
	for fid in system.fleets.keys():
		if system.fleets[fid].destination_system != null:
			system.fleets.erase(fid)
	system.player = s.player
	emit_signal("system_update", system)


func add_fleet(fleet):
	_state.game.systems[fleet.system].fleets[fleet.id] = fleet
	emit_signal("fleet_created", fleet)


func fleet_sail(fleet, arrival_time ):
	_state.game.systems[fleet.system].fleets.erase(fleet.id)
	emit_signal("fleet_sailed", fleet, arrival_time)


func remove_player_lobby(player_id):
	for i in range(Store._state.lobby.players.size()):
		if Store._state.lobby.players[i].id == player_id:
			Store._state.lobby.players.remove(i)
			break


func update_fleet_system(fleet):
	_state.game.systems[fleet.system].fleets[fleet.id] = fleet
	emit_signal("fleet_update",fleet)


func update_fleet_nb_ships(fleet, ship_category, nb_ships):
	if not Store._state.game.systems[fleet.system].fleets.has(fleet.id) :
		return
	var fleet_in_store = Store._state.game.systems[fleet.system].fleets[fleet.id]
	var has_updated_number = false
	for ship_group in fleet_in_store.ship_groups:
		if ship_group.category == ship_category:
			ship_group.quantity = nb_ships
			has_updated_number = true
	if not has_updated_number:
		fleet_in_store.ship_groups.push_back({
			"category" : ship_category, 
			"quantity" : nb_ships,
			"fleet" : fleet_in_store.id,
			"system": fleet_in_store.system,
		})
	emit_signal("fleet_update_nb_ships", fleet_in_store)


func update_fleet_ship_groups(fleet, ship_groups):
	if not Store._state.game.systems[fleet.system].fleets.has(fleet.id) :
		return
	var fleet_in_store = Store._state.game.systems[fleet.system].fleets[fleet.id]
	fleet_in_store.ship_groups = ship_groups
	emit_signal("fleet_update_nb_ships", fleet_in_store)


func erase_fleet(fleet):
	Store._state.game.systems[fleet.system].fleets.erase(fleet.id)
	emit_signal("fleet_erased", fleet)


func erase_all_fleet_system(system):
	Store._state.game.systems[system.id].fleets.clear()


func select_fleet(fleet):
	_state.selected_fleet = fleet
	emit_signal("fleet_selected", fleet)


func unselect_fleet():
	_state.selected_fleet = null
	emit_signal("fleet_unselected")


func unload_data():
	var player = _state.player
	if player != null:
		player.game = null
		player.lobby = null
	_state = _STATE_EMPTY.duplicate(true)
	_state.player = player


func is_in_range(fleet,system):
	# check that the system is adjacent and not equal
	# adjacent include diagonally
	if fleet == null or system == null:
		return false
	var coord_system_fleet = Store._state.game.systems[fleet.system].coordinates
	var vector_diff = Vector2(coord_system_fleet.x, coord_system_fleet.y) - Vector2(system.coordinates.x, system.coordinates.y)
	return vector_diff.length() < assets.constants.fleet_range and vector_diff != Vector2.ZERO


func _get_faction_color(faction, is_victory_system = false, is_current_player = false) :
	var color = faction.get_color()
	if is_current_player:
		color = Utils.lighten_color(color)
	if is_victory_system:
		color = Utils.lighten_color(color)
	return color


func get_player_color(player,is_victory_system = false) :
	if player == null :
		return Color(194.0 / 255.0, 254.0 / 255.0 , 255.0 / 255.0) if is_victory_system else Color(1.0, 1.0, 1.0)
	return _get_faction_color(assets.factions[player.faction], is_victory_system, player.id == _state.player.id)


func update_scores(scores):
	_state.scores = scores


func update_system_buildings(system_id, buildings):
	_state.game.systems[system_id].buildings = buildings
	emit_signal("building_updated", _state.game.systems[system_id])


func update_system_hangar(system_id, ship_groups):
	print(ship_groups)
	_state.game.systems[system_id].hangar = ship_groups
	emit_signal("hangar_updated", _state.game.systems[system_id], ship_groups)


func update_hangar(system, ship_groups):
	update_system_hangar(system.id, ship_groups)


func update_buildings(system, buildings):
	update_system_buildings(system.id, buildings)


func add_building_to_system(system, building):
	add_building_to_system_by_id(system.id, building)


func add_ship_group_to_hangar(ship_group):
	var hangar_ship_groups = []
	if _state.game.systems[ship_group.system].has("hangar") and _state.game.systems[ship_group.system].hangar == null:
		hangar_ship_groups.push_back(ship_group)
	else:
		var has_added_ships = false
		hangar_ship_groups = _state.game.systems[ship_group.system].hangar if _state.game.systems[ship_group.system].has("hangar") else []
		for i in hangar_ship_groups:
			if i.category ==  ship_group.category:
				i.quantity += ship_group.quantity
				has_added_ships = true
				break
		if not has_added_ships:
			hangar_ship_groups.push_back(ship_group)
	update_system_hangar(ship_group.system, hangar_ship_groups)


func add_building_to_system_by_id(system_id, building):
	var total_buildings = _state.game.systems[system_id].buildings if _state.game.systems[system_id].has("buildings") else []
	if total_buildings == null:
		total_buildings = [building]
	else:
		var has_building = false
		for i in range(total_buildings.size()):
			if total_buildings[i].id == building.id:
				total_buildings[i] = building
				has_building = true
				break
		if not has_building:
			total_buildings.push_back(building)
	update_buildings(_state.game.systems[system_id], total_buildings)


func request_hangar_and_building(system):
	request_hangar(system)
	request_buildings(system)


func request_hangar(system):
	Network.req(self, "_on_ship_group_received",
		"/api/games/" +
			_state.game.id + "/systems/" +
			system.id + "/ship-groups/",
		HTTPClient.METHOD_GET,
		[],
		"",
		[system.id]
	)


func request_buildings(system):
	Network.req(self, "_on_receive_building",
		"/api/games/" +
			Store._state.game.id + "/systems/" +
			system.id + "/buildings/",
		HTTPClient.METHOD_GET,
		[],
		"",
		[system.id]
	)


func _on_ship_group_received(err, response_code, headers, body, system_id):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_OK :
		var result = JSON.parse(body.get_string_from_utf8()).result
		update_system_hangar(system_id, result)


func _on_receive_building(err, response_code, headers, body, system_id):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_OK :
		var result = JSON.parse(body.get_string_from_utf8()).result
		update_system_buildings(system_id, result)


func update_player_me():
	Network.req(self, "_on_me_loaded", "/api/players/me/")


func _on_me_loaded(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_OK :
		var result = JSON.parse(body.get_string_from_utf8()).result
		_state.player = result
		emit_signal("wallet_updated", _state.player.wallet)


func request_leave_game():
	Network.req(self, "_on_player_left_game", "/api/games/" + Store._state.game.id + "/players/", HTTPClient.METHOD_DELETE)


func _on_player_left_game(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
