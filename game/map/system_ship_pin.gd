extends VBoxContainer

# unused elements

const _ALPHA_SPEED_GAIN = 2.0
const _SNAP_ALPHA_DISTANCE = 0.05
const _ALPHA_APLITUDE = 0.4

export(int) var number = 0 setget set_number

onready var label = $Label
onready var texture = $texture


func _ready():
	set_process(false)
	_update_label()


func _process(delta):
	_process_modulate_alpha(delta)


func _process_modulate_alpha(delta):
	var target_alpha = cos(OS.get_ticks_msec() / 1000.0 * PI ) * _ALPHA_APLITUDE + (1.0 - _ALPHA_APLITUDE)
	texture.modulate = Color(1.0, 1.0, 1.0, target_alpha)


func set_number(new_number):
	if new_number < 0:
		return
	number = new_number
	_update_label()


func _update_label():
	if label == null:
		return
	label.text = (number as String) if number != 0 else ""
