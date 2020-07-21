extends PanelContainer


export(String) var text = "" setget set_text
export(bool) var disabled = false setget set_disabled

func _ready():
	pass 


func set_text(new_label : String):
	text = new_label
	$HBoxContainer/Label.text = tr(text)


func set_disabled(is_disabled : bool):
	disabled = is_disabled
	$HBoxContainer/Button.disabled = disabled
