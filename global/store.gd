extends Node

var _state = {
	"factions": {},
	"game": {},
	"lobby": null,
	"player": null,
	"selected_system": null,
	"selected_fleet":null,
}

signal notification_added(notification)
signal system_selected(system, old_system)
signal wallet_updated(amount)
signal fleet_created(fleet)
signal FleetSailed(fleet)

func _ready():
	pass


func get_lobby_name(lobby):
	return 'Partie de ' + lobby.creator.username if typeof(lobby.creator) == TYPE_DICTIONARY && lobby.creator.username != '' else 'Nouvelle Partie'

func reset_player_lobby_data():
	_state.player.username = ''
	_state.player.faction = null
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
	emit_signal("system_selected", system, _state.selected_system)
	_state.selected_system = system
	# _state.selected_system is the old system
	
func add_fleet(fleet):
	_state.game.systems[fleet.system].fleets[fleet.id] = fleet
	emit_signal("fleet_created", fleet)
	
func remove_player_lobby(player):
	for i in range(Store._state.lobby.players.size()):
		if Store._state.lobby.players[i].id == player.id:
			Store._state.lobby.players.remove(i)
			break
			
func update_fleet(fleet):
	if ! _state.game.systems[fleet.system].fleets.has(fleet.id):
		# relink the fleet to the correct system
		for system in _state.game.systems:
			if system.fleets.has(fleet.id):
				system.fleets.erase(fleet.id)
	_state.game.systems[fleet.system].fleets[fleet.id] = fleet


func select_fleet(fleet):
	_state.selected_fleet = fleet

func unselect_fleet():
	_state.selected_fleet = null
