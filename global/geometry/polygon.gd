tool
class_name Polygon
extends Resource

enum Orientation{
	ANTI_TRIGONOMETRIC = -1,
	NOT_DEFINED = 0,
	TRIGONOMETRIC = 1,
}

export(PoolVector2Array) var points = PoolVector2Array() setget set_points


func _init(new_points = PoolVector2Array()):
	._init()
	_set_point_test(new_points)


func set_points(new_points):
	_set_point_test(new_points)


func reverse_orientation():
	points.invert()
	emit_signal("changed")


func is_inside(point):
	return Geometry.is_point_in_polygon(point, points)


func is_convex():
	return _is_array_convex(points) and not _has_intersection_array(points)


func push_back_point(point):
	var new_points = points
	new_points.push_back(point)
	return _set_point_test(new_points)


func insert_point(point, index):
	if index >= points.size():
		return
	var new_points = points
	new_points.insert(index, point)
	return _set_point_test(new_points)


func pop_back_point():
	return pop_point(points.size() - 1)


func pop_point(index):
	if index >= points.size():
		return null
	var new_points = points
	var point_back = points[index]
	new_points.remove(index)
	if _set_point_test(new_points):
		return point_back
	return null


func get_bounds():
	return _get_bounds_array(points)


func _set_point_test(new_points):
	points = new_points
	emit_signal("changed")
	return true


func is_valid():
	return points != null and points.size() >= 3


func get_center_of_mass():
	return _get_center_of_mass_array(points)


func set_orientation(orientation):
	if orientation != Orientation.TRIGONOMETRIC and orientation != Orientation.ANTI_TRIGONOMETRIC:
		return
	var poly_orientation = get_orientation()
	if poly_orientation != Orientation.NOT_DEFINED and poly_orientation != orientation:
		reverse_orientation()


func get_shadow_points(shadow_size = 1, shadow_size_offset = Vector2.ZERO):
	return _get_shadow_points_array(points, shadow_size, shadow_size_offset)


func get_orientation():
	return _get_poly_orientation(points)


func get_border_of_poly(edge_index, border_width):
	return _get_border_of_array(points, edge_index, border_width)


static func _get_center_of_mass_array(points_array):
	var center = Vector2.ZERO
	if points_array.size() == 0:
		return center
	for i in points_array:
		center += points_array
	return center / points_array.size()


static func _get_bounds_array(points_array):
	if points_array.size() == 0:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var min_x = points_array[0].x
	var min_y = points_array[0].y
	var max_x = points_array[0].x
	var max_y = points_array[0].y
	for i in range(1, points_array.size()):
		min_x = min(min_x, points_array[i].x)
		min_y = min(min_y, points_array[i].y)
		max_x = max(max_x, points_array[i].x)
		max_y = max(max_y, points_array[i].y)
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


static func _has_intersection_array(points_array):
	if points_array.size() < 3:
		return false
	for i in range(points_array.size() - 2):
		for j in range(i + 2, points_array.size()):
			var segment_1 = points_array[(i + 1) % points_array.size()] - points_array[i % points_array.size()]
			var segment_2 = points_array[(j + 1) % points_array.size()] - points_array[j % points_array.size()]
			var intersection = Geometry.line_intersects_line_2d(points_array[i % points_array.size()], segment_1, points_array[j % points_array.size()], segment_2)
			var intersetion_segment = intersection - points_array[i % points_array.size()]
			if _has_intersection_segent(points_array[i % points_array.size()], points_array[(i + 1) % points_array.size()], points_array[j % points_array.size()], points_array[(j + 1) % points_array.size()]):
				return true
	return false


static func _has_intersection_segent(point_1_start, point_1_end, point_2_start, point_2_end):
	var segment_1 = point_1_end - point_1_start
	var segment_2 = point_2_end - point_2_start
	var intersection = Geometry.line_intersects_line_2d(point_1_start, segment_1, point_2_start, segment_2)
	var intersetion_segment = intersection - point_1_start
	# segemnt 1 and intersetion_segment are colinear 
	# the goal is to determine wehter of not intersection is inside the segment
	# juste checking the length is not enought as it can be on the other side (dot is < 0)
	return intersection != null and intersetion_segment.length() <= segment_1.length() and intersetion_segment.dot(segment_1) >= 0.0


