extends Control

var fleet = null

func _ready():
	$Player.set_text(Store.get_game_player(fleet.player).username)
