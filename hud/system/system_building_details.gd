extends Control

const BUILDING_AREA = preload("res://hud/system/buildings/building_panel.tscn")

const MENU = {
	"" : "menu_construction",
	"shipyard" :  "menu_shipyard",
	"mine" : null,
	"portal" : null,
}

var menu_layer : MenuLayer setget set_menu_layer
var _building_panel_list = []

onready var building_container = $ScrollContainer/HBoxContainer


func _ready():
	_building_panel_list = []
	Store.connect("system_selected", self, "_on_system_selected")
	Store.connect("system_update", self, "_on_system_update")
	Store.connect("building_updated", self, "_on_building_updated")
	update_building_panels()
	update_visibility()


func set_menu_layer(node):
	if menu_layer != null and menu_layer.is_connected("menu_closed", self, "_on_menu_layer_menu_closed"):
		menu_layer.disconnect("menu_closed", self, "_on_menu_layer_menu_closed")
	menu_layer = node
	menu_layer.connect("menu_closed", self, "_on_menu_layer_menu_closed")


func update_building_panels():
	while not _building_panel_list.empty():
		_building_panel_list.pop_back().queue_free()
	if Store._state.selected_system.player == Store._state.player.id:
		var building_area = BUILDING_AREA.instance()
		building_area.building = Store._state.selected_system.buildings[0] if  Store._state.selected_system.has("buildings") and Store._state.selected_system.buildings != null and Store._state.selected_system.buildings.size() >= 1 else null
		building_container.add_child(building_area)
		building_area.connect("pressed", self, "_on_panel_pressed" , [building_area])
		_building_panel_list.push_back(building_area)


func system_update(system):
	if system.id == Store._state.selected_system.id:
		update_visibility()
		update_building_panels()


func update_visibility():
	var visible_state = Store._state.selected_system != null and Store._state.selected_system.player == Store._state.player.id
	building_container.visible = visible_state
	if not visible_state:
		_deselect_other_building()


func _on_building_updated(system):
	system_update(system)


func _on_system_selected(system, old_system):
	update_building_panels()
	update_visibility()


func _on_system_update(system):
	system_update(system)


func _on_panel_pressed(node):
	_deselect_other_building(node)
	if node.is_selected and (node.building == null or node.building.status == "operational"):
		var menu = MENU[node.building.kind if node.building != null else ""]
		if menu != null:
			menu_layer.request_menu(menu)
			var node_menu = menu_layer.get_menu(menu)
			if node.building == null:
				node_menu.connect("building_contructing", self, "_on_building_contructing", [node])


func _deselect_other_building(node = null):
	# if node is null deselect all buildings
	for menu in MENU:
		menu_layer.close_menu(menu)
	for buiding_panel in _building_panel_list:
		if node == null or buiding_panel.name != node.name:
			buiding_panel.is_selected = false


func _on_menu_layer_menu_closed(menu_name):
	if menu_name == "menu_shipyard":
		_deselect_other_building()


func _on_building_contructing(node, building):
	node.building = building
