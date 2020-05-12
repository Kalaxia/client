extends Control

signal scene_requested(scene)

func _ready():
	Network.connect("GameStarted", self, "_on_game_started")
	$NbPlayers.set_text(str(Store._state.game.players.size()) + " joueurs")

func _on_game_started(game):
	emit_signal("scene_requested", "game")
