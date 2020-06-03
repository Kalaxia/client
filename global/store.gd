extends Node

var _state = {
	"factions": {},
	"game": {},
	"lobby": null,
	"player": null,
	"selected_system": null,
	"selected_fleet": null,
	"scores": {},
	"victorious_faction": null,
}

signal notification_added(notification)
signal system_selected(system, old_system)
signal wallet_updated(amount)
signal fleet_created(fleet)
signal fleet_sailed(fleet)

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

func select_fleet(fleet):
	_state.selected_fleet = fleet

func unselect_fleet():
	_state.selected_fleet = null
