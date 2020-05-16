extends Node2D

var system = null

func _ready():
	set_position(Vector2(system.coordinates.x * 50, system.coordinates.y * 50))
	init_color()
	pass
	
func init_color():
	$StarLight.set_color(Color(255,255,255))
	if system.player != null:
		print("ok")
		var player = Store.get_game_player(system.player)
		print(player)
		var faction = Store.get_faction(player.faction)
		$StarLight.set_color(Color(faction.color[0], faction.color[1], faction.color[2]))
	
