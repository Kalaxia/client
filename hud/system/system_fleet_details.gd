extends Control

var fleet_item_scene = preload("res://hud/system/fleet_item.tscn")
var _create_fleet_lock = Utils.Lock.new()
var _lock_add_fleet_item = Utils.Lock.new()

const FLEET_COST = 10

func _ready():
	Store.connect("system_selected", self, "_on_system_selected")
	Store.connect("wallet_updated", self, "_on_wallet_update")
	Store.connect("fleet_created", self, "_on_fleet_created")
	Store.connect("fleet_update", self, "_on_fleet_update")
	Store.connect("fleet_erased", self, "_on_fleet_erased")
	Store.connect("system_update", self, "_on_system_update")
	Store.connect("fleet_sailed", self, "_on_fleet_sailed")
	Network.connect("Victory", self, "_on_victory")
	$ScrollContainer/HBoxContainer/FleetCreationButton.connect("pressed", self, "create_fleet")
	$ScrollContainer/HBoxContainer/FleetCreationButton.set_visible(false)
	refresh_data(Store._state.selected_system)

func _on_system_selected(system, old_system):
	refresh_data(system)

func refresh_data(system):
	# because of the yield it is possible to add the nodes multiple times 
	# the lock prevents that
	if not _lock_add_fleet_item.try_lock():
		return # we do not have to retry as the data are taken after the yield
	for f in $ScrollContainer/HBoxContainer/Fleets.get_children(): f.queue_free()
	# we need to wait one frame for objects to be deleted before inserting new
	# otherwise name get duplicated as queue_free() does not free the node immediately
	while $ScrollContainer/HBoxContainer/Fleets.get_child_count() > 0 :
		yield($ScrollContainer/HBoxContainer/Fleets.get_child(0),"tree_exited")
	var create_fleet_button = $ScrollContainer/HBoxContainer/FleetCreationButton
	create_fleet_button.set_visible(false)
	if system == null || system.id == null:
		_lock_add_fleet_item.unlock()
		return
	var system_refreshed = Store._state.selected_system # refresh the data in the case where the data changed after the yield
	if system_refreshed == null:
		return
	if system_refreshed.player != null:
		var player = Store.get_game_player(system_refreshed.player)
		if system_refreshed.player == Store._state.player.id:
			create_fleet_button.set_visible(true)
			create_fleet_button.disabled = Store._state.player.wallet < FLEET_COST
	for id in system_refreshed.fleets: add_fleet_item(system_refreshed.fleets[id])
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
	$ScrollContainer/HBoxContainer/Fleets.add_child(fleet_node)
	if ( Store._state.selected_fleet == null or Store._state.selected_fleet.system != Store._state.selected_system.id ) and fleet.player == Store._state.player.id:
		Store.select_fleet(fleet)

func _on_fleet_created(fleet):
	if Store._state.selected_system == null || fleet.system != Store._state.selected_system.id:
		return
	add_fleet_item(fleet)

func _on_wallet_update(amount):
	if Store._state.selected_system == null || Store._state.selected_system.player != Store._state.player.id:
		return
	$ScrollContainer/HBoxContainer/FleetCreationButton.disabled = Store._state.player.wallet < FLEET_COST

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

func _input(event):
	if !event is InputEventKey || !is_visible():
		return
	if event.is_action_pressed("ui_add_fleet"):
		create_fleet()
	elif event.is_action_pressed("ui_select_fleet"):
		# get diff between first key and actual key to get the fleet list index
		var index = event.scancode - KEY_1
		if Store._state.selected_system.fleets.size() > index:
			Store.select_fleet(Store._state.selected_system.fleets.values()[index])
	elif Store._state.selected_fleet != null && event.is_action_pressed("ui_add_ships"):
		if has_node("ScrollContainer/HBoxContainer/Fleets/" + Store._state.selected_fleet.id):
			var node = get_node("ScrollContainer/HBoxContainer/Fleets/" + Store._state.selected_fleet.id)
			if Input.is_key_pressed(KEY_SHIFT):
				node.add_ships(5)
			else:
				node.add_ships(1)
