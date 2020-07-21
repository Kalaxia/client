class_name FleetSprite, "res://resources/assets/2d/map/picto_flotte_2.png"
extends Sprite

var faction = 0 setget set_faction


func _ready():
	set_faction_texture()


func set_faction_texture():
	if faction != 0:
		texture = Utils.FLEET_TEXTURE[faction as int]


func set_faction(new_faction):
	faction = new_faction as int
	set_faction_texture()
