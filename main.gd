extends Node2D

var loading_scene = preload("res://global/loading_screen.tscn")
var menu_scene = preload("res://menu/menu_screen.tscn")
var lobby_scene = preload("res://matchmaking/lobby/lobby.tscn")
var game_loading_scene = preload("res://matchmaking/game/game_loading.tscn")
var game_scene = preload("res://game/game.tscn")
var scores_scene = preload("res://game/scores.tscn")
var option_menu = preload("res://menu/menu_option.tscn")

func _ready():
	change_level(loading_scene)

func change_level(level_scene):
	for l in $Level.get_children(): l.queue_free()
	var level = level_scene.instance()
	level.connect("scene_requested", self, "_on_scene_request")
	$Level.add_child(level)

func _on_scene_request(scene):
	if scene == 'lobby':
		change_level(lobby_scene)
	elif scene == 'menu':
		change_level(menu_scene)
	elif scene == 'option_menu':
		change_level(option_menu)
	elif scene == 'game_loading':
		change_level(game_loading_scene)
	elif scene == 'game':
		change_level(game_scene)
	elif scene == "scores":
		change_level(scores_scene)
	else:
		printerr("Unknown requested scene : " + scene)

