extends Node2D

const _NUMBER_OF_POINTS = 64

export(float) var inner_radius = 0.98 setget set_inner_radius
export(Color) var color_range = Color(1.0, 1.0, 1.0, 0.39) setget set_color_range


func _ready():
	pass


func _draw():
	var points = PoolVector2Array()
	for i in range (_NUMBER_OF_POINTS +1):
		var angle = i * 2 * PI / _NUMBER_OF_POINTS
		var vector = Vector2(cos(angle), sin(angle))
		points.push_back(vector)
	for i in range (_NUMBER_OF_POINTS +1):
		var angle = (_NUMBER_OF_POINTS - i) * 2 * PI / _NUMBER_OF_POINTS
		var vector = Vector2(cos(angle), sin(angle)) * inner_radius
		points.push_back(vector)
	draw_polygon(points, PoolColorArray([ color_range ]), PoolVector2Array(), null, null, false)


func set_inner_radius(new_radius):
	if new_radius < 0 or new_radius > 1:
		return
	inner_radius = new_radius
	update()


func set_color_range(new_color):
	color_range = new_color
	update()
