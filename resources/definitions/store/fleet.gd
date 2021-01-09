class_name Fleet
extends DictResource

signal owner_updated()
signal fleet_update_nb_ships()
signal fleet_erased()
signal updated()
signal arrived()

export(Array) var squadrons setget set_squadrons
export(String) var player setget set_player
export(String) var id = null
export(String) var system = null
export(String) var destination_system = null
export(int) var destination_arrival_date
export(bool) var is_destroyed = false

func _init(dict = null).(dict):
	pass


func load_dict(dict):
	if dict == null:
		return
	.load_dict(dict)
	set_squadrons_dict(dict.squadrons)


func _get_dict_property_list():
	return ["id", "system", "destination_system", "player", "destination_arrival_date", "is_destroyed"]


func update_fleet_owner(new_player):
	self.player = new_player.id


func set_player(new_player_id):
	player = new_player_id
	emit_signal("changed")
	emit_signal("owner_updated")


func add_ship_group(squadron : ShipGroup, formation):
	var previous_squadron = get_squadron(formation, squadron.category)
	var previous_quantity = previous_squadron.quantity if previous_squadron != null else 0
	update_fleet_nb_ships(squadron.category, previous_quantity + squadron.quantity, formation)


func update_fleet_nb_ships(ship_category : ShipModel, nb_ships : int, formation : String):
	var has_updated_number = false
	for ship_group in squadrons:
		if ship_group.category == ship_category and ship_group.formation == formation:
			ship_group.quantity = nb_ships
			if nb_ships == 0:
				squadrons.erase(ship_group)
			has_updated_number = true
			break
	if not has_updated_number:
		if nb_ships > 0:
			var ship_group_updated = FleetSquadron.new({
				"category" : ship_category.category, 
				"quantity" : nb_ships,
				"fleet" : self.id,
				"formation" : formation,
			})
			squadrons.push_back(ship_group_updated)
	emit_signal("changed")
	emit_signal("fleet_update_nb_ships")


func set_squadrons(new_ship_groups):
	squadrons = new_ship_groups
	_remove_empty_squadron()
	emit_signal("fleet_update_nb_ships")
	emit_signal("changed")


func set_squadrons_dict(array):
	squadrons.clear() # todo review connection to previous ship group are eareased
	for ship_group in array:
		if ship_group.quantity > 0:
			squadrons.push_back(FleetSquadron.new(ship_group))
	emit_signal("fleet_update_nb_ships")
	emit_signal("changed")


func on_fleet_erased():
	emit_signal("fleet_erased")


func update_fleet(dict : Dictionary):
	load_dict(dict)
	emit_signal("updated")


func arrived():
	# only system should call this in fleet_arrive
	emit_signal("arrived")


func get_squadron(formation, ship_category : ShipModel = null):
	# normaly you only have one squadron per foramation so you do not to have to specify the categroy
	# however the client code does not prevent you from having mulitple squadron per formation
	# and this is use to prevent to miss count schip form one type to another by instance in add_ship_group
	for i in squadrons:
		if i.formation == formation and (ship_category == null or i.category == ship_category):
			return i
	return null


func _remove_empty_squadron():
	for ship_group in squadrons:
		if ship_group.quantity == 0:
			squadrons.erase(ship_group)


func get_number_of_ships():
	var number = 0
	for squadron in squadrons:
		number += squadron.quantity
	return number


func is_empty():
	return get_number_of_ships() == 0


func is_destroyed():
	return is_empty() and is_destroyed
