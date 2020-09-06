extends Control

signal join(lobby)

var lobby : Lobby = null
var nb_players = 0


func _ready():
	$Body/Join.connect("pressed", self, "join_lobby")
	set_lobby_name()
	nb_players = lobby.players.size()
	set_nb_players()


func set_lobby_name():
	$Body/Name.text = lobby.get_name()


func set_nb_players():
	$Body/Section/Players.text = tr("menu.lobby_card.player_count %d %d") % [nb_players, 12]


func increment_nb_players():
	# todo modifiy
	nb_players = nb_players + 1
	set_nb_players()


func decrement_nb_players():
	# todo modifiy
	nb_players = nb_players - 1
	set_nb_players()


func join_lobby():
	emit_signal("join", lobby)


func update_name(name):
	lobby.owner.username = name
	set_lobby_name()
