extends Node2D

signal scene_requested(scene)

var system_scene = preload("res://game/map/system.tscn")

func _ready():
	draw_systems()

func draw_systems():
	var map = $Map
	for i in Store._state.game.systems.keys():
		var system = system_scene.instance()
		system.set_name(Store._state.game.systems[i].id)
		system.system = Store._state.game.systems[i]
		$Map.add_child(system)
