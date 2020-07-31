class_name SelectablePanelContainer, "res://resources/editor/selectable_container.svg"
extends PanelContainer

signal pressed()

export(StyleBox) var base_style setget set_base_style
export(StyleBox) var hover_style setget set_hover_style
export(StyleBox) var selected_style setget set_selected_style
export(StyleBox) var focus_style setget set_focus_style

var is_selected = false setget set_is_selected
var _hover = false


func _ready():
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")
	update_style()


func _draw():
	._draw()
	if has_focus():
		var theme_style = theme.get("SelectablePanelContainer/styles/focus_style") if theme != null else null
		var style = focus_style if focus_style!= null else theme_style
		if style != null:
			focus_style.draw(get_canvas_item(), get_rect())


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
		var theme_style = theme.get("SelectablePanelContainer/styles/selected_style") if theme != null else null
		set("custom_styles/panel", selected_style if selected_style!= null else theme_style)
	elif _hover:
		var theme_style = theme.get("SelectablePanelContainer/styles/hover_style") if theme != null else null
		set("custom_styles/panel", hover_style if hover_style!= null else theme_style)
	else:
		var theme_style = theme.get("SelectablePanelContainer/styles/base_style") if theme != null else null
		set("custom_styles/panel", base_style if base_style!= null else theme_style)
	update()


func set_is_selected(selected):
	is_selected = selected;
	update_style()
