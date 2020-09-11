tool
class_name CircularButton, "res://resources/editor/custom_circular_button.svg"
extends CustomShapeButton

const _NUMBER_OF_POINT_ARC = 32

export(float) var angle_start = 0.0 setget set_angle_start
export(float) var angle_end = 0.0 setget set_angle_end
export(float) var radius_out = 1.0 setget set_radius_out
export(float) var radius_in = 0.0 setget set_radius_in
export(bool) var does_border_scale = false setget set_does_border_scale 
# determine whether the border scale with the radius.
# With small border it looks better if set as false. 
# With bigger order it look better is this is true

export(StyleBoxFlat) var base_style setget set_base_style
export(StyleBoxFlat) var hover_style setget set_hover_style
export(StyleBoxFlat) var selected_style setget set_selected_style
export(StyleBoxFlat) var focus_style setget set_focus_style

export(Texture) var texture setget set_texture
export(Vector2) var texture_size setget set_texture_size


func _ready():
	# we ned to do this verifiaction because of the this is a tool and the editor can call _ready multiple time
	if base_style != null and not base_style.is_connected("changed", self, "_on_changed"):
		base_style.connect("changed", self, "_on_changed")
	if selected_style != null and not selected_style.is_connected("changed", self, "_on_changed"):
		selected_style.connect("changed", self, "_on_changed")
	if hover_style != null and not hover_style.is_connected("changed", self, "_on_changed"):
		hover_style.connect("changed", self, "_on_changed")
	if focus_style != null and not focus_style.is_connected("changed", self, "_on_changed"):
		focus_style.connect("changed", self, "_on_changed")
	if texture != null and not texture.is_connected("changed", self, "_on_changed"):
		texture.connect("changed", self, "_on_changed")


func _draw():
	if rect_size.x == 0.0 or rect_size.y == 0.0:
		return
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
	var style_active
	if selected:
		var theme_style = get_stylebox("selected_style", "CircularButton")
		style_active = selected_style if selected_style != null else theme_style
	elif _hover:
		var theme_style = get_stylebox("hover_style", "CircularButton")
		style_active = hover_style if hover_style != null else theme_style
	else:
		var theme_style = get_stylebox("base_style", "CircularButton")
		style_active = base_style if base_style != null else theme_style
	if style_active == null or not style_active is StyleBoxFlat:
		colors_bg = Color(0.5,0.5,0.5) if (_hover or selected) else  Color(0.7,0.7,0.7)
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
	# draw shadow (todo improve)
	if shadow_size > 0:
		var point_shadow = _get_shadow_poly(points, shadow_size, shadow_offseet, center)
		draw_polygon(point_shadow, PoolColorArray([ shadow_color ]), PoolVector2Array(), null, null, anti_alaising)
	# darw inner
	if draw_center:
		draw_polygon(points, PoolColorArray([ colors_bg ]), PoolVector2Array(), null, null, anti_alaising)
	# draw border
	if border_width[0] > 0:
		draw_polygon(_get_left_border(border_width[0], corner_detail, does_border_scale), PoolColorArray([color_border]), PoolVector2Array(), null, null, anti_alaising)
	if border_width[2] > 0:
		draw_polygon(_get_right_border(border_width[2], corner_detail, does_border_scale), PoolColorArray([color_border]), PoolVector2Array(), null, null, anti_alaising)
	if border_width[1] > 0:
		draw_polygon(_get_outer_arc_border(border_width[1]), PoolColorArray([color_border]), PoolVector2Array(), null, null, anti_alaising)
	if border_width[3] > 0:
		draw_polygon(_get_inner_arc_border(border_width[3]), PoolColorArray([color_border]), PoolVector2Array(), null, null, anti_alaising)
	# draw texture
	if texture != null:
		_draw_texture()
	if has_focus():
		_draw_focus()


func _draw_focus():
	var theme_style =  get_stylebox("focus_style", "CircularButton")
	var style = focus_style if focus_style != null else theme_style
	if style == null:
		return
	var points = _get_array_points()
	if style.draw_center:
		draw_polygon(points, PoolColorArray([ style.bg_color ]), PoolVector2Array(), null, null, style.anti_aliasing)
	# draw border
	if style.border_width_left > 0:
		draw_polygon(_get_left_border(style.border_width_left, style.corner_detail, does_border_scale), PoolColorArray([style.border_color]), PoolVector2Array(), null, null, style.anti_aliasing)
	if style.border_width_right > 0:
		draw_polygon(_get_right_border(style.border_width_right, style.corner_detail, does_border_scale), PoolColorArray([style.border_color]), PoolVector2Array(), null, null, style.anti_aliasing)
	if style.border_width_top > 0:
		draw_polygon(_get_outer_arc_border(style.border_width_top),PoolColorArray([style.border_color]), PoolVector2Array(), null, null, style.anti_aliasing)
	if style.border_width_bottom > 0:
		draw_polygon(_get_inner_arc_border(style.border_width_bottom),PoolColorArray([style.border_color]), PoolVector2Array(), null, null, style.anti_aliasing)


