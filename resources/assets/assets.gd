tool
extends Resource
class_name KalaxiaAssets,"res://resources/assets/2d/white_logo.png"

export(Array, Resource) var factions
export(Dictionary) var ship_models
export(Resource) var constants
export(Dictionary) var buildings


func load_data_from_cached(ressource: CachedResource):
	for building in ressource.building_list:
		buildings[building.kind] = KalaxiaBuilding.new(building)
	constants = ressource.constants
	ship_models = ressource.ship_models
	for index in ressource.factions.keys():
		factions[index].load_dict(ressource.factions[index])
