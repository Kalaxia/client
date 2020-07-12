extends Control

class_name CustomShapeButton

export(bool) var block_mouse_motion = false

var _hover = false

signal pressed()
signal mouse_entered_area()
signal mouse_exited_area()

func _ready():
	connect("mouse_exited", self, "_on_mouse_exited")

func _input(event):
	if mouse_filter == MOUSE_FILTER_IGNORE:
		return
	if event is InputEventMouse:
		var inside = _is_inside(event.position - rect_global_position)
		if inside:
			if mouse_filter == MOUSE_FILTER_STOP and (block_mouse_motion or event is InputEventMouseButton):
				accept_event()
			if event is InputEventMouseButton and event.is_pressed() and event.get_button_index() == BUTTON_LEFT:
				_pressed()
				emit_signal("pressed")
		if event is InputEventMouseMotion:
			if _hover != inside:
				_hover = inside
				update()
				if inside:
					_mouse_entered_area()
				else:
					_mouse_exited_area()
				emit_signal("mouse_entered_area" if inside else "mouse_exited_area") 

func _is_inside(position : Vector2) -> bool:
	return false

func _on_mouse_exited():
	if _hover:
		_hover = false
		update()
		emit_signal("mouse_exited_area")

func _pressed():
	pass

func _mouse_entered_area():
	pass

func _mouse_exited_area():
	pass
