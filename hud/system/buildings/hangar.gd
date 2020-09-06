extends MenuContainer

const _SHIP_PRODUCTION_LINE = preload("res://hud/system/buildings/hangar/ship_production_line.tscn")
const _SHIP_TYPE_BUILD = preload("res://hud/system/buildings/hangar/ship_type_build.tscn")
const _SHIP_HANGARD = preload("res://hud/system/buildings/hangar/ship_type_hangar.tscn")

var game_data : GameData = load(GameData.PATH_NAME)
var ship_group_array = [] setget set_ship_group_array
var ship_queue_array = [] setget set_ship_queue_array, get_ship_queue_array

var _lock_ship_prod_update = Utils.Lock.new()

onready var production_list_vbox_elements = $MenuBody/Body/ShipProductionList/VBoxContainer/ScrollContainer/VBoxContainer
onready var ship_order_element = $MenuBody/Body/ShipOrder/VBoxContainer/ShipTypeBuild
onready var hangar_element = $MenuBody/Body/ShipHangar/VBoxContainer/ScrollContainer/HBoxContainer

onready var assets : KalaxiaAssets = load("res://resources/assets.tres")

func _ready():
	game_data.selected_state.connect("hangar_updated", self, "_on_hangar_updated")
	game_data.selected_state.connect("system_selected", self, "_on_system_selected")
	game_data.selected_state.connect("system_updated", self, "_on_system_updated")
	# todo
	Network.connect("ShipQueueFinished", self, "_on_ship_queue_finished")
	ship_order_element.connect("ship_construction_started", self, "_on_ship_construction_started")
	for category in assets.ship_models.values():
		var node = _SHIP_HANGARD.instance()
		node.category = category
		node.quantity = 0
		node.name = category.category
		hangar_element.add_child(node)
		node.connect("pressed", self, "select_group", [category])
	select_group(assets.ship_models.values()[0])
	refresh_hangar()
	refresh_queue_ships()


func refresh_queue_ships():
	# todo move
	#
	# this may require a bit of time to fetch the data
	# it may be better to store the data inside the system
	_remove_all_queued_elements()
	Network.req(self, "_on_queue_ships_received"
		, "/api/games/" +
			game_data.id+  "/systems/" +
			game_data.selected_state.selected_system.id + "/ship-queues/"
		, HTTPClient.METHOD_GET
	)


func refresh_hangar():
	var ship_gp_hangar = game_data.selected_state.selected_system.hangar
	if ship_gp_hangar != null: # todo
		set_ship_group_array(ship_gp_hangar)
	else:
		set_ship_group_array([])
		game_data.request_hangar(game_data.selected_state.selected_system)


func _remove_all_queued_elements():
	for node in production_list_vbox_elements.get_children():
		node.queue_free()


func _on_system_updated():
	if game_data.does_belong_to_current_player(game_data.selected_state.selected_system):
		close_request()


func _on_system_selected(old_system):
	var system = game_data.selected_state.selected_system
	if system.buildings.size() == 0 or system.buildings[0].kind.kind != "shipyard":
		close_request()
	if game_data.does_belong_to_current_player(system) and (old_system == null or old_system.id != system.id) :
		refresh_queue_ships()
		refresh_hangar()
	elif old_system == null or old_system.id != system.id:
		_remove_all_queued_elements()
		refresh_hangar()


func _on_hangar_updated(ship_groups):
	if game_data.does_belong_to_current_player(game_data.selected_state.selected_system):
		set_ship_group_array(ship_groups)


func set_ship_group_array(new_array):
	ship_group_array = new_array
	for i in hangar_element.get_children():
		i.quantity = 0
	for ship_group in ship_group_array:
		hangar_element.get_node(ship_group.category.category).quantity = ship_group.quantity


func _on_queue_ships_received(err, response_code, _headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_OK:
		var result = JSON.parse(body.get_string_from_utf8()).result
		var array_ship_queue_result = []
		for i in result:
			array_ship_queue_result.push_back(ShipQueue.new(i))
		set_ship_queue_array(array_ship_queue_result)


func _on_ship_queue_finished(ship_data):
	remove_ship_queue_id(ship_data.id)


func _on_ship_construction_started(ship_queue : Dictionary):
	if ship_queue != null:
		add_ship_queue(ShipQueue.new(ship_queue))


func select_group(category):
	if hangar_element.has_node(category.category):
		for node in hangar_element.get_children():
			if node.name != category.category:
				node.is_selected = false
			else:
				node.is_selected = true
				ship_order_element.ship_category = category


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
		if production_list_vbox_elements.has_node(ship_queue_array[i].id):
			production_list_vbox_elements.get_node(ship_queue_array[i].id).raise()


func update_ship_queue():
	# we lock to only update once until all node are free
	if not _lock_ship_prod_update.try_lock():
		return
	for node in production_list_vbox_elements.get_children():
		node.queue_free()
	# we need to wait for objects to be deleted before inserting new
	# otherwise name get duplicated as queue_free() does not free the node imediatly
	while production_list_vbox_elements.get_child_count() > 0:
		yield(production_list_vbox_elements.get_child(0), "tree_exited")
	_lock_ship_prod_update.unlock()
	for ship_queue in ship_queue_array:
		var ship_prod_node = _SHIP_PRODUCTION_LINE.instance()
		ship_prod_node.name = ship_queue.id
		ship_prod_node.ship_queue = ship_queue
		production_list_vbox_elements.add_child(ship_prod_node)


func remove_ship_queue_pos(pos):
	if pos < 0 or pos >= ship_queue_array.size():
		return
	var element = ship_queue_array[pos]
	ship_queue_array.remove(pos)
	var does_node_exist = production_list_vbox_elements.has_node(element.id)
	if does_node_exist:
		production_list_vbox_elements.get_node(element.id).queue_free()
	return does_node_exist


func remove_ship_queue_id(ship_queue_id):
	for i in range(ship_queue_array.size()):
		if ship_queue_array[i].id == ship_queue_id:
			return remove_ship_queue_pos(i)


func add_ship_queue(ship_queue : ShipQueue):
	ship_queue_array.push_back(ship_queue)
	var ship_prod_node = _SHIP_PRODUCTION_LINE.instance()
	ship_prod_node.name = ship_queue.id
	ship_prod_node.ship_queue = ship_queue
	production_list_vbox_elements.add_child(ship_prod_node)
	_sort_queue_ship()
	_sort_queue_ship_node()


func get_ship_queue_array():
	return ship_queue_array.duplicate(true)
