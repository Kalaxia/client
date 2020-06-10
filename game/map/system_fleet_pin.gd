extends Control

var faction = null
var is_current_player = false
var color = null

func _ready():
	$Sprite.set_modulate(color)
	if is_current_player:
		$Sprite.set_scale(Vector2(1.5,1.5))
