tool
extends Sprite

export var faction : int setget set_faction

const assets = preload("res://resources/assets.tres")

func _ready():
	pass


func set_faction(p_faction : int) -> void:
	faction = p_faction
	texture = assets.factions[faction].picto.crown_bottom
