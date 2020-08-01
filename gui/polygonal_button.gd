tool
class_name PolygonalButton, "res://resources/editor/polygonal_button.svg"
extends CustomShapeButton

export(StyleBoxFlat) var base_style setget set_base_style
export(StyleBoxFlat) var hover_style setget set_hover_style
export(StyleBoxFlat) var selected_style setget set_selected_style

export(Texture) var texture setget set_texture
export(Vector2) var texture_size setget set_texture_size

var polygon: Polygon = null setget set_polygon


func _ready():
	._ready()
	if polygon != null:
		polygon.connect("changed", self, "_on_changed")
	if base_style != null and not base_style.is_connected("changed",self,"_on_changed"):
		base_style.connect("changed",self,"_on_changed")
	if selected_style != null and not selected_style.is_connected("changed",self,"_on_changed"):
		selected_style.connect("changed",self,"_on_changed")
	if hover_style != null and not hover_style.is_connected("changed",self,"_on_changed"):
		hover_style.connect("changed",self,"_on_changed")
	if texture != null and not texture.is_connected("changed",self,"_on_changed"):
		texture.connect("changed",self,"_on_changed")


func _draw():
	# todo add theme 
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
		style_active = selected_style
	elif _hover:
		style_active = hover_style
	else:
		style_active = base_style
	if style_active == null or base_style is StyleBoxEmpty:
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
	var points = polygon.points
	# draw shadow (todo improve)
	if shadow_size > 0:
		var point_shadow = polygon.get_shadow_points(shadow_size, shadow_offseet)
		draw_polygon(point_shadow, PoolColorArray([ shadow_color ]), PoolVector2Array(), null, null, anti_alaising)
	# darw inner
	if draw_center:
		draw_polygon(points, PoolColorArray([ colors_bg ]), PoolVector2Array(), null, null, anti_alaising)
	# draw border
	for i in range(points.size()):
		if border_width[i % 4] > 0:
			# todo add way to override border_width to add more egdes
			draw_polygon(polygon.get_border_of_poly(i ,border_width[i % 4]), PoolColorArray([color_border]), PoolVector2Array(), null, null, anti_alaising)
	# draw texture
	if texture != null:
		_draw_texture()
	# add foccus
	# add text


func _draw_texture():
	var center = polygon.get_center_of_mass()
	var rect_rexture = Rect2(center - texture_size / 2.0, texture_size)
	draw_texture_rect(texture,rect_rexture,false)


func _on_changed():
	update()


func _is_inside(position):
	return polygon.is_inside(position)


func set_polygon(new_polygon):
	if new_polygon == null or not new_polygon.is_valid():
		return
	if polygon != null:
		polygon.disconnect("changed", self, "_on_changed")
	polygon = new_polygon
	polygon.connect("changed", self, "_on_changed")
	_on_changed()


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


func set_selected_style(style):
	if selected_style != null:
		selected_style.disconnect("changed",self,"_on_changed")
	selected_style = style
	if selected_style != null:
		selected_style.connect("changed",self,"_on_changed")
	update()


func set_texture_size(new_size):
	if new_size.x < 0.0 or new_size.y < 0.0:
		return
	texture_size = new_size
	update()
