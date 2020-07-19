extends Control

var ship_group_array = [] setget set_ship_group_array
var ship_queue_array = [] setget set_ship_queue_array, get_ship_queue_array

var _lock_ship_prod_update = Utils.Lock.new()

const _SHIP_PRODUCTION_LINE = preload("res://hud/system/buildings/hangar/ship_production_line.tscn")
const _SHIP_TYPE_BUILD = preload("res://hud/system/buildings/hangar/ship_type_build.tscn")
const _SHIP_HANGARD = preload("res://hud/system/buildings/hangar/ship_type_hangar.tscn")

onready var production_list_vbox_elements = $ShipProductionList/VBoxContainer/ScrollContainer/VBoxContainer
onready var ship_order_element = $ShipOrder/VBoxContainer/ShipTypeBuild
onready var hangar_element = $ShipHangar/VBoxContainer/ScrollContainer/HBoxContainer

func _ready():
	Network.connect("ShipQueueFinished",self,"_on_ship_queue_finished")
	for model in Utils.SHIP_MODEL:
		var node = _SHIP_HANGARD.instance()
		node.model = model
		node.quantity = 0
		node.name = model
		hangar_element.add_child(node)
		node.connect("pressed", self, "select_group",[model])
	select_group(Utils.SHIP_MODEL[0])
	ship_order_element.connect("ship_construction_started", self, "_on_ship_construction_started")
	Network.req(self, "_on_ship_group_recieved"
		, "/api/games/" +
			Store._state.game.id+  "/systems/" +
			Store._state.selected_system.id + "/ship-groups/"
		, HTTPClient.METHOD_GET
	)
	Network.req(self, "_on_queue_ships_received"
		, "/api/games/" +
			Store._state.game.id+  "/systems/" +
			Store._state.selected_system.id + "/ship-queues/"
		, HTTPClient.METHOD_GET
	)

func _on_ship_group_recieved(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_OK:
		var result = JSON.parse(body.get_string_from_utf8()).result
		set_ship_group_array(result)

func set_ship_group_array(new_array):
	ship_group_array = new_array
	for ship_group in ship_group_array:
		hangar_element.get_node(ship_group.model).quantity = ship_group.quantity

func _on_queue_ships_received(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_OK:
		var result = JSON.parse(body.get_string_from_utf8()).result
		set_ship_queue_array(result)

func _on_ship_queue_finished(ship_data):
	if ship_data.system != Store._state.selected_system.id:
		return
	remove_ship_queue_id(ship_data.id)
	for ship_group in ship_group_array:
		if ship_group.model == ship_data.model:
			ship_group.quantity += ship_data.quantity
			hangar_element.get_node(ship_data.model).quantity = ship_group.quantity
			return

func _on_ship_construction_started(ship_queue):
	add_ship_queue(ship_queue)

func select_group(model):
	if hangar_element.has_node(model):
		for node in hangar_element.get_children():
			if node.name != model:
				node.is_selected = false
			else:
				node.is_selected = true
				ship_order_element.ship_model = model

func set_ship_queue_array(new_array):
	ship_queue_array = new_array
	_sort_queue_ship()
	update_ship_queue()

func _sort_queue_ship():
	if ship_queue_array.size() <= 1:
		return
	for i in range(ship_queue_array.size()-1):
		var min_element = ship_queue_array[i].finished_at
		var pos_element = i
		for j in range(i+1, ship_queue_array.size()):
			if ship_queue_array[j].finished_at < min_element:
				min_element = ship_queue_array[j].finished_at
				pos_element = j
		var element_move = ship_queue_array[pos_element]
		ship_queue_array.remove(pos_element)
		ship_queue_array.insert(i, element_move)

func _sort_queue_ship_node():
	for i in range(ship_queue_array.size()):
		if production_list_vbox_elements.has_node(ship_queue_array[i].hash() as String):
			production_list_vbox_elements.get_node(ship_queue_array[i].hash() as String).raise()

func update_ship_queue():
	# we lock to only update once until all node are free
	if not _lock_ship_prod_update.try_lock():
		return
	for node in production_list_vbox_elements.get_children():
		node.queue_free()
	# we need to wait for objects to be deleted before inserting new
	# otherwise name get duplicated as queue_free() does not free the node imediatly
	while production_list_vbox_elements.get_child_count() > 0 :
		yield(production_list_vbox_elements.get_child(0),"tree_exited")
	_lock_ship_prod_update.unlock()
	for ship_queue in ship_queue_array:
		var ship_prod_node = _SHIP_PRODUCTION_LINE.instance()
		ship_prod_node.name = ship_queue.hash() as String
		ship_prod_node.ship_queue = ship_queue
		production_list_vbox_elements.add_child(ship_prod_node)

func remove_ship_queue_pos(pos):
	if pos < 0 or pos >= ship_queue_array.size():
		return
	var element = ship_queue_array[pos]
	ship_queue_array.remove(pos)
	var does_node_exist = production_list_vbox_elements.has_node(element.hash() as String)
	if does_node_exist:
		production_list_vbox_elements.get_node(element.hash() as String).queue_free()
	return does_node_exist

func remove_ship_queue_id(ship_queue_id):
	for i in range(ship_queue_array.size()):
		if ship_queue_array[i].id == ship_queue_id:
			return remove_ship_queue_pos(i)

func add_ship_queue(ship_queue):
	ship_queue_array.push_back(ship_queue)
	var ship_prod_node = _SHIP_PRODUCTION_LINE.instance()
	ship_prod_node.name = ship_queue.hash() as String
	ship_prod_node.ship_queue = ship_queue
	production_list_vbox_elements.add_child(ship_prod_node)
	_sort_queue_ship()
	_sort_queue_ship_node()

func get_ship_queue_array():
	return ship_queue_array.duplicate(true)
