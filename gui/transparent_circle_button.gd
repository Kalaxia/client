extends CustomShapeButton

class_name TransparentCircleButton

# as we have no draw the button is transparent

func _ready():
	._ready()

func _is_inside(position):
	var rel_to_center = position - rect_size * rect_scale / 2.0 
	return rel_to_center.length() < min(rect_size.x * abs(rect_scale.x) / 2.0, rect_size.y * abs(rect_scale.y) / 2.0)
