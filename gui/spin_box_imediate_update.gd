tool
class_name SpinBoxImediateUpdate, "res://resources/editor/spin_box_imediate_update.svg"
extends SpinBox

signal text_entered(text)
signal text_changed(text)


func _ready():
	get_line_edit().connect("text_changed", self, "_on_line_edit_text_changed")
	get_line_edit().connect("text_entered", self, "_on_text_entered")


func _on_line_edit_text_changed(text):
	var caret_position = get_line_edit().caret_position
	apply()
	get_line_edit().caret_position = caret_position
	emit_signal("text_changed", text)


func _on_text_entered(text):
	emit_signal("text_entered", text)
