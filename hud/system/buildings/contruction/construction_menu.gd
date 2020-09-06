tool
extends MenuContainer

signal building_contructing(building)

const ASSETS = preload("res://resources/assets.tres")
const CONSTRUCTION_ITEM = preload("res://hud/system/buildings/contruction/construction_building_item.tscn")

onready var conainer_contruction = $MenuBody/Body


func _ready():
	for building in ASSETS.buildings.keys(): # todo change that to ressource
		if building != "":
			var node = CONSTRUCTION_ITEM.instance()
			node.building_type = ASSETS.buildings[building]
			node.connect("building_contructing", self, "_on_building_contructing")
			conainer_contruction.add_child(node)


func _on_building_contructing(building):
	emit_signal("building_contructing", building)
	close_request()
