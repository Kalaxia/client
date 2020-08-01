extends PanelContainer

signal option_pressed(is_pressed)

export(String) var text = "" setget set_text
export(bool) var is_checked = false setget set_is_checked
export(bool) var disabled = false setget set_disabled

onready var button = $HBoxContainer/Button
onready var label = $HBoxContainer/Label


func _ready():
	button.connect("pressed", self, "_on_button_toggle")
	label.text = tr(text)


func set_text(new_label : String):
	text = new_label
	if label != null:
		label.text = tr(text)


func _on_button_toggle():
	is_checked = button.pressed
	emit_signal("option_pressed", is_checked)


func set_is_checked(new_is_checked : bool):
	is_checked = new_is_checked
	button.pressed = is_checked


func set_disabled(is_disabled : bool):
	disabled = is_disabled
	button.disabled = disabled
