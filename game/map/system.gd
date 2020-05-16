extends Node2D

var system = null

func _ready():
	set_position(Vector2(system.coordinates.x * 50, system.coordinates.y * 50))
	init_color()
	if system.player == Store._state.player.id:
		$StarLight.set_scale(Vector2(2, 10))
	
func init_color():
	$StarLight.set_color(Color(255,255,255))
	if system.player != null:
		var player = Store.get_game_player(system.player)
		var faction = Store.get_faction(player.faction)
		$StarLight.set_color(Color(faction.color[0], faction.color[1], faction.color[2]))
	
