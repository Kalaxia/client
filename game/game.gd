extends Node2D

signal scene_requested(scene)

var system_scene = preload("res://game/map/system.tscn")
var moving_fleet_scene = preload("res://game/map/fleet_sailing.tscn")

func _ready():
	Store.connect("system_selected", self, "_on_system_selected")
	Store.connect("fleet_created", self, "_on_fleet_created")
	Store.connect("fleet_sailed", self, "_on_fleet_sailed")
	Network.connect("CombatEnded", self, "_on_combat_ended")
	Network.connect("PlayerIncome", self, "_on_player_income")
	Network.connect("FleetCreated", self, "_on_remote_fleet_created")
	Network.connect("FleetSailed", self, "_on_remote_fleet_sailed")
	Network.connect("FleetArrived", self, "_on_fleet_arrival")
	Network.connect("SystemConquerred", self, "_on_system_conquerred")
	Network.connect("Victory", self, "_on_victory")
	draw_systems()

func draw_systems():
	var map = $Map
	for i in Store._state.game.systems.keys():
		var system = system_scene.instance()
		system.set_name(Store._state.game.systems[i].id)
		system.system = Store._state.game.systems[i]
		map.add_child(system)

func add_fleet_sailing(fleet):
	var sailing_fleet = moving_fleet_scene.instance()
	sailing_fleet.set_name(fleet.id)
	var origin_system = get_node("Map/" + fleet.system)
	origin_system.refresh()
	sailing_fleet.color = Store.get_faction(Store.get_game_player(fleet.player).faction).color
	sailing_fleet.origin_position = origin_system.get_position() # todo test
	sailing_fleet.destination_position = get_node("Map/" + fleet.destination_system).get_position() # todo test
	get_node("Map/FleetContainer").add_child(sailing_fleet)
	
func update_fleet_system(fleet):
	Store.update_fleet_system(fleet)
	get_node("Map/" + fleet.system).refresh_fleet_pins()
	get_node("Map/FleetContainer/" + fleet.id).queue_free()
	
func _on_combat_ended(data):
	for fleet in data.fleets.values():
		if fleet.destination_system != null:
			get_node("Map/FleetContainer/" + fleet.id).queue_free()
		if fleet.nb_ships == 0:
			Store._state.game.systems[fleet.system].fleets.erase(fleet.id)
		else:
			Store._state.game.systems[fleet.system].fleets[fleet.id].nb_ships = fleet.nb_ships
	get_node("Map/" + data.system.id).refresh_fleet_pins()
	
func _on_system_selected(system, old_system):
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
	get_node("Map/" + fleet.system).refresh_fleet_pins()

func _on_fleet_arrival(fleet):
	update_fleet_system(fleet)

func _on_fleet_sailed(fleet):
	add_fleet_sailing(fleet)

# This method is called when the websocket notifies an another player's fleet sailing
# It notifies the store which call _on_fleet_sailed back
func _on_remote_fleet_sailed(fleet):
	Store.fleet_sail(fleet)

func _on_system_conquerred(data):
	update_fleet_system(data.fleet)
	Store.update_system(data.system)
	get_node("Map/" + data.system.id).refresh()
	
func _on_victory(data):
	Store._state.victorious_faction = data.victorious_faction
	Store._state.scores = data.scores
	emit_signal("scene_requested", "scores")