func _is_inside(position):
	var rel_to_center = position -  get_rect().size / 2.0 
	if rect_size.x == 0.0 or rect_size.y == 0.0:
		return false
	# this is the vector corrected with the aspect ration of the box size
	# rect_size.tangent().abs() juste swap the coordinates (as rect_size has both component > 0)
	var vector_to_compute_angle = rel_to_center * (get_rect().size).tangent().abs().normalized()
	# we need to take -angle because when we convert deg to rad we chnage the orientation 
	# degrees grows in the anti trigo orientation (clockwise)
	var angle = fposmod(-vector_to_compute_angle.angle_to(Vector2.RIGHT), 2.0 * PI)
	var angle_1 = fposmod(deg2rad(min(angle_start, angle_end)), 2.0 * PI)
	var angle_2 = fposmod(deg2rad(max(angle_start, angle_end)), 2.0 * PI)
	var radius = rel_to_center.length() / (get_rect().size * get_vector_radial(angle) / 2.0).length()
	# as we take the mod of the angle angle_1 can be greater angle_2
	# in that case we need to check that angle is not between [angle_2, angle_1]
	return radius <= radius_out and radius >= radius_in and ((angle_1 <= angle_2 and angle >= angle_1 and angle <= angle_2) or (angle_1 > angle_2 and not (angle >= angle_2 and angle <= angle_1) ) )


func update():
	.update()


static func get_vector_radial(angle, radius = 1.0):
	return  Vector2(cos(angle), sin(angle)) * radius

func set_radius_out(new_radius):
	if new_radius < radius_in:
		return
	radius_out = new_radius
	update()


func set_radius_in(new_radius):
	if new_radius > radius_out or new_radius < 0.0:
		return
	radius_in = new_radius
	update()


func set_angle_end(new_angle):
	if new_angle >= angle_start + 360.0 or new_angle <= angle_start - 360.0:
		return
	angle_end = new_angle
	update()


func set_angle_start(new_angle):
	if new_angle >= angle_end + 360.0 or new_angle <= angle_end - 360.0:
		return
	angle_start = new_angle
	update()


func set_base_style(style):
	if base_style != null:
		base_style.disconnect("changed", self, "_on_changed")
	base_style = style
	if base_style != null:
		base_style.connect("changed", self, "_on_changed")
	update()


func set_hover_style(style):
	if hover_style != null:
		hover_style.disconnect("changed", self, "_on_changed")
	hover_style = style
	if hover_style != null:
		hover_style.connect("changed", self, "_on_changed")
	update()


func set_texture(new_texture):
	if texture != null:
		texture.disconnect("changed", self, "_on_changed")
	texture = new_texture
	if texture != null:
		texture.connect("changed", self, "_on_changed")
	update()


func set_selected_style(style):
	if selected_style != null:
		selected_style.disconnect("changed", self, "_on_changed")
	selected_style = style
	if selected_style != null:
		selected_style.connect("changed", self, "_on_changed")
	update()


func set_focus_style(style):
	if focus_style != null:
		focus_style.disconnect("changed", self, "_on_changed")
	focus_style = style
	if focus_style != null:
		focus_style.connect("changed", self, "_on_changed")
	update()


func set_texture_size(new_size):
	if new_size.x < 0.0 or new_size.y < 0.0:
		return
	texture_size = new_size
	update()


func set_does_border_scale(new_bool):
	does_border_scale = new_bool
	update()


func _draw_texture():
	var center = rect_size / 2.0
	var middle_angle = deg2rad(angle_start + angle_end) / 2.0
	var position = get_vector_radial(middle_angle, (radius_out + radius_in) / 2.0 * rect_size / 2.0) 
	var rect_rexture = Rect2(center - texture_size / 2.0 + position,texture_size)
	draw_texture_rect(texture,rect_rexture,false)


func _get_shadow_poly(points, shadow_size, shadow_offseet, center = rect_size / 2.0):
	var point_shadow = PoolVector2Array()
	for i in range(points.size()):
		var point = (points[i] - center) * (Vector2(1.0, 1.0) + radius_out * shadow_size * Vector2(1.0 / rect_size.x, 1.0 /rect_size.y)/ 2.0)  + shadow_offseet
		point_shadow.push_back(point + center)
	return point_shadow


