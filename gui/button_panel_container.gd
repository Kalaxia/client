tool
class_name ButtonPanelContainer, "res://resources/editor/selectable_container.svg"
extends PanelContainer

# todo improve this class so it is similare to button
# also do somthing for inheritance with selectable panel container

signal pressed()
signal released()

export(StyleBox) var base_style setget set_base_style
export(StyleBox) var hover_style setget set_hover_style
export(StyleBox) var pressed_style setget set_pressed_style
export(StyleBox) var focus_style setget set_focus_style
export(StyleBox) var disabled_style setget set_disabled_style
export(bool) var disabled = false setget set_disabled

var _hover = false
var _is_pressed = false


func _ready():
	if not is_connected("mouse_entered", self, "_on_mouse_entered"):
		connect("mouse_entered", self, "_on_mouse_entered")
	if not is_connected("mouse_exited", self, "_on_mouse_exited"):
		connect("mouse_exited", self, "_on_mouse_exited")
	update_style()


func _draw():
	if has_focus():
		_draw_focus()


static func _get_theme_class_name() -> String:
	return "Button"


func update():
	.update()


func _on_mouse_entered():
	_hover = true
	update_style()


func _on_mouse_exited():
	_hover = false
	_release()


func _gui_input(event):
	if disabled or not event is InputEventMouseButton or event.get_button_index() != BUTTON_LEFT:
		return
	if event.is_pressed():
		_pressed()
	else:
		_release()


func _pressed():
	Audio.play_click()
	_is_pressed = true
	update_style()
	emit_signal("pressed")


func _release():
	_is_pressed = false
	update_style()
	emit_signal("released")


func _draw_focus():
	var theme_style = get_stylebox("focus", _get_theme_class_name())
	var style = focus_style if focus_style!= null else theme_style
	if style != null:
		style.draw(get_canvas_item(), get_rect())


func set_base_style(style):
	base_style = style
	update_style()


func set_hover_style(style):
	hover_style = style
	update_style()


func set_pressed_style(style):
	pressed_style = style
	update_style()


func set_focus_style(style):
	focus_style = style
	update_style()


func set_disabled_style(style):
	disabled_style = style
	update_style()


func update_style():
	if disabled:
		var theme_style = get_stylebox("disabled", _get_theme_class_name())
		set("custom_styles/panel", disabled_style if disabled_style != null else theme_style)
	elif _is_pressed:
		var theme_style = get_stylebox("pressed", _get_theme_class_name())
		set("custom_styles/panel", pressed_style if pressed_style != null else theme_style)
	elif _hover:
		var theme_style = get_stylebox("hover", _get_theme_class_name())
		set("custom_styles/panel", hover_style if hover_style != null else theme_style)
	else:
		var theme_style = get_stylebox("normal", _get_theme_class_name())
		set("custom_styles/panel", base_style if base_style != null else theme_style)
	update()


func set_disabled(new_bool):
	disabled = new_bool
	if _is_pressed:
		_release()
		# this update the style
	else:
		update_style()
