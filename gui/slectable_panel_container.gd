extends PanelContainer

class_name SelectablePanelContainer, "res://resources/editor/selectable_container.svg"

export(StyleBox) var base_style
export(StyleBox) var hover_style
export(StyleBox) var slected_style

var is_selected = false setget set_is_selected
var _hover = false

signal pressed()

func _ready():
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")
	update_style()

func _on_mouse_entered():
	_hover = true
	update_style()

func _on_mouse_exited():
	_hover = false
	update_style()

func _gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() && event.get_button_index() == BUTTON_LEFT:
		_pressed()
		emit_signal("pressed")

func _pressed():
	is_selected = not is_selected
	update_style()

func update_style():
	if is_selected:
		set("custom_styles/panel", slected_style)
	elif _hover:
		set("custom_styles/panel", hover_style)
	else:
		set("custom_styles/panel", base_style)
	update()

func set_is_selected(selected):
	is_selected = selected;
	update_style()
