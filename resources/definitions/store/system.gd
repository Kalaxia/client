class_name System
extends DictResource

signal fleet_added(fleet)
signal fleet_erased(fleet)
signal building_updated()
signal hangar_updated(hangar)
signal system_owner_updated()
signal updated()
signal fleet_arrived(fleet)
signal building_contructed(building) # todo selected system state
signal fleet_owner_updated(fleet)
signal ship_queue_finished(ship_group)
signal ship_queue_added(ship_queue)
signal ship_queue_removed(ship_queue) # emited when a ship_queue is removed but not finished

const MAX_NUMBER_OF_BUILDING = 1

export(String) var player # ressource ?
export(String) var kind
export(Vector2) var coordinates
export(bool) var unreachable
export(Dictionary) var fleets # this should be accessed read only
export(Array, Resource) var buildings setget set_buildings
export(Array, Resource) var hangar setget set_hangar
export(String) var game = null
export(String) var id
export(Array, Resource) var ship_queues setget set_ship_queues


func _init(dict = null).(dict):
	pass


func load_dict(dict):
	if dict == null:
		return
	.load_dict(dict)
	if not dict is Dictionary or dict.has("fleet"):
		erase_all_fleet()
		for fleet in dict.fleets:
			if fleet is Fleet:
				add_fleet(fleet)
			elif fleet is Dictionary:
				add_fleet_dict(fleet)
	if not dict is Dictionary or dict.has("coordinates"):
		coordinates = Vector2(dict.coordinates.x, dict.coordinates.y)
	if not dict is Dictionary or dict.has("ship_queues"):
		ship_queues.clear()
		for queue in dict.ship_queues:
			ship_queues.push_back(ShipQueue.new(queue) if not queue is ShipQueue else queue)


func _get_dict_property_list() -> Array:
	return ["player", "kind", "unreachable", "game", "id"]


func add_fleet_dict(fleet_dict : Dictionary):
	if fleets.has(fleet_dict.id):
		fleets[fleet_dict.id].update_fleet(fleet_dict)
	else:
		add_fleet(Fleet.new(fleet_dict))


func add_fleet(fleet : Fleet):
	var has_fleet = fleets.has(fleet.id)
	_add_fleet_to_storage(fleet)
	if not has_fleet:
		emit_signal("fleet_added", fleet)
		emit_signal("changed")


func erase_fleet(fleet : Fleet):
	return _remove_fleet_from_storage(fleet)


func erase_fleet_id(fleet_id : String):
	if fleets.has(fleet_id):
		return _remove_fleet_from_storage(fleets[fleet_id])
	return false


func erase_all_fleet():
	for fleet in fleets.values():
		_remove_fleet_from_storage(fleet)


func set_buildings(buildings_p):
	buildings = buildings_p
	emit_signal("building_updated")
	emit_signal("changed")


func set_hangar(ship_groups):
	hangar = ship_groups
	emit_signal("hangar_updated", hangar)
	emit_signal("changed")


func add_ship_group_to_hangar(ship_group : ShipGroup):
	var has_added_ships = false
	var hangar_ship_groups = hangar
	for i in hangar_ship_groups:
		if i.category ==  ship_group.category:
			i.quantity += ship_group.quantity
			has_added_ships = true
			break
	if not has_added_ships:
		hangar_ship_groups.push_back(ship_group)
	set_hangar(hangar_ship_groups)


func add_building_to_system(building : Building):
	var total_buildings = buildings
	var has_building = false
	for i in range(total_buildings.size()):
		if total_buildings[i].id == building.id:
			total_buildings[i] = building
			has_building = true
			break
	if not has_building and buildings.size() < MAX_NUMBER_OF_BUILDING:
		total_buildings.push_back(building)
	set_buildings(total_buildings)


func update_system_owner(player_p): 
	# review name operation
	for fid in fleets.keys():
		if fleets[fid].destination_system != null:
			erase_fleet(fleets[fid])
	player = player_p.id
	emit_signal("system_owner_updated")


func get_fleet(fleet_id : String):
	return fleets[fleet_id] if fleets.has(fleet_id) else null


func update(dict : Dictionary):
	load_dict(dict)
	emit_signal("updated")
	emit_signal("changed")


func fleet_arrive(fleet : Fleet): 
	# game data call this and only game data should call this
	_add_fleet_to_storage(fleet)
	fleet.arrived()
	emit_signal("fleet_arrived", fleet)


func building_contructed(building):
	add_building_to_system(building)
	emit_signal("building_contructed", building)


func _on_fleet_owner_updated(fleet):
	if fleet.system == id:
		emit_signal("fleet_owner_updated", fleet)


func queue_finished(ship_group : ShipGroup):
	for i in range(ship_queues.size()):
		if ship_queues[i].id == ship_group.id:
			ship_queues.remove(i)
			break
	add_ship_group_to_hangar(ship_group)
	ship_group.on_finished()
	emit_signal("ship_queue_finished", ship_group)


func add_ship_queue(ship_queue : ShipQueue):
	ship_queues.push_back(ship_queue)
	emit_signal("ship_queue_added", ship_queue)


func set_ship_queues(new_ship_queues):
	if ship_queues != new_ship_queues:
		for queue in ship_queues:
			emit_signal("ship_queue_removed", queue)
		ship_queues = new_ship_queues
		emit_signal("changed")
		for queue in ship_queues:
			emit_signal("ship_queue_added", queue)


func _add_fleet_to_storage(fleet):
	fleets[fleet.id] = fleet
	fleet.connect("owner_updated", self, "_on_fleet_owner_updated", [fleet])


func _remove_fleet_from_storage(fleet):
	var has_ereased = fleets.erase(fleet.id)
	if has_ereased:
		fleet.disconnect("owner_updated", self, "_on_fleet_owner_updated")
		fleet.on_fleet_erased()
		emit_signal("fleet_fleet_erased", fleet)
		emit_signal("changed")
	return has_ereased
