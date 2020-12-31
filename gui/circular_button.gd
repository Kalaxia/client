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
	for s in [base_style, selected_style, hover_style, focus_style, texture]:
		if s != null:
			Utils.unique_external_connect(s, "changed", self, "_on_changed")


func _draw():
	if rect_size.x == 0.0 or rect_size.y == 0.0:
		return
	# style setup
	var bg_color
	var border_color
	var border_width
	var corner_detail = 8
	var shadow_color = Color(0.0, 0.0, 0.0, 0.0)
	var shadow_size = 0
	var shadow_offseet = Vector2(0,0)
	var anti_aliasing = true
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
		bg_color = Color(0.5,0.5,0.5) if (_hover or selected) else  Color(0.7,0.7,0.7)
		border_color = Color(0.0, 0.0, 0.0)
		border_width = [1,1,1,1]
	else:
		bg_color = style_active.bg_color
		border_color = style_active.border_color
		border_width = [style_active.border_width_left, style_active.border_width_top, style_active.border_width_right, style_active.border_width_bottom]
		corner_detail = style_active.corner_detail
		shadow_color = style_active.shadow_color
		shadow_size = style_active.shadow_size
		shadow_offseet = style_active.shadow_offset
		anti_aliasing = style_active.anti_aliasing
		draw_center = style_active.draw_center
	# draw
	var center = rect_size / 2.0
	var points = _get_array_points()
	# draw shadow (todo improve)
	if shadow_size > 0:
		_draw_polygon(shadow_color, anti_aliasing, _get_shadow_poly(points, shadow_size, shadow_offseet, center))
	# darw inner
	if draw_center:
		_draw_polygon(bg_color, anti_aliasing, points)
	# draw border
	if border_width[0] > 0:
		_draw_polygon(border_color, anti_aliasing, _get_border(true, border_width[0], corner_detail, does_border_scale))
	if border_width[2] > 0:
		_draw_polygon(border_color, anti_aliasing, _get_border(false, border_width[2], corner_detail, does_border_scale))
	if border_width[1] > 0:
		_draw_polygon(border_color, anti_aliasing, _get_arc("outer", true, border_width[1]))
	if border_width[3] > 0:
		_draw_polygon(border_color, anti_aliasing, _get_arc("inner", true, border_width[3]))
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
		_draw_polygon(style.bg_color, style.anti_aliasing, points)
	# draw border
	if style.border_width_left > 0:
		_draw_polygon(style.border_color, style.anti_aliasing, _get_border(true, style.border_width_left, style.corner_detail, does_border_scale))
	if style.border_width_right > 0:
		_draw_polygon(style.border_color, style.anti_aliasing, _get_border(false, style.border_width_right, style.corner_detail, does_border_scale))
	if style.border_width_top > 0:
		_draw_polygon(style.border_color, style.anti_aliasing, _get_arc("outer", true, style.border_width_top))
	if style.border_width_bottom > 0:
		_draw_polygon(style.border_color, style.anti_aliasing, _get_arc("inner", true, style.border_width_bottom))


func _draw_polygon(color, anti_aliasing, points):
	draw_polygon(points, PoolColorArray([color]), PoolVector2Array(), null, null, anti_aliasing)


func _is_inside(position):
	var rel_to_center = position - _get_center()
	if rect_size.x == 0.0 or rect_size.y == 0.0:
		return false
	# this is the vector corrected with the aspect ration of the box size
	# rect_size.tangent().abs() juste swap the coordinates (as rect_size has both component > 0)
	var vector_to_compute_angle = rel_to_center * (get_rect().size).tangent().abs().normalized()
	# we need to take -angle because when we convert deg to rad we chnage the orientation 
	# degrees grows in the anti trigo orientation (clockwise)
	var full_angle = 2.0 * PI
	var angle = fposmod(-vector_to_compute_angle.angle_to(Vector2.RIGHT), full_angle)
	var angle_1 = fposmod(deg2rad(min(angle_start, angle_end)), full_angle)
	var angle_2 = fposmod(deg2rad(max(angle_start, angle_end)), full_angle)
	var radius = rel_to_center.length() / (_get_center() * get_vector_radial(angle)).length()
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
	var center = _get_center()
	var middle_angle = deg2rad(angle_start + angle_end) / 2.0
	var position = get_vector_radial(middle_angle, (radius_out + radius_in) / 2.0 * center) 
	var rect_rexture = Rect2(center - texture_size / 2.0 + position,texture_size)
	draw_texture_rect(texture,rect_rexture,false)


func _get_shadow_poly(points, shadow_size, shadow_offseet, center = _get_center()):
	var point_shadow = PoolVector2Array()
	for i in range(points.size()):
		var point = (points[i] - center) * (Vector2(1.0, 1.0) + radius_out * shadow_size * Vector2(1.0 / rect_size.x, 1.0 /rect_size.y)/ 2.0)  + shadow_offseet
		point_shadow.push_back(point + center)
	return point_shadow


func _get_array_points():
	var points_arc = _get_arc("outer")
	points_arc.append_array(_get_arc("inner"))
	return points_arc


func _get_center():
	return rect_size / 2.0


func _get_arc(is_outer, is_border = false, width = 1.0, details = _NUMBER_OF_POINT_ARC):
	var center = _get_center()
	var points_arc = _get_arc(is_outer, false, 0) if is_border else PoolVector2Array()
	var radius = radius_out if is_outer else radius_in
	for i in range(details + 1):
		var coeff = i if (not is_border and is_outer) or (is_border and not is_outer) else (details - i)
		var angle_point = deg2rad(angle_start + coeff * (angle_end - angle_start) / details)
		points_arc.push_back(center + get_vector_radial(angle_point, radius * center - Vector2(1.0, 1.0) * width))
	return points_arc


func _get_border(is_left, width = 1.0, details = 8, border_scale = false):
	var center = _get_center()
	var angle = angle_start if is_left else angle_end
	var sign_coeff = -1 if is_left else 1
	# direction of angle inside the shape
	var sign_inner = sign (sign_coeff * angle_start - sign_coeff * angle_end) 
	var points_arc = PoolVector2Array()
	var angle_diff_outer = float(width) * 2.0 / (rect_size.x * radius_out) # this is the angle to generante a border of size width on the  outer edge
	for i in range(details + 1): # arc outter
		var unit_vect_angle = get_vector_radial(deg2rad(angle) + sign_inner * i * angle_diff_outer / details)
		points_arc.push_back(center + unit_vect_angle * radius_out * center)
	# if we scale the border then the angle_diff should be the same
	# we choose to take the outer one, meaning the border will nerver be greater than width
	var angle_diff_inner = angle_diff_outer if border_scale else 0.0 if radius_in == 0.0 else float(width) * 2.0 / (rect_size.x * radius_in)
	
	for i in range(details + 1): # arc inner
		var unit_vect_angle = get_vector_radial(deg2rad(angle) + sign_inner * (details-i) * angle_diff_inner / details)
		points_arc.push_back(center + unit_vect_angle * radius_in * center)
	return points_arc


func _on_changed():
	update()
