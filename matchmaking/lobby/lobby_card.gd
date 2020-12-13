extends Control

signal join(lobby)

var lobby : Lobby = null


func _ready():
	print_stack()
	$Body/Join.connect("pressed", self, "join_lobby")
	set_lobby_name()
	set_nb_players()


func set_lobby_name():
	$Body/Name.text = lobby.get_name()


func set_nb_players():
	$Body/Section/Players.text = tr("menu.lobby_card.player_count %d %d") % [lobby.players.size(), 12]


func join_lobby():
	print_stack()
	emit_signal("join", lobby)


func update_name(name):
	lobby.owner.username = name
	set_lobby_name()


func add_player(player : Player):
	lobby.players[player.id] = player
	set_nb_players()


func remove_player(player_id):
	lobby.remove_player_lobby(player_id)
	set_nb_players()
