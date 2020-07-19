extends Control


var fleet = null setget set_fleet
var ship_group_hangar = [] setget set_ship_group_hangar
var system_id = null 

const _SHIP_GROUP_ELEMENT = preload("res://hud/system/fleet/ship_group_fleet_menu.tscn")

onready var ship_group_element_container = $PanelContainer/ScrollContainer/ShipList
onready var menu_header = $MenuHeader

func _ready():
	Store.connect("fleet_update_nb_ships",self,"_on_fleet_update_nb_ships")
	Network.connect("ShipQueueFinished",self,"_on_ship_queue_finished")
	for model in Utils.SHIP_MODEL:
		var node = _SHIP_GROUP_ELEMENT.instance()
		node.ship_model = model
		node.name = model
		ship_group_element_container.add_child(node)
	menu_header.connect("minimize_request", self, "_on_minimize_request")
	update_hangar()
	update_element_fleet()

func _on_minimize_request():
	visible = false

func _on_ship_queue_finished(ship_data):
	if ship_data.system != Store._state.selected_system.id:
		return
	for i in ship_group_hangar:
		if i.model == ship_data.model:
			i.quantity += ship_data.quantity
			ship_group_element_container.get_node(i.model).quantity_hangar = i.quantity
			return

func update_hangar():
	if fleet == null or system_id == fleet.system:
		return
	system_id = fleet.system
	Network.req(self, "_on_ship_group_recieved"
		, "/api/games/" +
			Store._state.game.id+  "/systems/" +
			fleet.system + "/ship-groups/"
		, HTTPClient.METHOD_GET
	)

func update_element_fleet():
	if fleet == null:
		for node in ship_group_element_container.get_children():
			node.quantity_fleet = 0
	else:
		for i in fleet.ship_group:
			ship_group_element_container.get_node(i.model).quantity_fleet = i.quantity

func _on_ship_group_recieved(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_OK :
		var result = JSON.parse(body.get_string_from_utf8()).result
		set_ship_group_hangar(result)

func set_fleet(new_fleet):
	fleet = new_fleet
	if fleet.system != system_id:
		update_hangar() 
	update_element_fleet()

func set_ship_group_hangar(array):
	ship_group_hangar = array
	for i in ship_group_hangar:
		ship_group_element_container.get_node(i.model).quantity_hangar = i.quantity

func _on_fleet_update_nb_ships(fleet_param):
	if fleet_param.id == fleet.id:
		set_fleet(fleet_param)
