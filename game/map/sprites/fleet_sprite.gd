extends Sprite

var faction = 0

const _TEXTURE = {
	0 : preload("res://resources/assets/2d/map/fleet_pin.png"),
	1 : preload("res://resources/assets/2d/map/fleet_pin_faction_1.png"),
	2 : preload("res://resources/assets/2d/map/fleet_pin_faction_2.png"),
	3 : preload("res://resources/assets/2d/map/fleet_pin_faction_3.png"),
}
 


func _ready():
	set_faction_texture()


func set_faction_texture():
	texture = _TEXTURE[faction]
