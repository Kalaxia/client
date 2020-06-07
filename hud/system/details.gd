extends Control

var banners = {
	"Kalankar": preload("res://resources/assets/2d/faction/kalankar/banner.png"),
	"Valkar": preload("res://resources/assets/2d/faction/valkar/banner.png"),
	"Adranite": preload("res://resources/assets/2d/faction/adranite/banner.png"),
}
var fleet_item_scene = preload("res://hud/system/fleet_item.tscn")

const FLEET_COST = 10

func _ready():
	Store.connect("system_selected", self, "_on_system_selected")
	Store.connect("wallet_updated", self, "_on_wallet_update")
	Store.connect("fleet_created", self, "_on_fleet_created")
	Store.connect("fleet_update", self, "_on_fleet_update")
	Store.connect("fleet_erased", self, "_on_fleet_erased")
	Store.connect("system_update", self, "_on_system_update")
	Network.connect("Victory", self, "_on_victory")
	$FleetCreationButton.connect("pressed", self, "create_fleet")
	set_visible(false)

func _on_system_selected(system, old_system):
	set_visible(true)
	refresh_data(system)
	
func refresh_data(system):
	var banner_node = get_node("Header/FactionBanner")
	var player_node = get_node("Header/Player")
	var create_fleet_button = $FleetCreationButton
	create_fleet_button.set_visible(false)
	if system.player != null:
		var player = Store.get_game_player(system.player)
		banner_node.set_visible(true)
		banner_node.set_texture(banners[Store.get_faction(player.faction).name])
		player_node.set_text(player.username)
		player_node.set_visible(true)
		if system.player == Store._state.player.id:
			create_fleet_button.set_visible(true)
			create_fleet_button.disabled = Store._state.player.wallet < FLEET_COST
	else:
		banner_node.set_visible(false)
		player_node.set_visible(false)
		
	for f in $Fleets.get_children(): f.queue_free()
	
	for id in system.fleets: add_fleet_item(system.fleets[id])
		
func create_fleet():
	Network.req(self, "_on_request_completed"
		, "/api/games/" +
			Store._state.game.id + "/systems/" +
			Store._state.selected_system.id + "/fleets/"
		, [ "Content-Type: application/json" ]
		, HTTPClient.METHOD_POST
	)
	
func add_fleet_item(fleet):
	var fleet_node = fleet_item_scene.instance()
	fleet_node.set_name(fleet.id)
	fleet_node.fleet = fleet
	$Fleets.add_child(fleet_node)
	Store.select_fleet(fleet)
	
func _on_fleet_created(fleet):
	if Store._state.selected_system == null || fleet.system != Store._state.selected_system.id:
		return
	add_fleet_item(fleet)
	
func _on_wallet_update(amount):
	if Store._state.selected_system == null || Store._state.selected_system.player != Store._state.player.id:
		return
	$FleetCreationButton.disabled = Store._state.player.wallet < FLEET_COST

func _on_request_completed(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == 201:
		Store.update_wallet(-FLEET_COST)
		Store.add_fleet(JSON.parse(body.get_string_from_utf8()).result)

func _on_fleet_erased(fleet):
	if fleet.system == Store._state.selected_system.id:
		refresh_data(Store._state.selected_system)
	
func _on_fleet_update(fleet):
	refresh_data(Store._state.selected_system)

func _on_system_update(system):
	if system.id == Store._state.selected_system.id:
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
		if Input.is_key_pressed(KEY_SHIFT):
			get_node("Fleets/" + Store._state.selected_fleet.id).add_ships(5)
		else:
			get_node("Fleets/" + Store._state.selected_fleet.id).add_ships(1)

