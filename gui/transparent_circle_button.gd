extends CustomShapeButton

class_name TransparentCircleButton

func _ready():
	._ready()

func _is_inside(position):
	var rel_to_center : Vector2 = position - rect_size / 2.0 
	var dist = rel_to_center.length()
	return dist < min(rect_size.x / 2.0, rect_size.y / 2.0)
