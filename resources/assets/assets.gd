tool
extends Resource
class_name KalaxiaAssets,"res://resources/assets/2d/white_logo.png"

export(Array, Resource) var factions
export(Dictionary) var ship_models
export(Resource) var constants
export(Dictionary) var buildings


func load_data_from_cached(resource: CachedResource):
	for building in resource.building_list:
		buildings[building.kind] = KalaxiaBuilding.new(building)
	constants = resource.constants
	for ship in resource.ship_models:
		ship_models[ship.category] = KalaxiaShipModel.new(ship)
	for index in resource.factions.keys():
		factions[index].update_info_form_dict(resource.factions[index])
