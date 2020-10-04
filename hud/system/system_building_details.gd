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
var _game_data : GameData = Store.game_data

onready var building_container = $ScrollContainer/HBoxContainer


func _ready():
	_building_panel_list = []
	_game_data.selected_state.connect("system_selected", self, "_on_system_selected")
	_game_data.selected_state.connect("system_updated", self, "_on_system_updated")
	_game_data.selected_state.connect("building_updated", self, "_on_building_updated")
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
	if _game_data.does_belong_to_current_player(_game_data.selected_state.selected_system):
		var building_area = BUILDING_AREA.instance()
		building_area.building = _game_data.selected_state.selected_system.buildings[0] if _game_data.selected_state.selected_system.buildings.size() >= 1 else null
		building_container.add_child(building_area)
		building_area.connect("pressed", self, "_on_panel_pressed" , [building_area])
		_building_panel_list.push_back(building_area)


func system_updated():
	update_visibility()
	update_building_panels()


func update_visibility():
	var visible_state = _game_data.selected_state.selected_system != null \
			and _game_data.does_belong_to_current_player(_game_data.selected_state.selected_system)
	building_container.visible = visible_state
	if not visible_state:
		_deselect_other_building()


func _on_building_updated():
	system_updated()


func _on_system_selected(_old_system):
	update_building_panels()
	update_visibility()


func _on_system_updated():
	system_updated()


func _on_panel_pressed(node):
	_deselect_other_building(node)
	if node.is_selected and (node.building == null or node.building.status == "operational"):
		var menu = MENU[node.building.kind.kind if node.building != null else ""]
		if menu != null:
			menu_layer.request_menu(menu)
			var node_menu = menu_layer.get_menu(menu)
			if node.building == null:
				if node_menu.is_connected("building_contructing", self, "_on_building_contructing"):
					node_menu.disconnect("building_contructing", self, "_on_building_contructing")
				node_menu.connect("building_contructing", self, "_on_building_contructing", [node])
				# todo connect systems instead ?


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
	elif menu_name == "menu_construction":
		var node_menu = menu_layer.get_menu("menu_construction")
		if node_menu.is_connected("building_contructing", self, "_on_building_contructing"):
			node_menu.disconnect("building_contructing", self, "_on_building_contructing")
		_deselect_other_building()


func _on_building_contructing(building, node):
	# the data are not chnage in game_data as the menu does it
	if node != null and is_instance_valid(node):
		node.building = building
