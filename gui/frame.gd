tool
class_name Frame
extends MarginContainer

export(Color) var color = Color.black setget set_color
export(Color) var background_color = Color.transparent setget set_background_color
export(int) var line_width = 1 setget set_line_width
export(bool) var blend = false setget set_blend


func _ready():
	pass


func _draw():
	var colors_array = PoolColorArray([color, color, background_color, background_color]) \
			if blend else PoolColorArray([color])
	var points_top = PoolVector2Array([
		Vector2.ZERO,
		Vector2(rect_size.x,0),
		Vector2(rect_size.x - line_width, line_width),
		Vector2(line_width, line_width)
	])
	draw_polygon(points_top, colors_array)
	var points_left = PoolVector2Array([
		Vector2(rect_size.x,0),
		Vector2(rect_size.x, rect_size.y),
		Vector2(rect_size.x - line_width, rect_size.y - line_width),
		Vector2(rect_size.x - line_width, line_width)
	])
	draw_polygon(points_left, colors_array)
	var points_bottom = PoolVector2Array([
		Vector2(0, rect_size.y),
		Vector2(rect_size.x, rect_size.y),
		Vector2(rect_size.x - line_width, rect_size.y - line_width),
		Vector2(line_width, rect_size.y - line_width)
	])
	draw_polygon(points_bottom, colors_array)
	var points_right = PoolVector2Array([
		Vector2(0 ,0),
		Vector2(0, rect_size.y),
		Vector2(line_width, rect_size.y - line_width),
		Vector2(line_width, line_width)
	])
	draw_polygon(points_right, colors_array)
	var points_center = PoolVector2Array([
		Vector2(line_width, line_width),
		Vector2(line_width, rect_size.y - line_width),
		Vector2(rect_size.x - line_width, rect_size.y - line_width),
		Vector2(rect_size.x - line_width, line_width),
	])
	draw_polygon(points_center, PoolColorArray([ background_color ]))


func set_line_width(width):
	if width < 1:
		return
	line_width = width
	update()


func set_color(new_color):
	color = new_color
	update()


func set_background_color(new_color):
	background_color = new_color
	update()


func set_blend(blend_new):
	blend = blend_new
	update()