static func _is_array_convex(points_array):
	if points_array.size() < 3:
		return false
	var orientation_head = _get_array_head_orientation(points_array)
	for i in range(1, points_array.size()):
		var segment_array = PoolVector2Array([points_array[i % points_array.size()] , points_array[(i + 1) % points_array.size()], points_array[(i + 2) % points_array.size() ]])
		var orientation = _get_array_head_orientation(segment_array)
		if orientation_head == Orientation.NOT_DEFINED:
			orientation_head = orientation
		elif orientation != orientation_head and orientation != Orientation.NOT_DEFINED:
			return false
	return orientation_head != Orientation.NOT_DEFINED


static func _get_array_head_orientation(points_array):
	if points_array.size() < 3:
		return Orientation.NOT_DEFINED
	var edge_1 = points_array[1] - points_array[0]
	var edge_2 = points_array[2] - points_array[1]
	var angle = fposmod(edge_2.angle_to(edge_1), 2.0 * PI) 
	if angle == PI or angle == 0.0:
		return Orientation.NOT_DEFINED
	return Orientation.TRIGONOMETRIC if angle < PI else Orientation.ANTI_TRIGONOMETRIC


static func _get_array_first_orientation(points_array):
	# return the first not undefined orientation
	# for convec poly this is the orientation of the poly
	if points_array.size() < 3 or not _is_array_convex(points_array):
		return Orientation.NOT_DEFINED
	else:
		for i in range(1, points_array.size()):
			var segment_array = PoolVector2Array([points_array[i % points_array.size()], points_array[(i + 1) % points_array.size()], points_array[(i + 2) % points_array.size()]])
			var orientation = _get_array_head_orientation(segment_array)
			if  orientation != Orientation.NOT_DEFINED:
				return orientation
	return Orientation.NOT_DEFINED


static func _get_poly_orientation(points_array):
	if points_array.size() < 3:
		return Orientation.NOT_DEFINED
	var total_angle = 0
	for i in range(points_array.size()): 
		var edge_1 = points_array[(i + 1) % points_array.size()] - points_array[i % points_array.size()]
		var edge_2 = points_array[(i + 2) % points_array.size()] - points_array[(i + 1) % points_array.size()]
		total_angle += - fposmod(edge_2.angle_to(edge_1), 2.0 * PI) + PI
	if total_angle == 2.0 * PI or total_angle == 0.0:
		# if total_angle this is jute that all point are colinear and therfore does not have an orientation
		return Orientation.NOT_DEFINED
	return Orientation.TRIGONOMETRIC if total_angle > 0.0 else Orientation.ANTI_TRIGONOMETRIC


static func _get_shadow_points_array(points_array, shadow_size = 1, shadow_size_offset = Vector2.ZERO):
	# todo improve
	var center_of_mass = _get_center_of_mass_array(points_array)
	var array = PoolVector2Array()
	for vector in points_array:
		array.push_back((vector - center_of_mass).normalized() * shadow_size + vector + shadow_size_offset)
	return array


static func _get_border_of_array(points_array, edge_index, border_width):
	if edge_index > points_array.size() or border_width == 0:
		return PoolVector2Array()
	var orientation = _get_array_first_orientation(points_array)
	var edge: Vector2 = points_array[(edge_index + 1) % points_array.size()] - points_array[edge_index % points_array.size()]
	var edge_previous: Vector2 = points_array[edge_index % points_array.size()] - points_array[(edge_index - 1) % points_array.size()]
	var edge_next: Vector2 = points_array[(edge_index + 2) % points_array.size()] - points_array[(edge_index + 1) % points_array.size()]
	var array = [points_array[(edge_index) % points_array.size()],  points_array[edge_index % points_array.size()]]
	array.push_back((edge + edge_next).tangent().normalized() * orientation * border_width )
	array.push_back((edge + edge_previous).tangent().normalized() * orientation * border_width )
	return PoolVector2Array(array)
