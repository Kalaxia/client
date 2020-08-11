extends Control


func _ready():
	Network.connect("Victory", self, "_on_victory")
	Network.connect("GameStarted", self, "_on_game_started")


func _on_victory(data):
	pass


func _on_game_started(data):
	theme = Utils.THEME_FACTION[Store._state.player.faction as int]
