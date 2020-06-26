extends Sprite

var faction = 0

const _TEXTURE = {
	1 : preload("res://resources/assets/2d/map/kalankar/Picto_flotte_couronne-01.png"),
	2 : preload("res://resources/assets/2d/map/valkar/Picto_flotte_couronne-01.png"),
	3 : preload("res://resources/assets/2d/map/adranite/Picto_flotte_couronne-01.png"),
}
 


func _ready():
	set_faction_texture()


func set_faction_texture():
	if faction != 0:
		texture = _TEXTURE[faction as int]
