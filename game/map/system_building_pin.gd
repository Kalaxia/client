extends TextureRect

export(String) var building_type = "" setget set_building_type


func _ready():
	_updates_elements()


func set_building_type(new_type):
	if not Utils.BUILDING_LIST.has(new_type):
		return
	building_type = new_type
	_updates_elements()


func _updates_elements():
	texture = Utils.TEXTURE_BUILDING[building_type]
