extends Control

signal scene_requested(scene)

onready var main_menu_button = $ButtonsContainer/MainMenu


func _ready():
	main_menu_button.connect("pressed", self, "_on_back_to_main_menu")


func _on_back_to_main_menu():
	Config.save_config_file()
	Config.reload_locale()
	emit_signal("scene_requested", "menu")
