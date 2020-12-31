extends MenuContainer

const _SHIP_PRODUCTION_LINE = preload("res://hud/system/buildings/hangar/ship_production_line.tscn")
const _SHIP_TYPE_BUILD = preload("res://hud/system/buildings/hangar/ship_type_build.tscn")
const _SHIP_HANGARD = preload("res://hud/system/buildings/hangar/ship_type_hangar.tscn")
const ASSETS : KalaxiaAssets = preload("res://resources/assets.tres")

var _game_data : GameData = Store.game_data
var ship_group_array = [] setget set_ship_group_array # todo remove ship_group_array
var ship_queue_array = [] setget set_ship_queue_array, get_ship_queue_array # todo remove ship_queue_array
var _lock_ship_prod_update = Utils.Lock.new()

onready var production_list_vbox_elements = $MenuBody/Body/ShipProductionList/VBoxContainer/ScrollContainer/VBoxContainer
onready var ship_order_element = $MenuBody/Body/ShipOrder/VBoxContainer/ShipTypeBuild
onready var hangar_element = $MenuBody/Body/ShipHangar/VBoxContainer/ScrollContainer/HBoxContainer


func _ready():
	_game_data.selected_state.connect("hangar_updated", self, "_on_hangar_updated")
	_game_data.selected_state.connect("system_selected", self, "_on_system_selected")
	_game_data.selected_state.connect("system_updated", self, "_on_system_updated")
	_game_data.selected_state.connect("ship_queue_finished", self, "_on_ship_queue_finished")
	_game_data.selected_state.connect("ship_queue_removed", self, "_on_ship_queue_removed")
	_game_data.selected_state.connect("ship_queue_added", self, "_on_ship_construction_started")
	_init_node_ship_hangar()
	select_group(ASSETS.ship_models.values()[0])
	refresh_hangar()
	if _game_data.selected_state.selected_system != null:
		set_ship_queue_array(_game_data.selected_state.selected_system.ship_queues)


func _enter_tree():
	pass


func _init_node_ship_hangar():
	for category in ASSETS.ship_models.values():
		var node = _SHIP_HANGARD.instance()
		node.category = category
		node.quantity = 0
		node.name = category.category
		hangar_element.add_child(node)
		node.connect("pressed", self, "select_group", [category])


func refresh_hangar():
	var ship_gp_hangar = _game_data.selected_state.selected_system.hangar
	if ship_gp_hangar != null: # todo
		set_ship_group_array(ship_gp_hangar)
	else:
		set_ship_group_array([])
		_game_data.request_hangar(_game_data.selected_state.selected_system)


func _remove_all_queued_elements():
	for node in production_list_vbox_elements.get_children():
		node.queue_free()
	ship_queue_array.clear()
	print("clear all node")


func _on_system_updated():
	if _game_data.does_belong_to_current_player(_game_data.selected_state.selected_system):
		close_request()


func _on_system_selected(old_system):
	var system = _game_data.selected_state.selected_system
	if system.buildings.size() == 0 or system.buildings[0].kind.kind != "shipyard":
		close_request()
	if _game_data.does_belong_to_current_player(system) \
			and (old_system == null or old_system.id != system.id):
		set_ship_queue_array(system.ship_queues)
		refresh_hangar()
	elif old_system == null or old_system.id != system.id:
		_remove_all_queued_elements()
		refresh_hangar()


func _on_hangar_updated(ship_groups):
	if _game_data.does_belong_to_current_player(_game_data.selected_state.selected_system):
		set_ship_group_array(ship_groups)


func set_ship_group_array(new_array):
	ship_group_array = new_array
	for i in hangar_element.get_children():
		i.quantity = 0
	for ship_group in ship_group_array:
		hangar_element.get_node(ship_group.category.category).quantity = ship_group.quantity


func _on_ship_queue_finished(ship_data):
	remove_ship_queue_id(ship_data.id)


func _on_ship_queue_removed(ship_queue):
	remove_ship_queue_id(ship_queue.id)


func _on_ship_construction_started(ship_queue : ShipQueue):
	if ship_queue != null:
		add_ship_queue(ship_queue)


func select_group(category):
	if not hangar_element.has_node(category.category):
		return
	for node in hangar_element.get_children():
		node.is_selected = node.name == category.category
		if node.is_selected:
			ship_order_element.ship_category = category


func set_ship_queue_array(new_array):
	# do not forget to duplicate the array !
	ship_queue_array = new_array.duplicate(false)
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
	if production_list_vbox_elements == null:
		return
	# we lock to only update once until all node are free
	if not _lock_ship_prod_update.try_lock():
		return
	for node in production_list_vbox_elements.get_children():
		node.queue_free()
	# we need to wait for objects to be deleted before inserting new
	# otherwise name get duplicated as queue_free() does not free the node imediatly
	while production_list_vbox_elements.get_child_count() > 0:
		var node = production_list_vbox_elements.get_child(0)
		# it is possible that the node is not inside the tree (when the menu is closed by instance)
		# so the freed node never exit the tree
		if node.is_inside_tree():
			yield(node, "tree_exited")
		else:
			yield(Engine.get_main_loop(), "idle_frame")
	for ship_queue in ship_queue_array:
		var ship_prod_node = _SHIP_PRODUCTION_LINE.instance()
		ship_prod_node.name = ship_queue.id
		ship_prod_node.ship_queue = ship_queue
		production_list_vbox_elements.add_child(ship_prod_node)
	_lock_ship_prod_update.unlock()


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
	# cannot lock if we try refreshing
	# as we are in single thread we unlock before we possibly could request update_ship_queue
	if not _lock_ship_prod_update.try_lock():
		return
	var ship_prod_node = _SHIP_PRODUCTION_LINE.instance()
	ship_prod_node.name = ship_queue.id
	ship_prod_node.ship_queue = ship_queue
	production_list_vbox_elements.add_child(ship_prod_node)
	_lock_ship_prod_update.unlock()
	_sort_queue_ship()
	_sort_queue_ship_node()


func get_ship_queue_array():
	return ship_queue_array.duplicate(true)
