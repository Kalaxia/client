extends Control

signal scene_requested(scene)

func _ready():
	$Forground/CenterH/CenterV/CreditsContainer/BackMainMenu.connect("pressed",self,"_on_back_to_main_menu")
	$Forground/CenterH/CenterV/CreditsContainer/GridContainer/LinkButtonKalaxia.connect("pressed",self,"_on_link_button_press",["https://kalaxia.org"])
	$Forground/CenterH/CenterV/CreditsContainer/GridContainer/LinkButtonDiscord.connect("pressed",self,"_on_link_button_press",["https://discord.com/invite/mDTms5c"])

func _on_back_to_main_menu():
	emit_signal("scene_requested","menu")

func _on_link_button_press(url):
	OS.shell_open(url)
