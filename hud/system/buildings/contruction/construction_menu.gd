extends MenuContainer

signal building_constructing(building)

const ASSETS = preload("res://resources/assets.tres")
const CONSTRUCTION_ITEM = preload("res://hud/system/buildings/contruction/construction_building_item.tscn")

onready var conainer_contruction = $MenuBody/Body


func _ready():
	for building in ASSETS.buildings.keys():
		if building != "":
			var node = CONSTRUCTION_ITEM.instance()
			node.building_type = ASSETS.buildings[building]
			node.connect("building_constructing", self, "_on_building_constructing")
			conainer_contruction.add_child(node)


func _on_building_constructing(building):
	emit_signal("building_constructing", building)
	close_request()
