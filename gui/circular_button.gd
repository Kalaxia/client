tool
extends Control

class_name CircularButton

#todo check how to stop event propagation
#export(bool) var propagate_event = false 
# if true the hover and click events are not consumed and can be propagated

export(float) var angle_start = 0.0 setget set_angle_start
export(float) var angle_end = 0.0 setget set_angle_end
export(float) var radius_out = 1.0 setget set_radius_out
export(float) var radius_in = 0.0 setget set_radius_in

export(StyleBoxFlat) var base_style setget set_base_style
export(StyleBoxFlat) var hover_style setget set_hover_style

export(Texture) var texture setget set_texture
export(Vector2) var texture_size setget set_texture_size

var _hover = false

const _NUMBER_OF_POINT_ARC = 32

signal pressed()

func _ready():
	self.mouse_filter = MOUSE_FILTER_IGNORE # todo see how I can set that by default or prenvent to be chnaged at all
	_update_shape()
	if base_style != null:
		if not base_style.is_connected("changed",self,"_on_changed"):
			base_style.connect("changed",self,"_on_changed")
	if hover_style != null:
		if not hover_style.is_connected("changed",self,"_on_changed"):
			hover_style.connect("changed",self,"_on_changed")
	if texture != null:
		if not texture.is_connected("changed",self,"_on_changed"):
			texture.connect("changed",self,"_on_changed")

func _on_changed():
	update()

func _add_area_2d():
	var area = Area2D.new()
	area.monitorable = false
	area.name = "Area2D"
	area.monitorable = false
	area.visible = true
	add_child(area)

func _add_collision_shape():
	var collision = CollisionPolygon2D.new()
	collision.name = "CollisionPolygon2D"
	collision.visible = false
	$Area2D.add_child(collision)

func _update_shape():
	if not has_node("Area2D"):
		_add_area_2d()
	else:
		$Area2D.disconnect("mouse_entered",self, "_on_mouse_entered")
		$Area2D.disconnect("mouse_exited", self, "_on_mouse_exited")
		$Area2D.disconnect("input_event",self,"_on_input_event")
	if not has_node("Area2D/CollisionPolygon2D"):
		_add_collision_shape()
	$Area2D/CollisionPolygon2D.polygon = _get_array_points()
	var a = $Area2D/CollisionPolygon2D
	$Area2D.connect("input_event",self,"_on_input_event")
	$Area2D.connect("mouse_entered",self, "_on_mouse_entered")
	$Area2D.connect("mouse_exited", self, "_on_mouse_exited")

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_pressed() and event.get_button_index() == BUTTON_LEFT:
		emit_signal("pressed")
		print("pressed")

func update():
	.update()

func _on_mouse_entered():
	_hover = true
	update()

func _on_mouse_exited():
	_hover = false
	update()

func _draw():
	# style setup
	var colors_bg
	var color_border
	var border_width
	var corner_detail = 8
	var shadow_color = Color(0.0, 0.0, 0.0, 0.0)
	var shadow_size = 0
	var shadow_offseet = Vector2(0,0)
	var anti_alaising = true
	var draw_center = true
	var style_active = hover_style if _hover else base_style
	if style_active == null or base_style is StyleBoxEmpty:
		colors_bg = Color(0.5,0.5,0.5) if _hover else  Color(0.7,0.7,0.7)
		color_border = Color(0.0, 0.0, 0.0)
		border_width = [1,1,1,1]
	else:
		colors_bg = style_active.bg_color
		color_border = style_active.border_color
		border_width = [style_active.border_width_left, style_active.border_width_top, style_active.border_width_right, style_active.border_width_bottom]
		corner_detail = style_active.corner_detail
		shadow_color = style_active.shadow_color
		shadow_size = style_active.shadow_size
		shadow_offseet = style_active.shadow_offset
		anti_alaising = style_active.anti_aliasing
		draw_center = style_active.draw_center
	# draw
	var center = rect_size / 2.0
	var points = _get_array_points()
	# draw shadow (todo review)
	if shadow_size > 0:
		var point_shadow = PoolVector2Array()
		for i in range(points.size()):
			var point = (points[i]-center) * (Vector2(1.0, 1.0) + radius_out * shadow_size * Vector2(1.0 / rect_size.x, 1.0 /rect_size.y)/ 2.0)  + shadow_offseet
			point_shadow.push_back(point + center)
		draw_polygon(point_shadow, PoolColorArray([ shadow_color ]), PoolVector2Array(), null, null, anti_alaising)
	# darw inner
	if draw_center:
		draw_polygon(points, PoolColorArray([ colors_bg ]), PoolVector2Array(), null, null, anti_alaising)
	# draw border
	if border_width[0] > 0:
		draw_polygon(_get_left_border(border_width[0],corner_detail), PoolColorArray([color_border]), PoolVector2Array(), null, null, anti_alaising)
	if border_width[2] > 0:
		draw_polygon(_get_right_border(border_width[2],corner_detail), PoolColorArray([color_border]), PoolVector2Array(), null, null, anti_alaising)
	if border_width[1] > 0:
		draw_polygon(_get_outer_arc_border(border_width[1]),PoolColorArray([color_border]), PoolVector2Array(), null, null, anti_alaising)
	if border_width[3] > 0:
		draw_polygon(_get_inner_arc_border(border_width[3]),PoolColorArray([color_border]), PoolVector2Array(), null, null, anti_alaising)
	# draw texture
	if texture == null:
		return
	var middle_angle = deg2rad(angle_start+angle_end) / 2.0
	var position = Vector2(cos(middle_angle),sin(middle_angle)) * (radius_out+radius_in)/2.0 * rect_size /2.0
	var rect_rexture = Rect2(center - texture_size/2.0 + position,texture_size)
	draw_texture_rect(texture,rect_rexture,false)

