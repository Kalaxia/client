tool
class_name CrownSprite, "res://resources/assets/2d/map/kalankar/crown_bottom.png"
extends Sprite

export(Resource) var faction = null setget set_faction

const assets = preload("res://resources/assets.tres")


func _ready():
	pass


func set_faction_texture():
	if faction != null:
		texture = faction.picto.crown_bottom


func set_faction(new_faction):
	faction = new_faction
	set_faction_texture()
