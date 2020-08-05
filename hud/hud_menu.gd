extends VBoxContainer

const assets = preload("res://resources/assets.tres")

signal back_main_menu() 


func _ready():
	Network.connect("Victory", self, "_on_victory")
	Network.connect("GameStarted", self, "_on_game_started")
	$HBoxContainer/HBoxContainer2/Button.connect("pressed",self,"_back_to_mainmenu")
	set_visible(false)


func _on_victory(data):
	set_visible(false)


func _on_game_started(game):
	$HBoxContainer/TextureRect.texture = assets.factions[Store._state.player.faction].banner
	set_visible(true)


func _back_to_mainmenu():
	emit_signal("back_main_menu")
	set_visible(false)
