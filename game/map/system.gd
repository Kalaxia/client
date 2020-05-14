extends Node2D

var system = null

func _ready():
	set_position(Vector2(system.coordinates.x * 50, system.coordinates.y * 50))
	init_color()
	pass
	
func init_color():
	$StarLight.set_color(Color(255,255,255))
	if system.player != null:
		$StarLight.set_color(Color(255,0,0))
	
