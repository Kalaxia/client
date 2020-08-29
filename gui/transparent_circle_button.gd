class_name TransparentCircleButton, "res://resources/editor/custom_circle_button.svg"
extends CustomShapeButton

# as we have no draw the button is transparent


func _is_inside(position):
	var rel_to_center = position - get_rect().size / 2.0
	return rel_to_center.length() < min(get_global_rect().size.x / 2.0, get_global_rect().size.y / 2.0)
