extends TextureRect

export(String) var building_type = null setget set_building_type
export(Color, RGB) var faction_color = Color(1.0, 1.0, 1.0) setget set_faction_color


func _ready():
	_updates_elements()


func set_building_type(new_type):
	building_type = new_type
	_updates_elements()


func set_faction_color(new_color):
	faction_color = new_color
	_updates_color()


func _updates_elements():
	_update_texture()
	_updates_color()


func _update_texture():
	texture = Utils.TEXTURE_BUILDING[building_type.kind if building_type != null else ""]


func _updates_color():
	modulate = faction_color if building_type != null and building_type.status == "operational" else Color(1.0, 1.0, 1.0)
