extends VBoxContainer

signal request_assignation(ship_category, quantity)

const _SHIP_GROUP_ELEMENT = preload("res://hud/system/fleet/ship_group_fleet_menu.tscn")
const ASSETS = preload("res://resources/assets.tres")

onready var details_container_ship_group = $ScrollContainer/MarginContainer/GridContainer
onready var check_button = $CheckButton

func _ready():
	check_button.connect("toggled", self, "_on_build_schip_button_toggled")
	for category in ASSETS.ship_models.values():
		var node = _SHIP_GROUP_ELEMENT.instance()
		node.ship_category = category
		node.name = category.category
		node.build_ships = check_button.pressed
		details_container_ship_group.add_child(node)
		node.connect("request_assignation", self, "_on_request_assignation")
		node.connect("spinbox_too_much", self, "_on_spinbox_too_much")


func _on_spinbox_too_much():
	check_button.too_much_animation()


func _on_build_schip_button_toggled(pressed):
	for node in details_container_ship_group.get_children():
		node.build_ships = pressed


func _on_request_assignation(ship_category, quantity):
	emit_signal("request_assignation", ship_category, quantity)


func update_element_fleet(fleet, formation):
	if details_container_ship_group == null:
		return
	var node_updated_details = []
	if fleet != null and fleet.squadrons != null:
		for i in fleet.squadrons:
			if i.formation == formation and  details_container_ship_group.has_node(i.category.category):
				var node_ship_group = details_container_ship_group.get_node(i.category.category)
				node_ship_group.quantity_fleet = i.quantity
				node_updated_details.push_back(node_ship_group.name)
	for node in details_container_ship_group.get_children():
		if not node_updated_details.has(node.name):
			node.quantity_fleet = 0


func refresh_hangar_elements(hangar):
	if details_container_ship_group == null:
		return
	for node in details_container_ship_group.get_children():
		node.quantity_hangar = 0
	for i in hangar:
		if details_container_ship_group.has_node(i.category.category):
			details_container_ship_group.get_node(i.category.category).quantity_hangar = i.quantity


func update_details_view(fleet, formation):
	if details_container_ship_group == null:
		return
	var squadron = fleet.get_squadron(formation)
	for node in details_container_ship_group.get_children():
		node.visible = squadron.category == node.ship_category if squadron != null else true
