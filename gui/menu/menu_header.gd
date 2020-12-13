tool
class_name MenuHeader, "res://resources/editor/menu_header.svg"
extends PanelContainer

signal close_request()
signal minimize_request()

# note that custome_styles/panel will be overried use custom_style instead

export(String, MULTILINE) var text = "" setget set_text
export(bool) var closable = true setget set_closable
export(bool) var minimisable = true setget set_minimisable
export(Texture) var texture = null setget set_texture
export(StyleBox) var custom_style = null setget set_custom_style

onready var button_close = $MarginContainer/HBoxContainer/ButtonClose
onready var button_minimize = $MarginContainer/HBoxContainer/ButtonMinimize
onready var label = $MarginContainer/HBoxContainer/Label
onready var texture_rect = $MarginContainer/HBoxContainer/TextureRect


func _ready():
	button_close.connect("pressed", self, "_request_close")
	button_minimize.connect("pressed", self, "_request_minimize")
	update_elements()
	_update_theme()
	if theme != null and not theme.is_connected("changed", self, "_update_theme"):
		theme.connect("changed", self, "_update_theme")


func update_elements():
	button_close.visible = closable
	button_minimize.visible = minimisable
	label.text = tr(text)
	texture_rect.visible = texture != null
	texture_rect.texture = texture


func set_text(new_text):
	text = new_text
	if label != null:
		label.text = tr(text)


func _request_close():
	if closable:
		emit_signal("close_request")


func _request_minimize():
	if minimisable:
		emit_signal("minimize_request")


func set_closable(new_bool):
	closable = new_bool
	if button_close != null:
		button_close.visible = closable


func set_minimisable(new_bool):
	minimisable = new_bool
	if button_minimize != null:
		button_minimize.visible = minimisable


func set_texture(new_texture):
	texture = new_texture
	if texture_rect != null:
		texture_rect.visible = texture != null
		texture_rect.texture = texture


func set_custom_style(new_style):
	custom_style = new_style
	_update_theme()


func _update_theme():
	if custom_style != null:
		set("custom_styles/panel", custom_style)
	else:
		var style = get_stylebox("panel", "MenuHeader")
		set("custom_styles/panel", style)


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_request_close()
		accept_event()
	if event.is_action_pressed("ui_minimize"):
		_request_minimize()
		accept_event()
