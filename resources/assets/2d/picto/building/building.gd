tool
extends BuildingModelRemote
class_name KalaxiaBuilding

const RESOURCE_NAME  = {
	"" : "area.png",
	"mine" : "mine.svg",
	"portal" : "portal.svg",
	"shipyard" : "shipyard_64px.png", 
}

export(Texture) var texture


func _init(dict = null).(dict):
	pass


func load_dict(dict):
	.load_dict(dict)
	texture = load("res://resources/assets/2d/picto/building/" + RESOURCE_NAME[kind])


func _get_dict_property_list():
	return ._get_dict_property_list()
