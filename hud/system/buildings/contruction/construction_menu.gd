extends Control

signal closed()
signal building_contructing(building)

const CONSTRUCTION_ITEM = preload("res://hud/system/buildings/contruction/construction_building_item.tscn")

onready var menu_header = $MenuHeader
onready var conainer_contruction = $PanelContainer/VBoxContainer


func _ready():
	menu_header.connect("close_request", self, "_on_close_request")
	for building in Store._state.building_list:
		var node = CONSTRUCTION_ITEM.instance()
		node.building_type = building
		node.connect("building_contructing", self, "_on_building_contructing")
		conainer_contruction.add_child(node)


func close():
	emit_signal("closed")
	queue_free()


func _on_close_request():
	close()


func _on_building_contructing(building):
	emit_signal("building_contructing", building)
	close()
