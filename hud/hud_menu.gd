extends VBoxContainer

signal back_main_menu() 

func _ready():
	Network.connect("Victory", self, "_on_victory")
	Network.connect("GameStarted", self, "_on_game_started")
	$Button.connect("pressed",self,"_back_to_mainmenu")
	set_visible(false)


func _on_victory():
	set_visible(false)


func _on_game_started(game):
	set_visible(true)

func _back_to_mainmenu():
	emit_signal("back_main_menu")
	set_visible(false)
