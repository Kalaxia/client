extends Control

class_name CustomShapeButton

var _hover = false
var selected = false setget set_selected

signal pressed()
signal mouse_input(event)

func _ready():
	if not is_connected("mouse_exited", self, "_mouse_exited_area"):
		connect("mouse_exited", self, "_mouse_exited_area")
	if not is_connected("mouse_entered", self, "_mouse_entered_area"):
		connect("mouse_entered", self, "_mouse_entered_area")

func _gui_input(event):
	if event is InputEventMouse:
		emit_signal("mouse_input", event)
		if event is InputEventMouseButton and event.is_pressed() and event.get_button_index() == BUTTON_LEFT:
			_pressed()
			emit_signal("pressed")

func _is_inside(position : Vector2) -> bool:
	# this dertermine the area where the button is
	return false

func has_point(point):
	return _is_inside(point)

func _pressed():
	selected = not selected

func _mouse_entered_area():
	_hover = true
	update()

func _mouse_exited_area():
	_hover = false
	update()

func set_selected(new_selected):
	selected = new_selected
	update()
