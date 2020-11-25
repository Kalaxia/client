extends VBoxContainer

signal request_assignation(ship_category, quantity)

const _SHIP_GROUP_ELEMENT = preload("res://hud/system/fleet/ship_group_fleet_menu.tscn")
const ASSETS = preload("res://resources/assets.tres")

var fleet setget set_fleet # no need to connect signas as the parent (menu_fleet) mange the signal
var formation setget set_formation
var hangar setget set_hangar # idem no need to manage signal here for change

onready var check_button = $CheckButton
onready var ship_group_details = $ScrollContainer/MarginContainer/GridContainer/ShipGroupFleetMenu

func _ready():
	check_button.connect("toggled", self, "_on_build_schip_button_toggled")
	ship_group_details.build_ships = check_button.pressed
	ship_group_details.connect("request_assignation", self, "_on_request_assignation")
	ship_group_details.connect("spinbox_too_much", self, "_on_spinbox_too_much")
	ship_group_details.connect("ship_category_changed", self, "_on_ship_category_changed")
	_update_element(fleet, formation, hangar)


func _on_spinbox_too_much():
	check_button.too_much_animation()


func _on_build_schip_button_toggled(pressed):
	ship_group_details.build_ships = pressed


func _on_request_assignation(ship_category, quantity):
	emit_signal("request_assignation", ship_category, quantity)


func set_fleet(fleet_param):
	fleet = fleet_param
	_refresh_fleet(fleet, formation)
	# if the type of ship changes the element ship_group_details will emit the signal
	# ship_category_changed and the hangar number will be updated


func set_formation(formation_param):
	formation = formation_param
	_refresh_fleet(fleet, formation)
	# idem as in set_fleet


func set_hangar(hangar_param):
	hangar = hangar_param
	_refresh_hangar(hangar)


func _update_element(fleet_param, formation_param, hangar_param):
	if ship_group_details == null:
		return
	_refresh_fleet(fleet_param, formation_param)
	_refresh_hangar(hangar_param)


func _refresh_fleet(fleet_param, formation_param):
	if ship_group_details == null:
		return
	if fleet_param != null and fleet_param.squadrons != null:
		var squadron = fleet_param.get_squadron(formation_param)
		if squadron != null:
			ship_group_details.quantity_fleet = squadron.quantity
			if squadron.quantity != 0:
				ship_group_details.ship_category = squadron.category 
			return
	ship_group_details.quantity_fleet = 0


func _refresh_hangar(hangar_param):
	if ship_group_details == null:
		return
	ship_group_details.quantity_hangar = 0
	if hangar_param == null:
		return
	for i in hangar_param:
		if ship_group_details.ship_category == i.category:
			ship_group_details.quantity_hangar += i.quantity


func _on_ship_category_changed():
	_refresh_hangar(hangar)
