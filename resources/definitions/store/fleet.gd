class_name Fleet
extends DictResource

signal fleet_owner_updated()
signal fleet_update_nb_ships()
signal fleet_erased()
signal updated()

export(Array) var ship_groups = [] setget set_ship_groups
export(String) var player setget set_player
export(String) var id = null
export(String) var system = null


func _init(dict = null).(dict):
	pass


func _get_dict_property_list():
	return ["ship_groups", "id", "system"]


func update_fleet_owner(new_player):
	self.player = new_player.id


func set_player(new_player_id):
	# todo review
	player = new_player_id
	emit_signal("changed")
	emit_signal("fleet_owner_updated")


func update_fleet_nb_ships(ship_category : ShipModel, nb_ships : int):
	var ship_group_updated
	var has_updated_number = false
	for ship_group in ship_groups:
		if ship_group.category == ship_category:
			ship_group.quantity = nb_ships
			has_updated_number = true
			ship_group_updated = ship_group
	if not has_updated_number:
		ship_group_updated = ShipGroup.new({
			"category" : ship_category.category, 
			"quantity" : nb_ships,
			"fleet" : self.id,
			"system" : self.system,
		})
		self.ship_groups.push_back(ship_group_updated)
	emit_signal("fleet_update_nb_ships")
	return ship_group_updated


func set_ship_groups(new_ship_groups):
	ship_groups = new_ship_groups
	emit_signal("fleet_update_nb_ships")


func on_fleet_erased():
	emit_signal("fleet_erased")


func update_fleet(dict : Dictionary):
	load_dict(dict)
	emit_signal("updated")
