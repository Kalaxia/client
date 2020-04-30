extends Control

signal join(lobby, must_update)

var lobby = null

func _ready():
	get_node("Body/Join").connect("pressed", self, "join_lobby")
	get_node('Body/Name').set_text(lobby.id)

func join_lobby():
	print("Join pressed")
	emit_signal("join", lobby, true)
