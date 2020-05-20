extends Node

var _state = {
	"factions": {},
	"game": {},
	"lobby": null,
	"player": null,
	"selected_system": null
}

signal notification_added(notification)
signal system_selected(system, old_system)

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
	
func select_system(system):
	emit_signal("system_selected", system, Store._state.selected_system)
	Store._state.selected_system = system
	
