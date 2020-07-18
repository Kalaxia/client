extends Control

var hangar_menu = preload("res://hud/system/buildings/hangar.tscn")

var _building_panel_list = []
onready var hangar_node = $ScrollContainer/HBoxContainer/Hangar



func _ready():
	_building_panel_list = []
	var index = 0
	for node in $ScrollContainer/HBoxContainer.get_children():
		if node is SelectablePanelContainer:
			_building_panel_list.push_back(node)
	hangar_node.connect("pressed", self, "_on_hangar_pressed")
	$ScrollContainer/HBoxContainer/Shipyard.connect("pressed", self, "_on_shipyard_pressed")
	Store.connect("system_selected", self, "_on_system_selected")
	Store.connect("system_update", self, "_on_system_update")
	update_visibility()

func _on_system_selected(system, old_system):
	update_visibility()

func system_update(system):
	if system.id == Store._state.selected_system.id:
		update_visibility()

func update_visibility():
	var visible_state = Store._state.selected_system != null and Store._state.selected_system.player == Store._state.player.id
	$ScrollContainer/HBoxContainer/Hangar.visible = visible_state
	if not visible_state:
		_deselect_other_building()

func _deselect_other_building(node = null):
	for node in $MenuSelectedBuilding.get_children() :
		node.queue_free()
	for buiding_panel in _building_panel_list:
		if node != null and buiding_panel.name != node.name:
			buiding_panel.is_selected = false

func _on_hangar_pressed():
	_deselect_other_building(hangar_node)
	if hangar_node.is_selected:
		$MenuSelectedBuilding.add_child(hangar_menu.instance())

func _on_shipyard_pressed():
	_deselect_other_building($ScrollContainer/HBoxContainer/Shipyard)
