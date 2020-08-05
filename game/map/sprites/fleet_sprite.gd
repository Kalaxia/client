tool
class_name FleetSprite, "res://resources/assets/2d/map/picto_flotte_2.png"
extends Sprite

var faction : int = 0 setget set_faction

const assets = preload("res://resources/assets.tres")


func _ready():
	pass


func set_faction_texture():
	if faction != 0:
		texture = assets.factions[faction].picto.fleet


func set_faction(new_faction):
	faction = new_faction as int
	set_faction_texture()
