extends Node2D

signal scene_requested(scene)

var system_scene = preload("res://game/map/system.tscn")
var moving_fleet_scene = preload("res://game/map/fleet_sailing.tscn")
var is_fleet_selected = false

func _ready():
	Store.connect("system_selected", self, "_on_system_selected")
	Store.connect("fleet_created", self, "_on_fleet_created")
	Store.connect("select_fleet",self,"_on_fleet_select")
	Network.connect("PlayerIncome", self, "_on_player_income")
	Network.connect("FleetCreated", self, "_on_remote_fleet_created")
	Network.connect("FleetSailed", self, "_on_fleet_sailed")
	Network.connect("FleetArrived", self, "_on_fleet_arrival")
	draw_systems()

func draw_systems():
	var map = $Map
	for i in Store._state.game.systems.keys():
		var system = system_scene.instance()
		system.set_name(Store._state.game.systems[i].id)
		system.system = Store._state.game.systems[i]
		map.add_child(system)

func add_fleet_sailing(fleet_id, system_departure_id, system_arival_id):
	var sailing_fleet = moving_fleet_scene.instance()
	sailing_fleet.set_name(fleet_id)
	get_node("Map/FleetContainer").add_child(sailing_fleet)
	var position_departure = get_node("Map/" + system_departure_id).get_position_in_parent() # todo test
	var position_arival = get_node("Map/" + system_arival_id).get_position_in_parent() # todo test
	var curve = sailing_fleet.get_node("FleetPath")
	curve.add_point(position_departure)
	curve.add_point(position_arival)
	
func _on_system_selected(system, old_system):
	if is_fleet_selected:
		# todo http request
		is_fleet_selected = false
		Store._state.selected_fleet = null 
	else:
		Store.system_selected_hud_draw(system)
		if old_system != null:
			get_node("Map/" + old_system.id).unselect()

func _on_player_income(data):
	Store.update_wallet(data.income)
	
# This method is called when the websocket notifies an another player's fleet creation
# It calls the same store method when the current player creates a new fleet
func _on_remote_fleet_created(fleet):
	Store.add_fleet(fleet)

# This method is called in both cases, to update the map's view
func _on_fleet_created(fleet):
	get_node("Map/" + fleet.system).add_fleet(fleet)

func _on_fleet_arrival(fleet):
	Store.update_fleet(fleet)
	get_node("Map/" + fleet.system).add_fleet(fleet)
	get_node("Map/FleetContainer/" + fleet.id).queue_free()

func _on_fleet_sailed(data):
	add_fleet_sailing(data.fleet_id,data.departure_system_id,data.destination_system_id)

func _on_fleet_select():
	is_fleet_selected = true
