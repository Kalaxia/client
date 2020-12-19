extends Control

const FLEET_COST = 0
const FLEET_ITEM_SCENE = preload("res://hud/system/fleet/fleet_item.tscn")

var menu_layer : MenuLayer setget set_menu_layer
var _create_fleet_lock = Utils.Lock.new()
var _lock_add_fleet_item = Utils.Lock.new()
var _game_data : GameData = Store.game_data

onready var fleet_creation_button = $ScrollContainer/HBoxContainer/FleetCreationButton
onready var fleet_container = $ScrollContainer/HBoxContainer/Fleets


func _ready():
	_game_data.selected_state.connect("system_selected", self, "_on_system_selected")
	_game_data.player.connect("wallet_updated", self, "_on_wallet_update")
	_game_data.selected_state.connect("fleet_added", self, "_on_fleet_created")
	_game_data.selected_state.connect("fleet_erased", self, "_on_fleet_erased")
	_game_data.selected_state.connect("fleet_selected", self, "_on_fleet_selected")
	_game_data.selected_state.connect("system_updated", self, "_on_system_updated")
	_game_data.selected_state.connect("system_fleet_arrived", self, "_on_system_fleet_arrived")
	_game_data.connect("fleet_sailed", self, "_on_fleet_sailed")
	Network.connect("Victory", self, "_on_victory")
	fleet_creation_button.connect("pressed", self, "create_fleet")
	refresh_data()


func _unhandled_input(event):
	if not event is InputEventKey or not is_visible():
		return
	if event.is_action_pressed("ui_add_fleet"):
		create_fleet()
	elif event.is_action_pressed("ui_select_fleet"):
		# get diff between first key and actual key to get the fleet list index
		var index = event.scancode - KEY_1
		if _game_data.selected_state.selected_sytem.fleets.size() > index:
			_game_data.selected_state.select_fleet(_game_data.selected_state.selected_sytem.fleets.values()[index])


func set_menu_layer(node):
	menu_layer = node


func refresh_data():
	# because of the yield it is possible to add the nodes multiple times 
	# the lock prevents that
	if not _lock_add_fleet_item.try_lock():
		return # we do not have to retry as the data are taken after the yield
	for f in fleet_container.get_children(): 
		f.queue_free()
	# we need to wait one frame for objects to be deleted before inserting new
	# otherwise name get duplicated as queue_free() does not free the node immediately
	while fleet_container.get_child_count() > 0 :
		var node = fleet_container.get_child(0)
		# it is possible that the node is not inside the tree
		# so the freed node never exit the tree
		if node.is_inside_tree():
			yield(node, "tree_exited")
		else:
			yield(Engine.get_main_loop(), "idle_frame")
	# refresh the data in the case where the data changed after the yield
	var system_refreshed = _game_data.selected_state.selected_system
	if system_refreshed == null:
		_lock_add_fleet_item.unlock()
		return
	if system_refreshed.player != null and _game_data.does_belong_to_current_player(system_refreshed):
		fleet_creation_button.set_visible(true)
		fleet_creation_button.disabled = _game_data.player.wallet < FLEET_COST
	else:
		fleet_creation_button.set_visible(false)
	for id in range(system_refreshed.fleets.values().size()): 
		var fleet_node = add_fleet_item(system_refreshed.fleets.values()[id])
		fleet_node.set_key_binding_number(id)
	_lock_add_fleet_item.unlock()


func create_fleet():
	if _create_fleet_lock.try_lock() != Utils.Lock.LOCK_STATE.OK:
		return
	if _game_data.player.wallet < FLEET_COST :
		_create_fleet_lock.unlock()
		return
	Network.req(self, "_on_request_completed"
		, "/api/games/" +
			_game_data.id + "/systems/" +
			_game_data.selected_state.selected_system.id + "/fleets/"
		, HTTPClient.METHOD_POST
		, [ "Content-Type: application/json" ]
	)


func add_fleet_item(fleet):
	var fleet_node = FLEET_ITEM_SCENE.instance()
	fleet_node.set_name(fleet.id)
	fleet_node.fleet = fleet
	fleet_container.add_child(fleet_node)
	fleet_node.connect("pressed_open_ship_menu", self, "_on_button_menu_fleet")
	if (_game_data.selected_state.selected_fleet == null \
			or _game_data.selected_state.selected_fleet.system != _game_data.selected_state.selected_system.id) \
			and _game_data.does_belong_to_current_player(fleet):
		_game_data.selected_state.select_fleet(fleet)
	return fleet_node


func _on_system_fleet_arrived(fleet : Fleet):
	if not _lock_add_fleet_item.try_lock():
		return 
		# we can safely retrun as if it is lock it means that we are waiting on refresh this node anyway (because we are in single-thread)
	add_fleet_item(fleet)
	_lock_add_fleet_item.unlock()


func _on_system_selected(_old_system):
	refresh_data()


func _on_fleet_selected(_old_fleet):
	# todo
	menu_layer.get_menu("menu_fleet").fleet = _game_data.selected_state.selected_fleet


func _on_button_menu_fleet(fleet):
	if menu_layer.toogle_menu("menu_fleet"):
		menu_layer.get_menu("menu_fleet").fleet = fleet


func _on_fleet_created(fleet):
	if not _lock_add_fleet_item.try_lock():
		return
		# we can safely retrun as if it is lock it means that we are waiting on refresh this node anyway (because we are in single-thread)
	var fleet_node = add_fleet_item(fleet)
	_lock_add_fleet_item.unlock()
	fleet_node.set_key_binding_number(_game_data.selected_state.selected_system.fleets.size()-1)


func _on_wallet_update(_amount):
	if not _game_data.does_belong_to_current_player(_game_data.selected_state.selected_system):
		return
	fleet_creation_button.disabled = _game_data.player.wallet < FLEET_COST


func _on_request_completed(err, response_code, _headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_CREATED:
		_game_data.player.update_wallet(-FLEET_COST)
		var result = JSON.parse(body.get_string_from_utf8()).result
		_game_data.get_system(result.system).add_fleet_dict(result)
	_create_fleet_lock.unlock()


func _on_fleet_erased(_fleet):
	refresh_data()


func _on_system_updated():
	refresh_data()


func _on_fleet_sailed(fleet):
	if fleet.system == _game_data.selected_state.selected_system.id:
		refresh_data()
	if fleet == menu_layer.get_menu("menu_fleet").fleet:
		menu_layer.close_menu("menu_fleet")


func _on_victory(_data):
	set_visible(false)
