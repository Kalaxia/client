tool
class_name ConvexPolygon2D
extends Polygon

export(bool) var is_oriented = false setget set_is_oriented
# this is used when checking if the point is inside. If this is oriented then the inside is the part left to the segements
export(bool) var are_border_inside = true setget set_are_border_inside


func _init(new_points = PoolVector2Array(), is_oriented_p = false, are_border_inside_p = true):
	._init()
	is_oriented = is_oriented_p
	are_border_inside = are_border_inside_p
	# normaly signals cannot be connected at this point
	_set_point_test(new_points)


func set_points(new_points):
	if not _set_point_test(new_points):
		printerr("array is not convex or has intersection, cannot assign")


func set_is_oriented(oriented):
	is_oriented = oriented
	emit_signal("changed")


func set_are_border_inside(border_inside):
	are_border_inside = border_inside
	emit_signal("changed")


func is_inside_convex(point): 
	# use it only if are_border_inside = false or is_oriented = true is important
	# otherwise use is_inside
	return _is_array_inside_convex(point, points, are_border_inside, is_oriented)


func get_orientation():
	# optimized for convex polygones
	return _get_array_first_orientation(points)


func is_valid():
	return .is_valid() and is_convex()


func _set_point_test(new_points):
	if _is_array_convex(new_points) and not _has_intersection_array(new_points):
		points = new_points
		emit_signal("changed")
		return true
	return false


static func _is_array_inside_convex(point, points_array, are_border_inside = true, is_oriented = false):
	# only work for convex poly
	# if not convex te output is unprevisible
	var orientation = _get_array_first_orientation(points_array)
	# bool that determine which region we need to check (bounded vs unbounded)
	var unbounded_check = is_oriented and orientation == Polygon.Orientation.ANTI_TRIGONOMETRIC
	for i in range(points_array.size()):
		var edge = points_array[(i + 1) % points_array.size()] - points_array[i % points_array.size()]
		var vector_to_point = point - points_array[i % points_array.size()]
		var cross = edge.cross(vector_to_point) 
		var cross_oriented = (cross * orientation) if orientation != Polygon.Orientation.NOT_DEFINED else cross
		if cross_oriented < 0.0 or (cross_oriented == 0.0 and not Utils.xor(unbounded_check, are_border_inside)):
			# the first check determine if the point is to the side of the unbounded area
			# the second condition determine if se are colinear to the edge
			# the thrid one with the xor determine the behaviour depending if we consider boder inside
			# as the border are considered inside event when we check for the unbounded area
			# so in that case we check that teh point is not in the bounded area with inverse value of are_border_inside (achived by the xor)
			return unbounded_check
	return not unbounded_check
