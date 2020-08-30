class_name FleetItem, "res://resources/editor/fleet_item.svg"
extends SelectablePanelContainer

signal pressed_open_ship_menu(fleet)
signal fleet_donated()

var fleet = null setget set_fleet
var _lock_donate = Utils.Lock.new() setget private_set, private_get

onready var key_binding_compo = $Container/Ships/ButtonMenu/KeyBindingLabelsContainer
onready var button_give = $Container/Ships/ButtonGive
onready var button_menu = $Container/Ships/ButtonMenu

func _ready():
	update_owner()
	Store.connect("fleet_selected",self,"_on_fleet_selected")
	Store.connect("fleet_sailed",self,"_on_fleet_sailed")
	Store.connect("fleet_update_nb_ships",self,"_on_fleet_update_nb_ships")
	Store.connect("fleet_unselected",self,"_on_fleet_unselected")
	button_menu.connect("pressed", self, "open_menu_ship_pressed")
	button_give.connect("pressed", self, "_on_give_pressed")


func update_owner():
	$Container/Player.text = Store.get_game_player(fleet.player).username
	$Container/Ships.visible = fleet.player == Store._state.player.id
	_update_button_give_visibility()
	_update_composition_button_visibility()
	update_quantity()
	if fleet.player == Store._state.player.id:
		if not is_connected("pressed", self, "_on_pressed"):
			connect("pressed", self, "_on_pressed")
		if not is_connected("focus_entered", self, "_on_focus_entered"):
			connect("focus_entered", self, "_on_focus_entered")
		if not is_connected("focus_exited", self, "_on_focus_exited"):
			connect("focus_exited", self, "_on_focus_exited")
	else:
		if is_connected("pressed", self, "_on_pressed"):
			disconnect("pressed", self, "_on_pressed")
		if is_connected("focus_entered", self, "_on_focus_entered"):
			disconnect("focus_entered", self, "_on_focus_entered")
		if is_connected("focus_exited", self, "_on_focus_exited"):
			disconnect("focus_exited", self, "_on_focus_exited")


func _update_composition_button_visibility():
	if button_menu == null:
		return
	button_menu.visible = fleet.player == Store._state.player.id \
			and Store.get_system(fleet.system).player == Store._state.player.id


func _update_button_give_visibility():
	if button_give == null:
		return
	button_give.visible = fleet.player == Store._state.player.id \
			and Store.get_system(fleet.system).player != Store._state.player.id \
			and Store.get_system(fleet.system).player != null \
			and Store.get_game_player(Store.get_system(fleet.system).player).faction == Store._state.player.faction


func _on_give_pressed():
	if not _lock_donate.try_lock():
		return
	Network.req(self, "_on_fleet_given",
		"/api/games/" + Store._state.game.id + "/systems/" + fleet.system + "/fleets/" + fleet.id + "/donate/",
		HTTPClient.METHOD_PATCH, [], "", [fleet]
	)


func _on_fleet_given(err, response_code, headers, body, fleet_p):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_NO_CONTENT:
		Store.update_fleet_owner(fleet_p, Store.get_system(fleet_p.system).player)
		emit_signal("fleet_donated")
	_lock_donate.unlock()


func _gui_input(event):
	if has_focus() and event.is_action_pressed("ui_accept"):
		open_menu_ship_pressed()


func _on_focus_entered():
	key_binding_compo.visibility = true


func _on_focus_exited():
	key_binding_compo.visibility = false


func open_menu_ship_pressed():
	if Store._state.selected_fleet == null or Store._state.selected_fleet.id != fleet.id:
		Store.select_fleet(fleet)
	emit_signal("pressed_open_ship_menu", fleet)


func _on_pressed():
	if fleet.destination_system == null and is_selected:
		Store.select_fleet(fleet)
		#this will call _on_fleet_selected as the store emit a signal


func _on_fleet_selected(fleet_param):
	set_is_selected(fleet_param.id == fleet.id)


func _on_fleet_sailed(fleet_param, arrival_time):
	if fleet_param.id != fleet.id: 
		set_is_selected(false)


func _on_fleet_unselected():
	set_is_selected(false)


func _on_fleet_update_nb_ships(fleet_param):
	if fleet_param.id == fleet.id or fleet.ship_groups == null:
		var quantity = 0
		for i in fleet_param.ship_groups:
			quantity += i.quantity
		$Container/Ships/NbShips.text = str(quantity)


func update_quantity():
	if fleet == null or fleet.ship_groups == null:
		return
	var text_quantity = ""
	if fleet.player == Store._state.player.id:
		var quantity = 0
		for i in fleet.ship_groups:
			quantity +=  i.quantity
		text_quantity = quantity as String
	$Container/Ships/NbShips.text = text_quantity


func set_fleet(new_fleet):
	fleet = new_fleet
	update_owner()


func set_key_binding_number(position_of_event):
	$KeyBindingLabelsContainer.pos_of_events = PoolIntArray([position_of_event])
	$KeyBindingLabelsContainer.visibility = true


func private_set(variant):
	pass


func private_get():
	return null
