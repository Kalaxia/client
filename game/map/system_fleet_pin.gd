extends Node2D

var color = null

func _ready():
	$Sprite.set_modulate(Color(color[0], color[1], color[2]))
