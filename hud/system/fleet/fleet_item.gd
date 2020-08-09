class_name FleetItem, "res://resources/editor/fleet_item.svg"
extends SelectablePanelContainer

signal pressed_open_ship_menu(fleet)

var fleet = null setget set_fleet


func _ready():
	._ready()
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


func open_menu_ship_pressed():
	if Store._state.selected_fleet == null or Store._state.selected_fleet.id != fleet.id:
		Store.select_fleet(fleet)
	emit_signal("pressed_open_ship_menu", fleet)


func _on_pressed():
	if fleet.destination_system == null and is_selected:
		Store.select_fleet(fleet)
		#this will call _on_fleet_selected as the store emit a signal


func _on_fleet_selected(fleet_param):
	print(fleet_param)
	if fleet_param.id != fleet.id:
		self.is_selected = false


func _on_fleet_sailed(fleet_param, arrival_time):
	if fleet_param.id != fleet.id: 
		self.is_selected = false


func _on_fleet_unselected():
	self.is_selected = false


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
