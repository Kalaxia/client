extends Control

const FLEET_COST = 10

var fleet_item_scene = preload("res://hud/system/fleet/fleet_item.tscn")
var _create_fleet_lock = Utils.Lock.new()
var _lock_add_fleet_item = Utils.Lock.new()

onready var fleet_creation_button = $ScrollContainer/HBoxContainer/FleetCreationButton
onready var menu_fleet = $HBoxContainer/HBoxContainer/MenuFleet
onready var fleet_container = $ScrollContainer/HBoxContainer/Fleets


func _ready():
	Store.connect("system_selected", self, "_on_system_selected")
	Store.connect("wallet_updated", self, "_on_wallet_update")
	Store.connect("fleet_created", self, "_on_fleet_created")
	Store.connect("fleet_update", self, "_on_fleet_update")
	Store.connect("fleet_erased", self, "_on_fleet_erased")
	Store.connect("fleet_selected", self, "_on_fleet_selected")
	Store.connect("system_update", self, "_on_system_update")
	Store.connect("fleet_sailed", self, "_on_fleet_sailed")
	Network.connect("Victory", self, "_on_victory")
	fleet_creation_button.connect("pressed", self, "create_fleet")
	fleet_creation_button.set_visible(false)
	refresh_data(Store._state.selected_system)
	menu_fleet.visible = false


func _on_system_selected(system, old_system):
	refresh_data(system)


func _on_fleet_selected(fleet):
	menu_fleet.visible = false


func _on_button_menu_fleet(fleet):
	var visible_new = not menu_fleet.visible or fleet.id != menu_fleet.fleet.id
	menu_fleet.visible = visible_new
	if visible_new:
		menu_fleet.fleet = fleet


func refresh_data(system):
	# because of the yield it is possible to add the nodes multiple times 
	# the lock prevents that
	if not _lock_add_fleet_item.try_lock():
		return # we do not have to retry as the data are taken after the yield
	for f in fleet_container.get_children(): f.queue_free()
	# we need to wait one frame for objects to be deleted before inserting new
	# otherwise name get duplicated as queue_free() does not free the node immediately
	while fleet_container.get_child_count() > 0 :
		yield(fleet_container.get_child(0), "tree_exited")
	fleet_creation_button.set_visible(true)
	if system == null || system.id == null:
		_lock_add_fleet_item.unlock()
		return
	var system_refreshed = Store._state.selected_system # refresh the data in the case where the data changed after the yield
	if system_refreshed == null:
		return
	if system_refreshed.player != null:
		var player = Store.get_game_player(system_refreshed.player)
		if system_refreshed.player == Store._state.player.id:
			fleet_creation_button.set_visible(true)
			fleet_creation_button.disabled = Store._state.player.wallet < FLEET_COST
	for id in range(system_refreshed.fleets.values().size()): 
		var fleet_node = add_fleet_item(system_refreshed.fleets.values()[id])
		fleet_node.set_key_binding_number(id)
	_lock_add_fleet_item.unlock()


func create_fleet():
	if _create_fleet_lock.try_lock() != Utils.Lock.LOCK_STATE.OK:
		return
	if Store._state.player.wallet < FLEET_COST :
		_create_fleet_lock.unlock()
		return
	Network.req(self, "_on_request_completed"
		, "/api/games/" +
			Store._state.game.id + "/systems/" +
			Store._state.selected_system.id + "/fleets/"
		, HTTPClient.METHOD_POST
		, [ "Content-Type: application/json" ]
	)


func add_fleet_item(fleet):
	var fleet_node = fleet_item_scene.instance()
	fleet_node.set_name(fleet.id)
	fleet_node.fleet = fleet
	fleet_container.add_child(fleet_node)
	fleet_node.connect("pressed_open_ship_menu", self, "_on_button_menu_fleet")
	if ( Store._state.selected_fleet == null or Store._state.selected_fleet.system != Store._state.selected_system.id ) and fleet.player == Store._state.player.id:
		Store.select_fleet(fleet)
	return fleet_node


func _on_fleet_created(fleet):
	if Store._state.selected_system == null || fleet.system != Store._state.selected_system.id:
		return
	var fleet_node = add_fleet_item(fleet)
	fleet_node.set_key_binding_number(Store._state.selected_system.fleets.size()-1)


func _on_wallet_update(amount):
	if Store._state.selected_system == null || Store._state.selected_system.player != Store._state.player.id:
		return
	fleet_creation_button.disabled = Store._state.player.wallet < FLEET_COST


func _on_request_completed(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == 201:
		Store.update_wallet(-FLEET_COST)
		Store.add_fleet(JSON.parse(body.get_string_from_utf8()).result)
	_create_fleet_lock.unlock()


func _on_fleet_erased(fleet):
	if fleet.system == Store._state.selected_system.id:
		refresh_data(Store._state.selected_system)


func _on_fleet_update(fleet):
	if fleet.system == Store._state.selected_system.id:
		refresh_data(Store._state.selected_system)


func _on_system_update(system):
	if system.id == Store._state.selected_system.id:
		refresh_data(Store._state.selected_system)


func _on_fleet_sailed(fleet, arrival_time):
	if fleet.system == Store._state.selected_system.id:
		refresh_data(Store._state.selected_system)


func _on_victory(data):
	set_visible(false)


func _unhandled_input(event):
	if not event is InputEventKey or not is_visible():
		return
	if event.is_action_pressed("ui_add_fleet"):
		create_fleet()
	elif event.is_action_pressed("ui_select_fleet"):
		# get diff between first key and actual key to get the fleet list index
		var index = event.scancode - KEY_1
		if Store._state.selected_system.fleets.size() > index:
			Store.select_fleet(Store._state.selected_system.fleets.values()[index])
