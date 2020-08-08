extends Control

const _SHIP_GROUP_ELEMENT = preload("res://hud/system/fleet/ship_group_fleet_menu.tscn")

var fleet = null setget set_fleet
var ship_group_hangar = [] setget set_ship_group_hangar
var system_id = null 

onready var ship_group_element_container = $PanelContainer/ScrollContainer/ShipList
onready var menu_header = $MenuHeader


func _ready():
	Store.connect("fleet_update_nb_ships",self,"_on_fleet_update_nb_ships")
	Store.connect("hangar_updated", self, "_on_hangar_updated")
	Network.connect("ShipQueueFinished",self,"_on_ship_queue_finished")
	for category in Store._state.ship_models:
		var node = _SHIP_GROUP_ELEMENT.instance()
		node.ship_category = category
		node.name = category.category
		ship_group_element_container.add_child(node)
		node.connect("ship_assigned", self, "_on_ship_assigned", [category])
	menu_header.connect("minimize_request", self, "_on_minimize_request")
	update_hangar()
	update_element_fleet()


func _on_hangar_updated(system):
	if system.id == Store._state.selected_system.id:
		set_ship_group_hangar(system.hangar)


func _on_ship_assigned(quantity_fleet, quantity_hangar, category):
	var total_number_of_ships_in_hangar = 0
	for i in ship_group_hangar:
		if i.category == category.category:
			i.quantity = quantity_hangar
		total_number_of_ships_in_hangar += i.quantity
	Store.update_hangar_system_id(fleet.system, ship_group_hangar)


func _on_minimize_request():
	visible = false


func update_hangar():
	if fleet == null or system_id == fleet.system:
		return
	system_id = fleet.system
	if Store._state.selected_system.has("hangar") and Store._state.selected_system.hangar != null:
		set_ship_group_hangar(Store._state.selected_system.hangar)
	else:
		Network.req(self, "_on_ship_group_received"
			, "/api/games/" +
				Store._state.game.id+  "/systems/" +
				fleet.system + "/ship-groups/"
			, HTTPClient.METHOD_GET
			, [fleet.system]
		)


func update_element_fleet():
	var node_updated = []
	if fleet != null and fleet.ship_groups != null and ship_group_element_container != null:
		for i in fleet.ship_groups:
			var node_ship_group = ship_group_element_container.get_node(i.category)
			node_ship_group.quantity_fleet = i.quantity
			node_updated.push_back(node_ship_group.name)
	for node in ship_group_element_container.get_children():
		if not node_updated.has(node.name):
			node.quantity_fleet = 0


func _on_ship_group_received(err, response_code, headers, body, system_id):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_OK :
		var result = JSON.parse(body.get_string_from_utf8()).result
		set_ship_group_hangar(result)
		Store.update_hangarsystem_id(system_id, result)


func set_fleet(new_fleet):
	fleet = new_fleet
	if fleet.system != system_id:
		update_hangar()
	update_element_fleet()


func set_ship_group_hangar(array):
	ship_group_hangar = array
	for i in ship_group_hangar:
		ship_group_element_container.get_node(i.category).quantity_hangar = i.quantity


func _on_fleet_update_nb_ships(fleet_param):
	if fleet != null and fleet_param.id == fleet.id:
		set_fleet(fleet_param)
