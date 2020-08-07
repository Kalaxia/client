extends Control

const BUILDING_AREA = preload("res://hud/system/buildings/building_panel.tscn")

const MENU = {
	"" : preload("res://hud/system/buildings/contruction/construction_menu.tscn"),
	"hangar" :  preload("res://hud/system/buildings/hangar.tscn"),
	"mine" : null,
}

var _building_panel_list = []

onready var menu_selected_building = $MenuSelectedBuilding
onready var building_container = $ScrollContainer/HBoxContainer


func _ready():
	_building_panel_list = []
	Store.connect("system_selected", self, "_on_system_selected")
	Store.connect("system_update", self, "_on_system_update")
	Store.connect("building_updated", self, "_on_building_updated")
	update_building_panels()
	update_visibility()


func _on_system_selected(system, old_system):
	update_building_panels()
	update_visibility()


func update_building_panels():
	while not _building_panel_list.empty():
		_building_panel_list.pop_back().queue_free()
	if Store._state.selected_system.player == Store._state.player.id:
		var building_aera = BUILDING_AREA.instance()
		building_aera.building = Store._state.selected_system.buildings[0] if  Store._state.selected_system.has("buildings") and Store._state.selected_system.buildings != null and Store._state.selected_system.buildings.size() >= 1 else null
		building_container.add_child(building_aera)
		building_aera.connect("pressed", self, "_on_panel_pressed" , [building_aera])
		_building_panel_list.push_back(building_aera)


func system_update(system):
	if system.id == Store._state.selected_system.id:
		update_visibility()
		update_building_panels()


func _on_building_updated(system):
	system_update(system)


func update_visibility():
	var visible_state = Store._state.selected_system != null and Store._state.selected_system.player == Store._state.player.id
	building_container.visible = visible_state
	if not visible_state:
		_deselect_other_building()


func _on_panel_pressed(node):
	_deselect_other_building(node)
	if node.is_selected:
		var menu = MENU[node.building.king if node.building != null else ""]
		if menu != null:
			var node_menu = menu.instance()
			if node.building == null:
				node_menu.connect("building_contructing", self, "_on_building_contructing", [node])
			node_menu.connect("closed", self, "_on_menu_closed")
			menu_selected_building.add_child(node_menu)


func _deselect_other_building(node = null):
	# if node is null deselect all buildings
	for node in menu_selected_building.get_children() :
		node.queue_free()
	for buiding_panel in _building_panel_list:
		if node == null or buiding_panel.name != node.name:
			buiding_panel.is_selected = false


func _on_menu_closed():
	_deselect_other_building()


func _on_building_contructing(node, building):
	node.building = building
