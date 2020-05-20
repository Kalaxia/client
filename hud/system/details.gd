extends Control

var banners = {
	"Kalankar": preload("res://resources/assets/2d/faction/kalankar/banner.png"),
	"Valkar": preload("res://resources/assets/2d/faction/valkar/banner.png"),
	"Adranite": preload("res://resources/assets/2d/faction/adranite/banner.png"),
}

const FLEET_COST = 10

func _ready():
	$HTTPRequest.connect("request_completed", self, "_on_request_completed")
	Store.connect("system_selected", self, "_on_system_selected")
	Store.connect("wallet_updated", self, "_on_wallet_update")
	get_node("Fleets/Button").connect("pressed", self, "create_fleet")
	set_visible(false)

func _on_system_selected(system, old_system):
	set_visible(true)
	refresh_data(system)
	
func refresh_data(system):
	var banner_node = get_node("Header/FactionBanner")
	var player_node = get_node("Header/Player")
	var create_fleet_button = get_node("Fleets/Button")
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
		
func create_fleet():
	$HTTPRequest.request(Network.api_url + "/api/games/" + Store._state.game.id + "/fleets/", [
		"Authorization: Bearer " + Network.token,
		"Content-Type: application/json",
	], false, HTTPClient.METHOD_POST, JSON.print({ "system": Store._state.selected_system.id }))
	
func _on_wallet_update(amount):
	if Store._state.selected_system == null || Store._state.selected_system.player != Store._state.player.id:
		return
	get_node("Fleets/Button").disabled = Store._state.player.wallet < FLEET_COST

func _on_request_completed(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	Store.update_wallet(-FLEET_COST)
	Store.add_fleet(Store._state.selected_system.id, JSON.parse(body.get_string_from_utf8()).result)
