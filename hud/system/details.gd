extends Control

const ASSETS = preload("res://resources/assets.tres")

var fleet_details_scene = preload("res://hud/system/system_fleet_details.tscn")
var building_details_scene = preload("res://hud/system/system_building_details.tscn")

var menu_layer : MenuLayer setget set_menu_layer # injected from HUD

onready var menu_system = $MenuSystem
onready var button_building = $System/CircularContainer/Bluilding
onready var button_fleet = $System/CircularContainer/Fleet
onready var player_node = $System/CircularContainer/ContainerSystem/PlayerName


func _ready():
	Store.connect("system_selected", self, "_on_system_selected")
	Store.connect("system_update", self, "_on_system_update")
	var fleet_details = fleet_details_scene.instance()
	menu_system.add_child(fleet_details)
	button_building.connect("pressed",self,"_on_building_pressed")
	button_fleet.connect("pressed",self,"_on_fleet_pressed")


func _on_system_selected(system, _old_system):
	refresh_data(system)


func refresh_data(system):
	var faction = ASSETS.factions[0]
	player_node.text = ""
	if system.player != null:
		var player = Store.get_game_player(system.player)
		faction = ASSETS.factions[player.faction]
		player_node.text = player.username
	$System/CircularContainer/ContainerSystem/TextureRect.texture = faction.picto.system_by_kind(system.kind)
	$System/CircularContainer/ContainerSystem/TextureRect.modulate = faction.get_color(system.kind == "VictorySystem")


func set_menu_layer(new_node):
	menu_layer = new_node
	for node in menu_system.get_children():
		node.menu_layer = menu_layer


func _on_system_update(system):
	if system.id == Store._state.selected_system.id:
		refresh_data(Store._state.selected_system)


func _on_building_pressed():
	for node in menu_system.get_children():
		node.queue_free()
	if button_building.selected:
		button_fleet.selected = false
		var menu = building_details_scene.instance()
		menu.menu_layer = menu_layer
		menu_system.add_child(menu)
		


func _on_fleet_pressed():
	for node in menu_system.get_children():
		node.queue_free()
	if button_fleet.selected:
		button_building.selected = false
		var menu = fleet_details_scene.instance()
		menu.menu_layer = menu_layer
		menu_system.add_child(menu)
