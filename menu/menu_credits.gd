extends Control

signal scene_requested(scene)

func _ready():
	$CenterContainer/VBoxContainer/BackMainMenu.connect("pressed",self,"_on_back_to_main_menu")
	$CenterContainer/VBoxContainer/GridContainer/LinkButtonKalaxia.connect("pressed",self,"_on_link_button_press",["https://kalaxia.org"])
	$CenterContainer/VBoxContainer/GridContainer/LinkButtonDiscord.connect("pressed",self,"_on_link_button_press",["https://discordapp.com/invite/hCqAcY"])

func _on_back_to_main_menu():
	emit_signal("scene_requested","menu")

func _on_link_button_press(url):
	OS.shell_open(url)