func _get_array_points():
	var points_arc = _get_outer_arc()
	points_arc.append_array(_get_inner_arc())
	return points_arc


func _get_outer_arc():
	var center = rect_size / 2.0
	var points_arc = PoolVector2Array()
	for i in range(_NUMBER_OF_POINT_ARC + 1):
		var angle_point = deg2rad(angle_start + i * (angle_end - angle_start) / _NUMBER_OF_POINT_ARC)
		points_arc.push_back(center + get_vector_radial(angle_point, radius_out * rect_size / 2.0))
	return points_arc


func _get_inner_arc():
	var center = rect_size / 2.0
	var points_arc = PoolVector2Array()
	for i in range(_NUMBER_OF_POINT_ARC + 1):
		var angle_point = deg2rad(angle_start + (_NUMBER_OF_POINT_ARC - i) * (angle_end - angle_start) / _NUMBER_OF_POINT_ARC)
		points_arc.push_back(center + get_vector_radial(angle_point, radius_in * rect_size / 2.0))
	return points_arc


func _get_outer_arc_border(width = 1.0, details = _NUMBER_OF_POINT_ARC):
	var center = rect_size / 2.0
	var points_arc = _get_outer_arc()
	for i in range(details + 1):
		var angle_point = deg2rad(angle_start + (details-i) * (angle_end - angle_start) / details)
		points_arc.push_back(center + get_vector_radial(angle_point, radius_out * rect_size / 2.0 - Vector2(1.0, 1.0) * width))
	return points_arc


func _get_inner_arc_border(width = 1.0, details = _NUMBER_OF_POINT_ARC):
	var center = rect_size / 2.0
	var points_arc = _get_inner_arc()
	for i in range(details + 1):
		var angle_point = deg2rad(angle_start + (i) * (angle_end - angle_start) / details)
		points_arc.push_back(center + get_vector_radial(angle_point, radius_in * rect_size / 2.0 + Vector2(1.0, 1.0) * width))
	return points_arc


func _get_left_border(width = 1.0, details = 8, border_scale = false):
	var center = rect_size / 2.0
	var sign_inner = sign (- angle_start + angle_end) # direction of angle inside the shape
	var points_arc = PoolVector2Array()
	var angle_diff_outer = float(width) * 2.0 / (rect_size.x * radius_out) # this is the angle to generante a border of size width on the  outer edge
	for i in range(details+1): # arc outter
		var unit_vect_angle = get_vector_radial(deg2rad(angle_start) + sign_inner * i * angle_diff_outer / details)
		points_arc.push_back(center + unit_vect_angle * radius_out * rect_size / 2.0)
	var angle_diff_inner
	if not border_scale:  
		if radius_in != 0.0:
			angle_diff_inner = float(width) * 2.0 / (rect_size.x * radius_in) 
		else:
			angle_diff_inner = 0.0
	else:
		 angle_diff_inner = angle_diff_outer # if we scale the border then the angle_diff should be the same
		# we choose to take the outer one, meaning the border will nerver be greater than width
	for i in range(details+1): # arc inner
		var unit_vect_angle = get_vector_radial(deg2rad(angle_start) + sign_inner * (details-i) * angle_diff_inner / details)
		points_arc.push_back(center + unit_vect_angle * radius_in * rect_size / 2.0)
	return points_arc


func _get_right_border(width = 1.0, details = 8, border_scale = false):
	var center = rect_size / 2.0
	var sign_inner = sign (angle_start - angle_end)
	var points_arc = PoolVector2Array()
	var angle_diff_outer = float(width) * 2.0 / (rect_size.x * radius_out) # see _get_left_border
	for i in range(details+1): # arc outter
		var unit_vect_angle = get_vector_radial(deg2rad(angle_end) + sign_inner * i * angle_diff_outer / details)  
		points_arc.push_back(center + unit_vect_angle * radius_out * rect_size / 2.0)
	var angle_diff_inner
	if not border_scale:
		if radius_in != 0.0:
			angle_diff_inner = float(width) * 2.0 / (rect_size.x * radius_in)
		else:
			angle_diff_inner = 0.0
	else:
		 angle_diff_inner = angle_diff_outer # see _get_left_border
	for i in range(details + 1): # arc inner
		var unit_vect_angle = get_vector_radial(deg2rad(angle_end) + sign_inner * (details-i) * angle_diff_inner / details)
		points_arc.push_back(center + unit_vect_angle * radius_in * rect_size/2.0)
	return points_arc


func _on_changed():
	update()
