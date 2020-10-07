extends MenuContainer

const _SHIP_GROUP_ELEMENT = preload("res://hud/system/fleet/ship_group_fleet_menu.tscn")

var fleet : Fleet = null setget set_fleet
var ship_group_hangar = [] setget set_ship_group_hangar
var system_id = null 

var _game_data : GameData = Store.game_data

onready var ship_group_element_container = $MenuBody/Body/ScrollContainer/ShipList
onready var assets = load("res://resources/assets.tres")


func _ready():
	if fleet != null and not fleet.is_connected("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships"):
		fleet.connect("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships")
	_game_data.selected_state.connect("hangar_updated", self, "_on_hangar_updated") # is it necessary ?
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


func _on_hangar_updated(ship_groups):
	set_ship_group_hangar(ship_groups)


func _on_ship_assigned(_quantity_fleet, quantity_hangar, category):
	# todo methode
	var has_added_quantity = false
	for i in ship_group_hangar:
		if i.category.category == category.category:
			i.quantity = quantity_hangar
			has_added_quantity = true
	if not has_added_quantity:
		ship_group_hangar.push_back(ShipGroup.new({
			"system" : fleet.system,
			"fleet" : null,
			"category" : category.category,
			"quantity" : quantity_hangar,
		}))
	_game_data.selected_state.selected_system.set_hangar(ship_group_hangar)


func update_hangar():
	if fleet == null or system_id == fleet.system:
		return
	system_id = fleet.system
	if _game_data.selected_state.selected_system.hangar != null: # todo always true
		set_ship_group_hangar(_game_data.selected_state.selected_system.hangar)
	else:
		set_ship_group_hangar([])
		_game_data.request_hangar(_game_data.get_system(fleet.system))


func update_element_fleet():
	var node_updated = []
	if ship_group_element_container == null:
		return
	if fleet != null and fleet.ship_groups != null and ship_group_element_container != null:
		for i in fleet.ship_groups:
			var node_ship_group = ship_group_element_container.get_node(i.category.category)
			node_ship_group.quantity_fleet = i.quantity
			node_updated.push_back(node_ship_group.name)
	for node in ship_group_element_container.get_children():
		if not node_updated.has(node.name):
			node.quantity_fleet = 0


func set_fleet(new_fleet):
	if fleet != null and fleet.is_connected("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships"):
		fleet.disconnect("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships")
	fleet = new_fleet
	if fleet != null and not fleet.is_connected("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships"):
		fleet.connect("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships")
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
		ship_group_element_container.get_node(i.category.category).quantity_hangar = i.quantity


func _on_fleet_update_nb_ships():
	update_element_fleet()
