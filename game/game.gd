extends Node2D

signal scene_requested(scene)

var system_scene = preload("res://game/map/system.tscn")

func _ready():
	Store.connect("system_selected", self, "_on_system_selected")
	Network.connect("PlayerIncome", self, "_on_player_income")
	draw_systems()

func draw_systems():
	var map = $Map
	for i in Store._state.game.systems.keys():
		var system = system_scene.instance()
		system.set_name(Store._state.game.systems[i].id)
		system.system = Store._state.game.systems[i]
		map.add_child(system)

func _on_system_selected(system, old_system):
	if old_system != null:
		get_node("Map/" + old_system.id).unselect()

func _on_player_income(data):
	Store.update_wallet(data.income)
