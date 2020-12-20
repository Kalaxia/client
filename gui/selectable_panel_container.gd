tool
class_name SelectablePanelContainer, "res://resources/editor/selectable_container.svg"
extends PanelContainer

signal pressed()
signal state_changed(bool_is_pressed)

export(StyleBox) var base_style setget set_base_style
export(StyleBox) var hover_style setget set_hover_style
export(StyleBox) var selected_style setget set_selected_style
export(StyleBox) var focus_style setget set_focus_style

var is_selected = false setget set_is_selected
var _hover = false


func _ready():
	if not is_connected("mouse_entered", self, "_on_mouse_entered"):
		connect("mouse_entered", self, "_on_mouse_entered")
	if not is_connected("mouse_exited", self, "_on_mouse_exited"):
		connect("mouse_exited", self, "_on_mouse_exited")
	update_style()


func _draw():
	if has_focus():
		_draw_focus()


func update():
	.update()


func _on_mouse_entered():
	_hover = true
	update_style()


func _on_mouse_exited():
	_hover = false
	update_style()


func _gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.get_button_index() == BUTTON_LEFT:
		_pressed()
		emit_signal("pressed")


func _pressed():
	Audio.play_click()
	is_selected = not is_selected
	update_style()
	emit_signal("state_changed", is_selected)


func _draw_focus():
	var theme_style = get_stylebox("focus_style", "SelectablePanelContainer")
	var style = focus_style if focus_style!= null else theme_style
	if style != null:
		style.draw(get_canvas_item(), get_rect())


func set_base_style(style):
	base_style = style
	update_style()


func set_hover_style(style):
	hover_style = style
	update_style()


func set_selected_style(style):
	selected_style = style
	update_style()


func set_focus_style(style):
	focus_style = style
	update_style()


func update_style():
	if is_selected:
		var theme_style = get_stylebox("selected_style", "SelectablePanelContainer")
		set("custom_styles/panel", selected_style if selected_style != null else theme_style)
	elif _hover:
		var theme_style = get_stylebox("hover_style", "SelectablePanelContainer")
		set("custom_styles/panel", hover_style if hover_style != null else theme_style)
	else:
		var theme_style = get_stylebox("base_style", "SelectablePanelContainer")
		set("custom_styles/panel", base_style if base_style != null else theme_style)
	update()


func set_is_selected(selected):
	if is_selected != selected:
		is_selected = selected
		update_style()
		emit_signal("state_changed", is_selected)
