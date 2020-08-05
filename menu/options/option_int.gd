extends PanelContainer

signal option_changed(value)

export(String) var text = "" setget set_text
export(int) var value = 0 setget set_value
export(int) var max_value = 0 setget set_max_value
export(int) var min_value = 0 setget set_min_value
export(bool) var disabled = false setget set_disabled

onready var range_int = $HBoxContainer/RangeInt
onready var label = $HBoxContainer/Label


func _ready():
	range_int.connect("value_changed", self, "_on_value_changed")
	label.text = tr(text)


func set_text(new_label : String):
	text = new_label
	if label != null:
		label.text = tr(text)


func _on_value_changed(new_value):
	value = new_value
	emit_signal("option_changed", new_value)


func set_value(new_value : int):
	if new_value > max_value || new_value < min_value:
		return
	range_int.disconnect("value_changed", self, "_on_value_changed")
	value = new_value
	range_int.value = value
	range_int.connect("value_changed", self, "_on_value_changed")


func set_disabled(is_disabled : bool):
	disabled = is_disabled
	range_int.editable = not is_disabled


func set_max_value(new_max_value : int ):
	if new_max_value < min_value:
		return
	max_value = new_max_value
	if value > max_value:
		range_int.disconnect("value_changed", self, "_on_value_changed")
		value = max_value
		range_int.connect("value_changed", self, "_on_value_changed")
	range_int.max_value = max_value


func set_min_value(new_min_value : int ):
	if new_min_value > max_value:
		return
	min_value = new_min_value
	if value < min_value:
		range_int.disconnect("value_changed", self, "_on_value_changed")
		value = min_value
		range_int.connect("value_changed", self, "_on_value_changed")
	range_int.min_value = min_value
