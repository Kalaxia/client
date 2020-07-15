extends Control

class_name CustomShapeButton

export(bool) var block_mouse_motion = false
#determine if aborbe the mouse motion event if mouse_filter = MOUSE_FILTER_STOP

var _hover = false

signal pressed()
signal mouse_entered_area()
signal mouse_exited_area()

func _ready():
	if not is_connected("mouse_exited", self, "_on_mouse_exited"):
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
			if _hover != inside: # we do things only if the state changes
				_hover = inside
				update()
				if inside:
					_mouse_entered_area()
					emit_signal("mouse_entered_area")
				else:
					_mouse_exited_area()
					emit_signal("mouse_exited_area")

func _is_inside(position : Vector2) -> bool:
	# this dertermine the area where the button is
	return false

func _on_mouse_exited():
	# this is used to add a extra check when the mouse exit the node
	# this is mainly use in the case where two custom button overlapp and block_mouse_motion  is true
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
