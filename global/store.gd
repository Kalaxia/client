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
}

var _state = _STATE_EMPTY.duplicate(true)

signal notification_added(notification)
signal system_selected(system, old_system)
signal wallet_updated(amount)
signal fleet_created(fleet)
signal fleet_sailed(fleet)
signal fleet_selected(fleet)
signal fleet_update(fleet)
signal fleet_erased(fleet)
signal system_update(system)
signal fleet_update_nb_ships(fleet)
signal fleet_unselected()

func _ready():
	pass

func get_lobby_name(lobby):
	return 'Partie de ' + lobby.owner.username if typeof(lobby.owner) == TYPE_DICTIONARY && lobby.owner.username != '' else 'Nouvelle Partie'

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
	emit_signal("system_selected", system, _state.selected_system)
	_state.selected_system = system

func update_system(system):
	for fid in system.fleets.keys():
		if system.fleets[fid].destination_system != null:
			system.fleets.erase(fid)
	_state.game.systems[system.id] = system
	emit_signal("system_update",system)

func add_fleet(fleet):
	_state.game.systems[fleet.system].fleets[fleet.id] = fleet
	emit_signal("fleet_created", fleet)
	
func fleet_sail(fleet):
	_state.game.systems[fleet.system].fleets.erase(fleet.id)
	emit_signal("fleet_sailed", fleet)
	
func remove_player_lobby(player):
	for i in range(Store._state.lobby.players.size()):
		if Store._state.lobby.players[i].id == player.id:
			Store._state.lobby.players.remove(i)
			break
			
func update_fleet_system(fleet):
	_state.game.systems[fleet.system].fleets[fleet.id] = fleet
	emit_signal("fleet_update",fleet)

func update_fleet_nb_ships(fleet,nb_ships):
	Store._state.game.systems[fleet.system].fleets[fleet.id].nb_ships = nb_ships
	emit_signal("fleet_update_nb_ships",Store._state.game.systems[fleet.system].fleets[fleet.id])

func erase_fleet(fleet):
	Store._state.game.systems[fleet.system].fleets.erase(fleet.id)
	emit_signal("fleet_erased",fleet)

func select_fleet(fleet):
	_state.selected_fleet = fleet
	emit_signal("fleet_selected", fleet)

func unselect_fleet():
	_state.selected_fleet = null
	emit_signal("fleet_unselected")

func unload_data():
	var player = _state.player
	var factions = _state.factions
	if player != null:
		player.game = null
		player.lobby = null
	_state = _STATE_EMPTY.duplicate(true)
	_state.player = player
	_state.factions = factions

func is_in_range(fleet,system):
	# check that the system is adjacent and not equal
	# adjacent include diagonally
	if fleet == null || system == null:
		return false
	var coord_system_fleet = Store._state.game.systems[fleet.system].coordinates
	var vector_diff = Vector2(coord_system_fleet.x,coord_system_fleet.y) - Vector2(system.coordinates.x,system.coordinates.y)
	return abs(vector_diff.x) <=1.0 && abs(vector_diff.y) <=1.0 && vector_diff != Vector2.ZERO

func _get_color_faction(faction, is_current_player := false) :
	if is_current_player:
		return Color(_lighten_color(faction.color[0]) as int, _lighten_color(faction.color[1]) as int, _lighten_color(faction.color[2])as int)
	else:
		return Color(faction.color[0] as int,faction.color[1] as int,faction.color[2] as int)

func _lighten_color(color_component):
	return max( color_component+40,255)

func get_color_player(player) :
	if player == null :
		return Color(1.0,1.0,1.0)
	return _get_color_faction(Store.get_faction(player.faction),player.id == _state.player.id)
