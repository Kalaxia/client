extends Control

var faction = null
var is_current_player = false
var color = null

func _ready():
	$Sprite.set_modulate(Color(color[0], color[1], color[2]))
	if is_current_player:
		$Sprite.set_scale(Vector2(1.5,1.5))
