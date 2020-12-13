extends Control

signal request_main_menu()

const ASSETS = preload("res://resources/assets.tres")

var _game_data = Store.game_data

onready var menu_layer = $MenuLayer
onready var hud_menu = $HudMenu


func _ready():
	print_stack()
	$HudMenu.connect("back_main_menu", self, "_on_back_main_menu")
	$SystemDetails.menu_layer = menu_layer
	hud_menu.menu_layer = menu_layer
	theme = _game_data.player.faction.theme
	hud_menu.update_theme()


func _on_back_main_menu():
	print_stack()
	emit_signal("request_main_menu")
