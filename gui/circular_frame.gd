tool
class_name CircularFrame
extends MarginContainer

export(Color) var color = Color.black setget set_color
export(Color) var background_color = Color.transparent setget set_background_color
export(int) var line_width = 1 setget set_line_width
export(int) var number_of_edges = 32 setget set_number_of_edges
export(bool) var blend = false setget set_blend
export(bool) var advance_blend = false setget set_advance_blend
export(float, 0.0, 1.0) var blend_factor = 0.5 setget set_blend_factor


func _draw():
	var points_1 = PoolVector2Array([])
	var center = rect_size / 2.0
	var colors = PoolColorArray([])
	var mid_color = color.linear_interpolate(background_color, blend_factor)
	for i in range(number_of_edges + 1):
		var angle = float(i) * 2.0 * PI / float(number_of_edges)
		points_1.push_back(Vector2(cos(angle) * rect_size.x / 2.0, sin(angle) * rect_size.y / 2.0) + center)
		colors.push_back(color)
	var points_2 = PoolVector2Array([])
	var colors_2 = PoolColorArray([])
	for i in range(number_of_edges + 1):
		var angle = float(number_of_edges - i) * 2.0 * PI / float(number_of_edges)
		points_2.push_back(Vector2(cos(angle) * (rect_size.x / 2.0 - line_width as float), \
				sin(angle) * (rect_size.y / 2.0 - line_width as float)) + center)
		if blend:
			colors_2.push_back(mid_color if advance_blend else background_color)
		else:
			colors_2.push_back(color)
	points_1.append_array(points_2)
	colors.append_array(colors_2)
	draw_polygon(points_1, colors)
	if advance_blend:
		var points_3 = PoolVector2Array([])
		var colors_3 = PoolColorArray([])
		for i in range(number_of_edges + 1):
			var angle = float(i) * 2.0 * PI / float(number_of_edges)
			points_3.push_back(Vector2(cos(angle) * (rect_size.x / 2.0 - line_width as float - 1.0), \
					sin(angle) * (rect_size.y / 2.0 - line_width as float - 1.0)) + center)
			colors_3.push_back(background_color if blend else mid_color)
		points_2.append_array(points_3)
		colors_2.append_array(colors_3)
		draw_polygon(points_2, colors_2)
		draw_polygon(points_3, PoolColorArray([background_color]))
	else:
		draw_polygon(points_2, PoolColorArray([background_color]))


func set_number_of_edges(new_var):
	if new_var < 4:
		return
	number_of_edges = new_var
	update()


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


func set_advance_blend(blend_new):
	advance_blend = blend_new
	update()


func set_blend_factor(blend_new):
	blend_factor = blend_new
	update()
