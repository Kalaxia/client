extends Control

signal scene_requested(scene)

func _ready():
	$Forground/CenterH/CenterV/CreditsContainer/BackMainMenu.connect("pressed",self,"_on_back_to_main_menu")
	$Forground/CenterH/CenterV/CreditsContainer/GridContainer/LinkButtonKalaxia.connect("pressed",self,"_on_link_button_press",["https://kalaxia.org"])
	$Forground/CenterH/CenterV/CreditsContainer/GridContainer/LinkButtonDiscord.connect("pressed",self,"_on_link_button_press",["https://discord.com/invite/mDTms5c"])
	# apparently it does not load directly in scene
	$Forground/CenterH/CenterV/CreditsContainer/GridContainer/LinkButtonKalaxia.text = tr("menu.credits.website")
	$Forground/CenterH/CenterV/CreditsContainer/GridContainer/LinkButtonDiscord.text = tr("menu.credits.discord")
	
func _on_back_to_main_menu():
	emit_signal("scene_requested","menu")

func _on_link_button_press(url):
	OS.shell_open(url)
