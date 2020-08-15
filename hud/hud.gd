extends Control

signal request_main_menu()

onready var menu_layer = $MenuLayer
onready var scores_container = $ScoresContainer
onready var hud_menu = $HudMenu


func _ready():
	$HudMenu.connect("back_main_menu", self, "_on_back_main_menu")
	$SystemDetails.menu_layer = menu_layer
	theme = Utils.THEME_FACTION[Store._state.player.faction as int]
	hud_menu.update_theme()


func _on_back_main_menu():
	emit_signal("request_main_menu")


func show_scores():
	scores_container.visible = true


func hide_scores():
	scores_container.visible = false
