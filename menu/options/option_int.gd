extends PanelContainer

export(String) var option_name setget set_option_name
export(int) var value = 0 setget set_value
export(int) var max_value = 0 setget set_max_value
export(int) var min_value = 0 setget set_min_value
export(bool) var disabled = false setget set_disabled

signal option_changed(value)

# Called when the node enters the scene tree for the first time.
func _ready():
	$HBoxContainer/RangeInt.connect("value_changed",self,"_on_value_changed")

func set_option_name(new_label : String):
	$HBoxContainer/Label.text = new_label

func _on_value_changed(new_value):
	value = new_value
	emit_signal("option_changed",new_value)

func set_value(new_value : int):
	if new_value > max_value || new_value < min_value:
		return
	$HBoxContainer/RangeInt.disconnect("value_changed",self,"_on_value_changed")
	value = new_value
	$HBoxContainer/RangeInt.value = value
	$HBoxContainer/RangeInt.connect("value_changed",self,"_on_value_changed")

func set_disabled(is_disabled : bool):
	disabled = is_disabled
	$HBoxContainer/RangeInt.editable = ! is_disabled

func set_max_value(new_max_value : int ):
	if new_max_value < min_value:
		return
	max_value = new_max_value
	if value > max_value:
		$HBoxContainer/RangeInt.disconnect("value_changed",self,"_on_value_changed")
		value = max_value
		$HBoxContainer/RangeInt.connect("value_changed",self,"_on_value_changed")
	$HBoxContainer/RangeInt.max_value = max_value
	
func set_min_value(new_min_value : int ):
	if new_min_value > max_value:
		return
	min_value = new_min_value
	if value < min_value:
		$HBoxContainer/RangeInt.disconnect("value_changed",self,"_on_value_changed")
		value = min_value
		$HBoxContainer/RangeInt.connect("value_changed",self,"_on_value_changed")
	$HBoxContainer/RangeInt.min_value = min_value
