class_name FleetItem, "res://resources/editor/fleet_item.svg"
extends SelectablePanelContainer

signal pressed_open_ship_menu(fleet)
signal fleet_donated()

var fleet : Fleet = null setget set_fleet
var _lock_donate = Utils.Lock.new() setget private_set, private_get
var _game_data : GameData = Store.game_data

onready var key_binding_compo = $Container/Ships/ButtonMenu/KeyBindingLabelsContainer
onready var button_give = $Container/Ships/ButtonGive
onready var button_menu = $Container/Ships/ButtonMenu


func _ready():
	update_owner()
	_connect_fleet()
	_game_data.selected_state.connect("fleet_selected", self, "_on_fleet_selected")
	_game_data.connect("fleet_sailed", self, "_on_fleet_sailed")
	_game_data.selected_state.connect("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships")
	_game_data.selected_state.connect("fleet_unselected", self, "_on_fleet_unselected")
	button_menu.connect("pressed", self, "open_menu_ship_pressed")
	button_give.connect("pressed", self, "_on_give_pressed")
	set_is_selected(_game_data.selected_state.selected_fleet.id == fleet.id)


func update_owner():
	$Container/Player.text = _game_data.get_player(fleet.player).username
	$Container/Ships.visible = _game_data.does_belong_to_current_player(fleet)
	_update_button_give_visibility()
	_update_composition_button_visibility()
	update_quantity()
	if _game_data.does_belong_to_current_player(fleet):
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


func set_key_binding_number(position_of_event):
	$KeyBindingLabelsContainer.pos_of_events = PoolIntArray([position_of_event])
	$KeyBindingLabelsContainer.visibility = true


func _update_composition_button_visibility():
	if button_menu == null:
		return
	button_menu.visible = _game_data.does_belong_to_current_player(fleet) \
			and _game_data.does_belong_to_current_player(_game_data.get_system(fleet.system))


func _update_button_give_visibility():
	if button_give == null:
		return
	button_give.visible = _game_data.does_belong_to_current_player(fleet) \
			and not _game_data.does_belong_to_current_player(_game_data.get_system(fleet.system)) \
			and _game_data.get_system(fleet.system).player != null \
			and _game_data.get_player(_game_data.get_system(fleet.system).player).faction == _game_data.player.faction


func _on_give_pressed():
	if not _lock_donate.try_lock():
		return
	Network.req(self, "_on_fleet_given",
		"/api/games/" + _game_data.id + "/systems/" + fleet.system + "/fleets/" + fleet.id + "/donate/",
		HTTPClient.METHOD_PATCH, [], "", [fleet]
	)


func _on_fleet_given(err, response_code, _headers, _body, fleet_p):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_NO_CONTENT:
		fleet.update_fleet_owner(_game_data.get_player(_game_data.get_system(fleet_p.system).player))
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
	if _game_data.selected_state.selected_fleet == null or _game_data.selected_state.selected_fleet.id != fleet.id:
		_game_data.selected_state.select_fleet(fleet)
	emit_signal("pressed_open_ship_menu", fleet)


func _on_pressed():
	if fleet.destination_system == null and is_selected:
		_game_data.selected_state.select_fleet(fleet)
		#this will call _on_fleet_selected as the store emit a signal


func _on_fleet_selected(_old_fleet):
	set_is_selected(_game_data.selected_state.selected_fleet.id == fleet.id)


func _on_fleet_sailed(fleet_param):
	if fleet_param.id != fleet.id: 
		set_is_selected(false)


func _on_fleet_unselected(_old_fleet):
	set_is_selected(false)


func _on_fleet_update_nb_ships():
	if _game_data.selected_state.selected_fleet.id == fleet.id:
		var quantity = 0 # todo methode get_number of ships
		for i in _game_data.selected_state.selected_fleet.ship_groups:
			quantity += i.quantity
		$Container/Ships/NbShips.text = str(quantity)


func update_quantity():
	if fleet == null or fleet.ship_groups == null:
		return
	var text_quantity = ""
	if _game_data.does_belong_to_current_player(fleet):
		var quantity = 0
		for i in fleet.ship_groups:
			quantity +=  i.quantity
		text_quantity = quantity as String
	$Container/Ships/NbShips.text = text_quantity


func set_fleet(new_fleet):
	_disconnect_fleet()
	fleet = new_fleet
	_connect_fleet()
	update_owner()


func _connect_fleet(fleet_p : Fleet = fleet):
	if fleet_p != null and not fleet.is_connected("owner_updated", self, "_on_fleet_owner_updated"):
		fleet_p.connect("owner_updated", self, "_on_fleet_owner_updated")
	if fleet_p != null and not fleet.is_connected("updated", self, "_on_fleet_update"):
		fleet_p.connect("updated", self, "_on_fleet_update")


func _disconnect_fleet(fleet_p : Fleet = fleet):
	if fleet_p != null and fleet_p.is_connected("owner_updated", self, "_on_fleet_owner_updated"):
		fleet_p.disconnect("owner_updated", self, "_on_fleet_owner_updated")
	if fleet_p != null and fleet_p.is_connected("updated", self, "_on_fleet_update"):
		fleet_p.disconnect("updated", self, "_on_fleet_update")


func _on_fleet_owner_updated():
	update_owner()


func _on_fleet_update():
	_update_button_give_visibility()
	_update_composition_button_visibility()
	update_quantity()


func private_set(_variant):
	pass


func private_get():
	return null
