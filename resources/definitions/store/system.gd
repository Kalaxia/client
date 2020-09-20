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

const MAX_NUMBER_OF_BUILDING = 1

export(String) var player # ressource ?
export(String) var kind
export(Vector2) var coordinates
export(bool) var unreachable
export(Dictionary) var fleets
export(Array, Resource) var buildings setget set_buildings
export(Array, Resource) var hangar setget set_hangar
export(String) var game = null
export(String) var id


func _init(dict = null).(dict):
	pass


func load_dict(dict):
	if dict == null:
		return
	.load_dict(dict)
	if not dict is Dictionary or dict.has("fleet"):
		for fleet in dict.fleets:
			fleets[fleet.id] = Fleet.new(fleets)
	if not dict is Dictionary or dict.has("coordinates"):
		coordinates = Vector2(dict.coordinates.x, dict.coordinates.y)


func _get_dict_property_list() -> Array:
	return ["player", "kind", "unreachable", "game", "id"]


func add_fleet_dict(fleet_dict : Dictionary):
	add_fleet(Fleet.new(fleet_dict))


func add_fleet(fleet : Fleet):
	fleets[fleet.id] = fleet
	emit_signal("fleet_added", fleet)
	emit_signal("changed")


func erase_fleet(fleet : Fleet):
	var has_ereased = fleets.erase(fleet.id)
	if has_ereased:
		fleet.on_fleet_erased()
		emit_signal("fleet_fleet_erased", fleet)
		emit_signal("changed")
	return has_ereased


func erase_fleet_id(fleet_id : String):
	var has_fleet = fleets.has(fleet_id)
	if has_fleet:
		var fleet = fleets[fleet_id]
		fleets.erase(fleet_id)
		fleet.on_fleet_erased()
		emit_signal("fleet_fleet_erased", fleet)
		emit_signal("changed")
	return has_fleet


func erase_all_fleet():
	var fleets_previous = fleets
	fleets.clear()
	for fleet in fleets_previous.values():
		emit_signal("fleet_erased", fleet)
	emit_signal("changed")


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
	# game data call this and oly game data should call this
	fleets[fleet.id] = fleet
	fleet.arrived()
	emit_signal("fleet_arrived", fleet)


func building_contructed(building):
	add_building_to_system(building)
	emit_signal("building_contructed", building)
