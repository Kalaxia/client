extends VBoxContainer

export(int) var number = 0 setget set_number

onready var label = $Label


func _ready():
	_update_label()


func set_number(new_number):
	if new_number < 0:
		return
	number = new_number
	_update_label()


func _update_label():
	if label == null:
		return
	$Label.text = (number as String) if number != 0 else ""
