extends Control

signal join(lobby, must_update)

var lobby = null

func _ready():
	get_node("Body/Join").connect("pressed", self, "join_lobby")
	set_lobby_name()
	
func set_lobby_name():
	get_node('Body/Name').set_text(Store.get_lobby_name(lobby))

func join_lobby():
	emit_signal("join", lobby, true)

func update_name(name):
	lobby.creator = {
		"id": lobby.creator if typeof(lobby.creator) == TYPE_STRING else lobby.creator.id,
		"username": name
	}
	set_lobby_name()
	
