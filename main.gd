extends Node2D

var loading_scene = preload("res://global/loading_screen.tscn")
var menu_scene = preload("res://menu/menu_screen.tscn")
var lobby_scene = preload("res://matchmaking/lobby/lobby.tscn")

func _ready():
	Network.connect("authenticated", self, "_on_authentication")
	change_level(loading_scene)

func change_level(level_scene):
	for l in $Level.get_children():
		l.queue_free()
	var level = level_scene.instance()
	level.connect("scene_requested", self, "_on_scene_request")
	$Level.add_child(level)

func _on_scene_request(scene):
	if scene == 'lobby':
		change_level(lobby_scene)
	elif scene == 'menu':
		change_level(menu_scene)

func _on_authentication():
	change_level(menu_scene)
