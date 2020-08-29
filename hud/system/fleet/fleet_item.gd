class_name FleetItem, "res://resources/editor/fleet_item.svg"
extends SelectablePanelContainer

signal pressed_open_ship_menu(fleet)

var fleet = null setget set_fleet



onready var key_binding_compo = $Container/Ships/ButtonMenu/KeyBindingLabelsContainer

func _ready():
	connect("focus_entered", self, "_on_focus_entered")
	connect("focus_exited", self, "_on_focus_exited")
	$Container/Player.set_text(Store.get_game_player(fleet.player).username)
	if fleet.player != Store._state.player.id:
		$Container/Ships.set_visible(false)
		return
	Store.connect("fleet_selected",self,"_on_fleet_selected")
	Store.connect("fleet_sailed",self,"_on_fleet_sailed")
	Store.connect("fleet_update_nb_ships",self,"_on_fleet_update_nb_ships")
	Store.connect("fleet_unselected",self,"_on_fleet_unselected")
	$Container/Ships/ButtonMenu.connect("pressed", self, "open_menu_ship_pressed")
	connect("pressed", self, "_on_pressed")
	update_quantity()


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
	var quantity = 0
	for i in fleet.ship_groups:
		quantity +=  i.quantity
	$Container/Ships/NbShips.text = str(quantity)


func set_fleet(new_fleet):
	fleet = new_fleet
	update_quantity()


func set_key_binding_number(position_of_event):
	$KeyBindingLabelsContainer.pos_of_events = PoolIntArray([position_of_event])
	$KeyBindingLabelsContainer.visibility = true
	

