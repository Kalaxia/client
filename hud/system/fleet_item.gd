extends Control

var fleet = null

const SHIP_COST = 10

func _ready():
	$Player.set_text(Store.get_game_player(fleet.player).username)
	if fleet.player != Store._state.player.id:
		$Ships.set_visible(false)
		return
	$HTTPRequest.connect("request_completed", self, "_on_ship_added")
	Store.connect("wallet_updated", self, "_on_wallet_update")
	get_node("Ships/NbShips").set_text(str(fleet.nb_ships))
	get_node("Ships/CreationButton").connect("pressed", self, "add_ship")
	check_button_state()
	
func add_ship():
	$HTTPRequest.request(
		Network.api_url + "/api/games/" +
		Store._state.game.id+  "/systems/" +
		Store._state.selected_system.id + "/fleets/" +
		fleet.id + "/ships/", [
		"Authorization: Bearer " + Network.token
	], false, HTTPClient.METHOD_POST)
	get_node("Ships/CreationButton").disabled = true
	
func check_button_state():
	get_node("Ships/CreationButton").disabled = Store._state.player.wallet < SHIP_COST
	
func _on_ship_added(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	Store.update_wallet(-SHIP_COST)
	fleet.nb_ships += 1
	check_button_state()
	get_node("Ships/NbShips").set_text(str(fleet.nb_ships))

func _on_wallet_update(amount):
	check_button_state()
