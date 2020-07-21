extends Control

class_name FleetItem, "res://resources/editor/fleet_item.svg"

var fleet = null setget set_fleet
var theme_highlight = preload("res://themes/theme_main_square_button_highlight.tres")
var theme_not_highlight = preload("res://themes/theme_main_square_button.tres")
#var _quantity = 0
#var _is_locked = Utils.Lock.new()

signal pressed_open_ship_menu(fleet)

const SHIP_COST = 10

func _ready():
	$Container/Player.set_text(Store.get_game_player(fleet.player).username)
	if fleet.player != Store._state.player.id:
		$Container/Ships.set_visible(false)
		return
	Store.connect("fleet_selected",self,"_on_fleet_selected")
	Store.connect("fleet_sailed",self,"_on_fleet_sailed")
	Store.connect("fleet_update_nb_ships",self,"_on_fleet_update_nb_ships")
	Store.connect("fleet_unselected",self,"_on_fleet_unselected")
	$Container/Ships/ButtonMenu.connect("pressed", self, "open_menu_ship_pressed")
	connect("gui_input", self, "button_sail_fleet")
	update_quantity()
	update_highlight_state()
	
func open_menu_ship_pressed():
	if Store._state.selected_fleet == null or Store._state.selected_fleet.id != fleet.id:
		Store.select_fleet(fleet)
	emit_signal("pressed_open_ship_menu",fleet)

func button_sail_fleet(event):
	if event is InputEventMouseButton and event.is_pressed() && event.get_button_index() == BUTTON_LEFT && fleet.destination_system == null:
		Store.select_fleet(fleet)
		#this will call _on_fleet_selected as the store emit a signal

func _on_fleet_selected(fleet):
	update_highlight_state()
	
func _on_fleet_sailed(fleet, arrival_time):
	update_highlight_state()

func _on_fleet_unselected():
	update_highlight_state()

func _on_fleet_update_nb_ships(fleet_param):
	if fleet_param.id == fleet.id or fleet.ship_groups == null:
		var quantity = 0
		for i in fleet_param.ship_groups:
			quantity +=  i.quantity
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

func update_highlight_state():
	if Store._state.selected_fleet != null && Store._state.selected_fleet.id == fleet.id:
		set_theme(theme_highlight)
	else:
		set_theme(theme_not_highlight)
