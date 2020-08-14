extends Control

signal request_main_menu()

onready var menu_layer = $MenuLayer


func _ready():
	$HudMenu.connect("back_main_menu", self, "_on_back_main_menu")
	$SystemDetails.menu_layer = menu_layer
	theme = Utils.THEME_FACTION[Store._state.player.faction as int]


func _on_back_main_menu():
	emit_signal("request_main_menu")
