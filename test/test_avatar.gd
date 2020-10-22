extends Node2D

const ID = "super secrete id"
var ASSETS = load("res://resources/assets.tres")
const SYSTEM_SECENE = preload("res://game/map/system.tscn")
const CACHE = preload("res://cache.tres")

func _ready():
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
	my_system.coordinates = Vector2(5,5)
	var system = SYSTEM_SECENE.instance()
	system.system = my_system
	add_child(system)
	var my_system_2 = System.new()
	my_system_2.id = "id2"
	my_system_2.kind = "VictorySystem"
	my_system_2.player = "kern"
	my_system_2.coordinates = Vector2(10,5)
	var system_2 = SYSTEM_SECENE.instance()
	system_2.system = my_system_2
	add_child(system_2)
