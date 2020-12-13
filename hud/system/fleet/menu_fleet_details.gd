extends VBoxContainer

signal request_assignation(ship_category, quantity)

const ASSETS = preload("res://resources/assets.tres")

var fleet setget set_fleet # no need to connect signas as the parent (menu_fleet) mange the signal
var formation setget set_formation
var hangar setget set_hangar # idem no need to manage signal here for change
var _game_data : GameData = Store.game_data

onready var ship_group_details = $ScrollContainer/MarginContainer/GridContainer/ShipGroupFleetMenu


func _ready():
	upatde_build_ship()
	ship_group_details.connect("request_assignation", self, "_on_request_assignation")
	ship_group_details.connect("ship_category_changed", self, "_on_ship_category_changed")
	_update_element(fleet, formation, hangar)
	_game_data.selected_state.connect("system_selected", self, "_on_system_selected")
	_game_data.selected_state.connect("building_contructed", self, "_on_building_contructed")


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


func _on_system_selected(_old_system):
	upatde_build_ship()


func upatde_build_ship():
	var system = _game_data.selected_state.selected_system
	ship_group_details.build_ships = system.has_shipyard()


func _on_building_contructed(building):
	if building.kind.kind == "shipyard":
		ship_group_details.build_ships = true
