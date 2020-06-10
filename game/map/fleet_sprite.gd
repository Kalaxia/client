extends Sprite

var faction = 0

const _TEXTURE_FACTION_0 = preload("res://resources/assets/2d/map/fleet_pin.png")
const _TEXTURE_FACTION_1 = preload("res://resources/assets/2d/map/fleet_pin_faction_1.png")
const _TEXTURE_FACTION_2 = preload("res://resources/assets/2d/map/fleet_pin_faction_2.png")
const _TEXTURE_FACTION_3 = preload("res://resources/assets/2d/map/fleet_pin_faction_3.png")


func _ready():
	set_faction_texture()


func set_faction_texture():
	match faction as int:
		1:
			texture = _TEXTURE_FACTION_1
		2:
			texture = _TEXTURE_FACTION_2
		3:
			texture = _TEXTURE_FACTION_3
		_:
			texture = _TEXTURE_FACTION_0
