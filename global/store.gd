extends Node

var _state = {
	"game": null,
	"lobby": null,
	"player": null
}

signal notification_added(notification)

func _ready():
	pass

func get_lobby_name(lobby):
	return 'Partie de ' + lobby.creator.username if typeof(lobby.creator) == TYPE_DICTIONARY && lobby.creator.username != '' else 'Nouvelle Partie'

func reset_player_lobby_data():
	_state.player.username = ''
	_state.player.faction = null
	_state.player.ready = false

func notify(title, content):
	print("notification")
	print(title)
	emit_signal("notification_added", {
		"title": title,
		"content": content
	})
