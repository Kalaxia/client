extends MenuContainer

const _SHIP_GROUP_ELEMENT = preload("res://hud/system/fleet/ship_group_fleet_menu.tscn")

var fleet = null setget set_fleet
var ship_group_hangar = [] setget set_ship_group_hangar
var system_id = null 

onready var ship_group_element_container = $MenuBody/Body/ScrollContainer/ShipList
onready var assets = load("res://resources/assets.tres")


func _ready():
	Store.connect("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships")
	Store.connect("hangar_updated", self, "_on_hangar_updated")
	for category in assets.ship_models.values():
		var node = _SHIP_GROUP_ELEMENT.instance()
		node.ship_category = category
		node.name = category.category
		ship_group_element_container.add_child(node)
		node.connect("ship_assigned", self, "_on_ship_assigned", [category])
	update_hangar()
	update_element_fleet()
	# it is possible that we would call _refresh_hangar_elements multiple time
	# it is however necessary to call it as it is possible that the elments are not updated before
	# (as ship_group_element_container is null before ready) but that ship_group_hangar are already in memory
	_refresh_hangar_elements()


func _on_hangar_updated(system, ship_groups):
	if Store._state.selected_system != null and system.id == Store._state.selected_system.id:
		set_ship_group_hangar(ship_groups)


func _on_ship_assigned(_quantity_fleet, quantity_hangar, category):
	var has_added_quantity = false
	for i in ship_group_hangar:
		if i.category == category.category:
			i.quantity = quantity_hangar
			has_added_quantity = true
	if not has_added_quantity:
		ship_group_hangar.push_back({
			"system" : fleet.system,
			"fleet" : null,
			"category" : category.category,
			"quantity" : quantity_hangar,
		})
	Store.update_system_hangar(fleet.system, ship_group_hangar)


func update_hangar():
	if fleet == null or system_id == fleet.system:
		return
	system_id = fleet.system
	if Store._state.selected_system.has("hangar") and Store._state.selected_system.hangar != null:
		set_ship_group_hangar(Store._state.selected_system.hangar)
	else:
		set_ship_group_hangar([])
		Store.request_hangar(Store._state.game.systems[fleet.system])


func update_element_fleet():
	var node_updated = []
	if ship_group_element_container == null:
		return
	if fleet != null and fleet.ship_groups != null and ship_group_element_container != null:
		for i in fleet.ship_groups:
			var node_ship_group = ship_group_element_container.get_node(i.category)
			node_ship_group.quantity_fleet = i.quantity
			node_updated.push_back(node_ship_group.name)
	for node in ship_group_element_container.get_children():
		if not node_updated.has(node.name):
			node.quantity_fleet = 0


func set_fleet(new_fleet):
	fleet = new_fleet
	if fleet.system != system_id:
		update_hangar()
	update_element_fleet()


func set_ship_group_hangar(array):
	ship_group_hangar = array
	_refresh_hangar_elements()


func _refresh_hangar_elements():
	if ship_group_element_container == null:
		return
	for node in ship_group_element_container.get_children():
		node.quantity_hangar = 0
	for i in ship_group_hangar:
		ship_group_element_container.get_node(i.category).quantity_hangar = i.quantity


func _on_fleet_update_nb_ships(fleet_param):
	if fleet != null and fleet_param.id == fleet.id:
		set_fleet(fleet_param)