func _get_array_points():
	var center = rect_size / 2.0
	var points_arc = _get_outer_arc()
	points_arc.append_array(_get_inner_arc())
	return points_arc
	
func _get_outer_arc():
	var center = rect_size / 2.0
	var points_arc = PoolVector2Array()
	for i in range(_NUMBER_OF_POINT_ARC + 1):
		var angle_point = deg2rad(angle_start + i * (angle_end - angle_start) / _NUMBER_OF_POINT_ARC)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius_out * rect_size /2.0)
	return points_arc

func _get_inner_arc():
	var center = rect_size / 2.0
	var points_arc = PoolVector2Array()
	for i in range(_NUMBER_OF_POINT_ARC + 1):
		var angle_point = deg2rad(angle_start + (_NUMBER_OF_POINT_ARC - i) * (angle_end - angle_start) / _NUMBER_OF_POINT_ARC)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius_in * rect_size/2.0)
	return points_arc

func _get_outer_arc_border(width = 1.0, details = _NUMBER_OF_POINT_ARC):
	var center = rect_size / 2.0
	var points_arc = _get_outer_arc()
	for i in range(details + 1):
		var angle_point = deg2rad(angle_start + (details-i) * (angle_end - angle_start) / details)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * (radius_out * rect_size /2.0 - Vector2(1.0,1.0) * width))
	return points_arc

func _get_inner_arc_border(width = 1.0, details = _NUMBER_OF_POINT_ARC):
	var center = rect_size / 2.0
	var points_arc = _get_inner_arc()
	for i in range(details + 1):
		var angle_point = deg2rad(angle_start + (i) * (angle_end - angle_start) / details)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * (radius_in * rect_size /2.0 + Vector2(1.0,1.0) * width))
	return points_arc

func _get_left_border(width = 1.0,details = 8,border_scale = false):
	var center = rect_size / 2.0
	var sign_inner = sign (- angle_start + angle_end)
	var points_arc = PoolVector2Array()
	# TODO revoir les taille des bord
	var angle_diff_outer = float(width) / (rect_size.x* radius_out ) 
	for i in range(details+1):
		var unit_vect_angle = Vector2(cos(deg2rad(angle_start) + sign_inner * i * angle_diff_outer / details), sin(deg2rad(angle_start) + sign_inner*  i * angle_diff_outer / details )) 
		points_arc.push_back(center + unit_vect_angle * radius_out * rect_size/2.0)
	var angle_diff_inner = float(width) / (rect_size.x* radius_in ) if not border_scale else angle_diff_outer
	for i in range(details+1):
		var unit_vect_angle = Vector2(cos(deg2rad(angle_start) + sign_inner * (details-i) * angle_diff_inner / details), sin(deg2rad(angle_start) + sign_inner*  (details-i) * angle_diff_inner / details )) 
		points_arc.push_back(center + unit_vect_angle * radius_in * rect_size/2.0)
	return points_arc

func _get_right_border(width = 1.0,details = 8,border_scale = false):
	var center = rect_size / 2.0
	var sign_inner = sign (angle_start - angle_end)
	var points_arc = PoolVector2Array()
	var angle_diff_outer = float(width) / (rect_size.x* radius_out)
	for i in range(details+1):
		var unit_vect_angle = Vector2(cos(deg2rad(angle_end) + sign_inner * i * angle_diff_outer / details), sin(deg2rad(angle_end) + sign_inner*  i * angle_diff_outer / details )) 
		points_arc.push_back(center + unit_vect_angle * radius_out * rect_size/2.0)
	var angle_diff_inner = float(width) / (rect_size.x* radius_in) if not border_scale else angle_diff_outer
	for i in range(details+1):
		var unit_vect_angle = Vector2(cos(deg2rad(angle_end) + sign_inner * (details-i) * angle_diff_inner / details), sin(deg2rad(angle_end) + sign_inner*  (details-i) * angle_diff_inner / details )) 
		points_arc.push_back(center + unit_vect_angle * radius_in * rect_size/2.0)
	return points_arc

func set_radius_out(new_radius):
	if new_radius < radius_in:
		return
	radius_out = new_radius
	_update_shape()
	update()

func set_radius_in(new_radius):
	if new_radius > radius_out or new_radius < 0.0:
		return
	radius_in = new_radius
	_update_shape()
	update()

func set_angle_end(new_angle):
	angle_end = new_angle
	_update_shape()
	update()

func set_angle_start(new_angle):
	angle_start = new_angle
	_update_shape()
	update()

func set_base_style(style):
	if base_style != null:
		base_style.disconnect("changed",self,"_on_changed")
	base_style = style
	if base_style != null:
		base_style.connect("changed",self,"_on_changed")
	update()

func set_hover_style(style):
	if hover_style != null:
		hover_style.disconnect("changed",self,"_on_changed")
	hover_style = style
	if hover_style != null:
		hover_style.connect("changed",self,"_on_changed")
	update()
	
func set_texture(new_texture):
	if texture != null:
		texture.disconnect("changed",self,"_on_changed")
	texture = new_texture
	if texture != null:
		texture.connect("changed",self,"_on_changed")
	update()

func set_texture_size(new_size):
	if new_size.x < 0.0 or new_size.y < 0.0:
		return
	texture_size = new_size
	update()
