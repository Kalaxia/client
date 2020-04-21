extends Control

var lobby = null

func _ready():
	print(lobby)
	get_node('Body/Name').set_text(lobby.id)
