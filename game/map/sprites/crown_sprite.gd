tool
class_name CrownSprite, "res://resources/assets/2d/map/kalankar/crown_bottom.png"
extends Sprite

export var faction : int = 0 setget set_faction

const assets = preload("res://resources/assets.tres")


func _ready():
	pass


func set_faction_texture():
	if faction != 0:
		texture = assets.factions[faction].picto.crown_bottom


func set_faction(new_faction):
	faction = new_faction as int
	set_faction_texture()
