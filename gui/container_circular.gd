tool
class_name CircularContainer, "res://resources/editor/circular_container.svg"
extends Container

enum ANCHOR_POSITION {
	TOP_LEFT,
	TOP,
	TOP_RIGHT,
	LEFT,
	CENTER,
	RIGTH,
	BOTTOM_LEFT,
	BOTTOM,
	BOTTOM_RIGHT,
}

export(float) var angle_start_offset = 0.0 setget set_angle_start_offset
export(float) var angle_end_offset = 0.0 setget set_angle_end_offset
export(float) var radius_ratio = 1.0 setget set_radius_ratio
# determine the radius_inner of circular button. In the case of the rect_size of the wanted inner_radius

export(ANCHOR_POSITION) var anchor_position = ANCHOR_POSITION.TOP_LEFT setget set_anchor_position

export(bool) var aspect_ratio_force = true setget set_aspect_ratio_force # force the aspect ration to conserve the button to be circular and not eliptical
export(bool) var clip_center_node = false setget set_clip_center_node 
# put the center node on the border. This can be useful if the center node only show part of the element
# has no effect if the anchot position is centered

var _warning_string = "" # for the editor warning system, has no effect outside the editor


func _ready():
	pass


func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		sort_children()


func sort_children():
	_reset_warning()
	# children_check
	if get_child_count() == 0:
		return
	var number_of_circular_button = 0
	var number_of_centered_node = 0
	for node in get_children():
		if not node is CircularButton and node.visible:
			node.raise() # we put the node at the end for simplicity
			number_of_centered_node += 1
		elif node.visible:
			number_of_circular_button += 1
	if number_of_centered_node > 1:
		_warn("There is more than one non circular button node.")
	elif number_of_centered_node == 0:
		_warn("There is less than one non circular button node.")
	var center_node = get_child(get_child_count() - 1 ) # this is the node where we put the circulars button arround
	if not center_node is Control:
		_warn("The lowest center node is not a Control, aborting...")
		return
	# size set up
	var rect_size_element_use # variable that we use as the rect_size but as a single valu
	var aspect_ratio = Vector2(1.0, 1.0) # this is used in order to scale the size of the button in the case we are on an edge (not center not in corner)
	match anchor_position:
		ANCHOR_POSITION.BOTTOM, ANCHOR_POSITION.TOP: 
			# In that case the container x should be the diameter and y the radius.
			# If we do not clip there is extra space we need to consider in the container, the aspect ratio should be corrected accordingly
			var y_extra = 0.0 if clip_center_node else center_node.rect_size.y / 2.0
			var y_comp =  max(rect_size.x, 1.0) / 2.0 + y_extra
			if aspect_ratio_force:
				rect_size = Vector2(max(rect_size.x, 1.0), y_comp)
			aspect_ratio.y = 0.5 + y_extra / rect_size.x
			rect_size_element_use = rect_size.y # the element representing the radius is in the y direction (this incliude the extra space)
		ANCHOR_POSITION.LEFT, ANCHOR_POSITION.RIGTH: 
			# in that case the container y should be the diameter and x the radius
			var x_extra = 0.0 if clip_center_node else center_node.rect_size.x / 2.0
			var x_comp =  max(rect_size.y, 1.0) / 2.0 + x_extra
			if aspect_ratio_force:
				rect_size = Vector2(x_comp,max(rect_size.y, 1.0))
			aspect_ratio.x = 0.5 + x_extra/rect_size.y
			rect_size_element_use = rect_size.x # the element representing the radius is in the x direction (this incliude the extra space)
		_ :
			# in that case , x and y are the diameters (center) or the radius (corner), hence the aspect ratio is (1,1)
			if aspect_ratio_force:
				rect_size = Vector2(max(rect_size.x, rect_size.y), max(rect_size.x, rect_size.y))
			rect_size_element_use = min(rect_size.x, rect_size.y) # we can take any of the two component, we choose to take the smaller one to avoir overflow
	rect_size_element_use = max(rect_size_element_use, 1.0)
	# position of center node
	for i in range (get_child_count() - number_of_centered_node,get_child_count()):
		var child_center = get_child(i)
		if child_center is Control and child_center.visible:
			match anchor_position:
				ANCHOR_POSITION.TOP_LEFT:
					child_center.set_anchors_and_margins_preset(Control.PRESET_TOP_LEFT)
				ANCHOR_POSITION.TOP:
					child_center.set_anchors_and_margins_preset(Control.PRESET_CENTER_TOP)
				ANCHOR_POSITION.TOP_RIGHT:
					child_center.set_anchors_and_margins_preset(Control.PRESET_TOP_RIGHT)
				ANCHOR_POSITION.LEFT:
					child_center.set_anchors_and_margins_preset(Control.PRESET_CENTER_LEFT)
				ANCHOR_POSITION.CENTER:
					child_center.set_anchors_and_margins_preset(Control.PRESET_CENTER)
				ANCHOR_POSITION.RIGTH:
					child_center.set_anchors_and_margins_preset(Control.PRESET_CENTER_RIGHT)
				ANCHOR_POSITION.BOTTOM_LEFT:
					child_center.set_anchors_and_margins_preset(Control.PRESET_BOTTOM_LEFT)
				ANCHOR_POSITION.BOTTOM:
					child_center.set_anchors_and_margins_preset(Control.PRESET_CENTER_BOTTOM)
				ANCHOR_POSITION.BOTTOM_RIGHT:
					child_center.set_anchors_and_margins_preset(Control.PRESET_BOTTOM_RIGHT)
			# set grow direction
			# todo review
			child_center.grow_horizontal = Control.GROW_DIRECTION_BOTH
			child_center.grow_vertical = Control.GROW_DIRECTION_BOTH
			if not clip_center_node:
				match anchor_position:
					ANCHOR_POSITION.TOP_LEFT, ANCHOR_POSITION.TOP, ANCHOR_POSITION.TOP_RIGHT:
						child_center.grow_vertical = Control.GROW_DIRECTION_END
				match anchor_position:
					ANCHOR_POSITION.BOTTOM_LEFT, ANCHOR_POSITION.BOTTOM, ANCHOR_POSITION.BOTTOM_RIGHT:
						child_center.grow_vertical = Control.GROW_DIRECTION_BEGIN
				match anchor_position:
					ANCHOR_POSITION.BOTTOM_LEFT, ANCHOR_POSITION.TOP_LEFT, ANCHOR_POSITION.LEFT:
						child_center.grow_horizontal = Control.GROW_DIRECTION_END
				match anchor_position:
					ANCHOR_POSITION.TOP_RIGHT, ANCHOR_POSITION.RIGTH, ANCHOR_POSITION.BOTTOM_RIGHT:
						child_center.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			else:
				# we reset the margin if we clip
				child_center.margin_bottom = 0.0
				child_center.margin_left = 0.0
				child_center.margin_right = 0.0
				child_center.margin_top = 0.0
		elif not child_center is Control:
			_warn("A center node is not a Control.")
	# angle
	var angle_start = 0.0
	var angle_end = 0.0
	var is_in_corner = false
	match anchor_position:
		ANCHOR_POSITION.TOP_LEFT:
			angle_end = 90.0
			is_in_corner = true
		ANCHOR_POSITION.TOP:
			angle_end = 180.0
		ANCHOR_POSITION.TOP_RIGHT:
			angle_start = 90.0
			angle_end = 180.0
			is_in_corner = true
		ANCHOR_POSITION.LEFT:
			angle_start = -90.0
			angle_end = 90.0
		ANCHOR_POSITION.CENTER:
			angle_end = 360.0
		ANCHOR_POSITION.RIGTH:
			angle_start = 90.0
			angle_end = 270.0
		ANCHOR_POSITION.BOTTOM_LEFT:
			angle_start =-90.0
			angle_end = 0.0
			is_in_corner = true
		ANCHOR_POSITION.BOTTOM:
			angle_start = 180.0
			angle_end = 360.0
		ANCHOR_POSITION.BOTTOM_RIGHT:
			angle_start = 180.0
			angle_end = 270.0
			is_in_corner = true
	angle_start = angle_start + angle_start_offset
	angle_end = angle_end + angle_end_offset
	# position of circular button
	var number_current_button = 0
	# this will be usefull later, this determine the correction of the center node if it is not clipped
	var clip_correction = center_node.rect_size / 2.0 if not clip_center_node else Vector2(0.0, 0.0)
	for i in range(get_child_count() - number_of_centered_node):
		var node = get_child(i)
		if node is CircularButton and node.visible:
			node.angle_start = angle_start + number_current_button * (angle_end-angle_start) / number_of_circular_button
			node.angle_end = angle_start + (number_current_button + 1) * (angle_end-angle_start) / number_of_circular_button
			if is_in_corner:
				# we find the rect site : this is the size of the container minus the clip correction
				node.rect_size = (rect_size - clip_correction) * 2.0
				# we find the ratio between the inner radius of the button (see above) and the inner element
				node.radius_in = min(center_node.rect_size.x, center_node.rect_size.y ) / (rect_size_element_use - min(clip_correction.x, clip_correction.y)) * radius_ratio / 2.0
			elif anchor_position == ANCHOR_POSITION.CENTER:
				node.rect_size = rect_size # this is juste the size of the container
				node.radius_in = min(center_node.rect_size.x, center_node.rect_size.y) / rect_size_element_use * radius_ratio
			else:
				var direction_radius = Vector2(0.0, 1.0) if anchor_position == ANCHOR_POSITION.BOTTOM or anchor_position == ANCHOR_POSITION.TOP else Vector2(1.0, 0.0)
				var aspect_ratio_ideal = (direction_radius + Vector2(1.0, 1.0)) / 2.0 # aspect ratio ingoring the center element (or the radius / diameter directions)
				# the clip correction is only considered alonf one directionm. this direction is direction_radius
				node.rect_size = (rect_size - clip_correction * direction_radius ) * aspect_ratio_ideal * 2.0
				# simiar as previously
				var radius_in_x_dirr = (center_node.rect_size.x)  / (rect_size.x - clip_correction.x) * aspect_ratio_ideal.y
				var radius_in_y_dirr = (center_node.rect_size.y)  / (rect_size.y - clip_correction.y) * aspect_ratio_ideal.x
				node.radius_in = max(radius_in_x_dirr,radius_in_y_dirr) * radius_ratio # this time we take the max
			node.rect_position = center_node.rect_size / 2.0 + center_node.rect_position - node.rect_size / 2.0 # we ceneter the button on the center of center_node
			number_current_button = number_current_button + 1


func set_radius_ratio(new_ratio):
	if new_ratio < 0.0:
		return
	radius_ratio = new_ratio
	queue_sort()


func set_aspect_ratio_force(ratio_force):
	aspect_ratio_force = ratio_force
	queue_sort()


func set_angle_start_offset(new_angle):
	angle_start_offset = new_angle
	queue_sort()


func set_angle_end_offset(new_angle):
	angle_end_offset = new_angle
	queue_sort()


func set_anchor_position(new_anchor):
	anchor_position = new_anchor
	queue_sort()


func set_clip_center_node(clip):
	clip_center_node = clip
	queue_sort()


func _reset_warning():
	_warning_string = ""
	update_configuration_warning()


func _warn(string):
	# editor only : show a warning on the container node
	_warning_string += ("\n" if _warning_string != "" else "") + string
	update_configuration_warning()


func _get_configuration_warning():
	# editor only : override see node._get_configuration_warning()
	# todo review
	return _warning_string
