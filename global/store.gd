extends Node

const _STATE_EMPTY = {
	"factions": {},
	"game": {},
	"lobby": null,
	"player": null,
	"selected_system": null,
	"selected_fleet": null,
	"scores": {},
	"victorious_faction": null,
	"ship_models" : [
		{
			"category": "fighter",
			"construction_time": 400,
			"cost": 20,
			"damage": 15,
			"hit_points": 10,
			"precision": 60,
		},
		{
			"category": "corvette",
			"construction_time": 1500,
			"cost": 140,
			"damage": 40,
			"hit_points": 60,
			"precision": 45,
		},
		{
			"category": "frigate",
			"construction_time": 2000,
			"cost": 250,
			"damage": 25,
			"hit_points": 100,
			"precision": 50,
		},
		{
			"category": "cruiser",
			"construction_time": 7000,
			"cost": 600,
			"damage": 80,
			"hit_points": 200,
			"precision": 45,
		},
	],
}

var _state = _STATE_EMPTY.duplicate(true)

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

func _ready():
	pass

func get_lobby_name(lobby):
	return tr('store.game_of') % lobby.owner.username if typeof(lobby.owner) == TYPE_DICTIONARY && lobby.owner.username != '' else tr('store.new_game')

func get_lobby_player(pid):
	for p in _state.lobby.players:
		if p.id == pid:
			return p

func reset_player_lobby_data():
	_state.player.ready = false

func notify(title, content):
	emit_signal("notification_added", {
		"title": title,
		"content": content
	})

func set_factions(factions):
	_state.factions = {}
	for faction in factions:
		_state.factions[faction.id] = faction
		
func get_faction(id):
	return _state.factions[id]
	
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
	emit_signal("fleet_erased",fleet)

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
	var factions = _state.factions
	var ship_models = _state.ship_models
	if player != null:
		player.game = null
		player.lobby = null
	_state = _STATE_EMPTY.duplicate(true)
	_state.player = player
	_state.factions = factions
	_state.ship_models = ship_models

func is_in_range(fleet,system):
	# check that the system is adjacent and not equal
	# adjacent include diagonally
	if fleet == null || system == null:
		return false
	var coord_system_fleet = Store._state.game.systems[fleet.system].coordinates
	var vector_diff = Vector2(coord_system_fleet.x, coord_system_fleet.y) - Vector2(system.coordinates.x, system.coordinates.y)
	return vector_diff.length() < Utils.FLEET_RANGE && vector_diff != Vector2.ZERO

func _get_faction_color(faction, is_victory_system = false, is_current_player = false) :
	var color = Color(faction.color[0] / 255.0, faction.color[1] / 255.0, faction.color[2] / 255.0)
	if is_current_player:
		color = Utils.lighten_color(color)
	if is_victory_system:
		color = Utils.lighten_color(color)
	return color

func get_player_color(player,is_victory_system = false) :
	if player == null :
		return Color(194.0 / 255.0, 254 / 255.0 , 255.0 / 255.0) if is_victory_system else Color(1.0,1.0,1.0)
	return _get_faction_color(Store.get_faction(player.faction), is_victory_system, player.id == _state.player.id)

func update_scores(scores):
	_state.scores = scores
