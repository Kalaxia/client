tool
class_name MenuHeader, "res://resources/editor/menu_header.svg"
extends PanelContainer

signal close_request()
signal minimize_request()

export(String, MULTILINE) var text = "" setget set_text
export(bool) var closable = true setget set_closable
export(bool) var minimisable = true setget set_minimisable
export(Texture) var texture = null setget set_texture

onready var button_close = $MarginContainer/HBoxContainer/ButtonClose
onready var button_minimize = $MarginContainer/HBoxContainer/ButtonMinimize
onready var label = $MarginContainer/HBoxContainer/Label
onready var texture_rect = $MarginContainer/HBoxContainer/TextureRect


func _ready():
	button_close.connect("pressed",self,"_request_close")
	button_minimize.connect("pressed", self, "_request_minimize")
	update_elements()
	if Engine.editor_hint and owner == null:
		self.set_owner(get_tree().edited_scene_root)


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
