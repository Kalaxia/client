extends Control

class_name FleetItem

var fleet = null
var theme_highlight = preload("res://themes/theme_main_square_button_highlight.tres")
var theme_not_highlight = preload("res://themes/theme_main_square_button.tres")
var _quantity = 0
var _is_locked = Utils.Lock.new()

const SHIP_COST = 10

func _ready():
	$Container/Player.set_text(Store.get_game_player(fleet.player).username)
	if fleet.player != Store._state.player.id:
		$Container/Ships.set_visible(false)
		return
	Store.connect("wallet_updated", self, "_on_wallet_update")
	Store.connect("fleet_selected",self,"_on_fleet_selected")
	Store.connect("fleet_sailed",self,"_on_fleet_sailed")
	Store.connect("fleet_update_nb_ships",self,"_on_fleet_update_nb_ships")
	Store.connect("fleet_unselected",self,"_on_fleet_unselected")
	get_node("Container/Ships/NbShips").set_text(str(fleet.nb_ships))
	get_node("Container/Ships/CreationButton").connect("pressed", self, "add_ship")
	connect("gui_input", self, "button_sail_fleet")
	check_button_add_ship_state()
	update_highlight_state()
	
func add_ship():
	add_ships(1)

func add_ships(quantity):
	# prevent keyboard shortcuts as well
	if _is_locked.try_lock() != Utils.Lock.LOCK_STATE.OK:
		return
	if Store._state.player.wallet < quantity*SHIP_COST :
		_is_locked.unlock()
		return
	_quantity = quantity
	Network.req(self, "_on_ship_added"
		, "/api/games/" +
			Store._state.game.id+  "/systems/" +
			Store._state.selected_system.id + "/fleets/" +
			fleet.id + "/ships/"
		, HTTPClient.METHOD_POST
		, [ "Content-Type: application/json" ]
		, JSON.print({ "quantity": quantity })
	)
	get_node("Container/Ships/CreationButton").disabled = true
	
func check_button_add_ship_state():
	get_node("Container/Ships/CreationButton").disabled = Store._state.player.wallet < SHIP_COST || _is_locked.get_is_locked()
	
func check_button_sail_state():
	get_node("Container/Ships/SailFleet").disabled = (fleet.destination_system != null)
	#todo highlight if it is selected fleet

func button_sail_fleet(event):
	if event is InputEventMouseButton and event.is_pressed() && event.get_button_index() == BUTTON_LEFT && fleet.destination_system == null:
		Store.select_fleet(fleet)
		#this will call _on_fleet_selected as the store emit a signal

func _on_ship_added(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_CREATED:
		Store.update_wallet(-SHIP_COST * _quantity)
		Store.update_fleet_nb_ships(fleet, fleet.nb_ships + _quantity)
	_quantity = 0
	_is_locked.unlock()
	check_button_add_ship_state()

func _on_wallet_update(amount):
	check_button_add_ship_state()

func _on_fleet_selected(fleet):
	update_highlight_state()
	
func _on_fleet_sailed(fleet, arrival_time):
	update_highlight_state()

func _on_fleet_unselected():
	update_highlight_state()

func _on_fleet_update_nb_ships(fleet_param):
	if fleet_param.id == fleet.id:
		get_node("Container/Ships/NbShips").set_text(str(fleet.nb_ships))

func update_highlight_state():
	if Store._state.selected_fleet != null && Store._state.selected_fleet.id == fleet.id:
		set_theme(theme_highlight)
	else:
		set_theme(theme_not_highlight)
