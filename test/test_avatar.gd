extends Node2D

const ID = "super secrete id"
var ASSETS = load("res://resources/assets.tres")
const SYSTEM_SECENE = preload("res://game/map/system.tscn")
const CACHE = preload("res://cache.tres")
const FLEET_SAILING = preload("res://game/map/fleet_sailing.tscn")

var fleet_saling
var fleet_saling_2

onready var timer = $Timer

func _ready():
	timer.connect("timeout", self, "_on_timeout")
	ASSETS.constants = CACHE.constants
	var me = Player.new()
	me.username = "Chicken"
	me.id = ID
	me.faction = ASSETS.factions[1]
	var kern = Player.new()
	kern.username = "Kern"
	kern.id = "kern"
	kern.faction = ASSETS.factions[2]
	Store.game_data = GameData.new("uuid", me, null)
	Store.game_data.players["kern"] = kern
	var my_system = System.new()
	my_system.id = "id1"
	my_system.kind = "BaseSystem"
	my_system.player = ID
	my_system.coordinates = Vector2(5, 5)
	var system = SYSTEM_SECENE.instance()
	system.system = my_system
	add_child(system)
	var my_system_2 = System.new()
	my_system_2.id = "id2"
	my_system_2.kind = "VictorySystem"
	my_system_2.player = "kern"
	my_system_2.coordinates = Vector2(10, 5)
	var system_2 = SYSTEM_SECENE.instance()
	system_2.system = my_system_2
	add_child(system_2)
	var fleet = Fleet.new()
	fleet.player = ID
	fleet.destination_arrival_date = OS.get_system_time_msecs() + 6 * 1000
	fleet_saling = FLEET_SAILING.instance()
	fleet_saling.fleet = fleet
	fleet_saling.origin_position = Vector2(5,5) * Utils.SCALE_SYSTEMS_COORDS
	fleet_saling.destination_position = Vector2(10, 5) * Utils.SCALE_SYSTEMS_COORDS
	add_child(fleet_saling)
	var fleet_2 = Fleet.new()
	fleet_2.player = "kern"
	fleet_2.destination_arrival_date = OS.get_system_time_msecs() + 6 * 1000
	fleet_saling_2 = FLEET_SAILING.instance()
	fleet_saling_2.fleet = fleet_2
	randomize()
	fleet_saling_2.origin_position = Vector2(rand_range(0, 20), rand_range(0, 15)) * Utils.SCALE_SYSTEMS_COORDS
	fleet_saling_2.destination_position = Vector2(rand_range(0, 20), rand_range(0, 15)) * Utils.SCALE_SYSTEMS_COORDS
	add_child(fleet_saling_2)


func _on_timeout():
	fleet_saling._time_departure = OS.get_system_time_msecs()
	fleet_saling.fleet.destination_arrival_date = OS.get_system_time_msecs() + 6 * 1000
	fleet_saling_2._time_departure = OS.get_system_time_msecs()
	fleet_saling_2.fleet.destination_arrival_date = OS.get_system_time_msecs() + 6 * 1000
	fleet_saling_2.origin_position = fleet_saling_2.destination_position
	fleet_saling_2.destination_position = Vector2(rand_range(0, 20), rand_range(0, 15)) * Utils.SCALE_SYSTEMS_COORDS
	fleet_saling_2._ready()
